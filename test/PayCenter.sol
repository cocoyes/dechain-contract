pragma solidity ^0.5.6;
pragma experimental ABIEncoderV2;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
contract PayCenter {
    address public owner;
    bool public openStatus=true; //全局控制开关
    uint public total=0; //总交易次数
    uint public totalFee=0; //总手续费
    uint public baseKeepAmount; //最低保证金
    uint public baseFee; //基础费率 10=10%
    Business[] public businessList; //商家列表
    OrderInfo[] orderList;

    IERC20 coin; //币种
    //获取基础信息
    function getPayBaseInfo() public view returns(
        address  _owner,
        bool _openStatus,
        uint _total,
        uint _totalFee,
        uint _baseKeepAmount,
        uint _baseFee
    ){
        return (
        owner,
        openStatus,
        total,
        totalFee,
        baseKeepAmount,
        baseFee
        );
    }
    /// @notice 构造函数
    constructor (IERC20 _token,uint keepAmount,uint _baseFee) public {
        owner = msg.sender;
        coin=_token;
        baseKeepAmount=keepAmount;
        baseFee=_baseFee;
    }

    struct Business{
        address owner; //商户地址
        string icon; //logo
        string name; // 商户名
        uint status; // 状态 0正常，1异常
        uint balance;  //余额
        uint count; //订单交易笔数
        uint fee; //单独手续费率
        uint totalFee; //总支出手续费
        uint keepBalance; //保证金
        bool used;
    }

    struct OrderInfo {
        string oid;
        uint amount;
        uint status; //状态 0已下单、1已支付,取消订单代表删除
        address payUser; //付款人
        uint block; //区块号
        bool used;
        address business;
    }
    //绑定合约单位
    function decimals() public view returns (
        uint _amount
    ) {
        return (coin.decimals());
    }
    //绑定合约符号
    function symbol() public view returns (
        string memory _symbol
    ) {
        return (coin.symbol());
    }
    //绑定合约名称
    function name() public view returns (
        string memory _name
    ) {
        return (coin.name());
    }


    //事件
    event createBusinessEvent(address businessAddress);
    event quitBusinessEvent(address businessAddress);
    event createOrderEvent(string oid);
    event orderPayedEvent(string oid,address business,uint amount);
    event orderRefundedEvent(string oid);
    event orderCanceledEvent(string oid);

    event withdrawFromBalanceEvent(address businessAddress);


    mapping(address => Business) private businessInfo;

    mapping(string => OrderInfo) private orderInfo;


    //注册商家，再此之前需要approve
    function createBusiness( uint keepBalance,string memory  icon, string memory name) public returns (bool){
        require(keepBalance>=baseKeepAmount);
        require(openStatus);
        require(!businessInfo[msg.sender].used);

        businessInfo[msg.sender].used=true;
        businessInfo[msg.sender].icon=icon;
        businessInfo[msg.sender].name=name;
        businessInfo[msg.sender].owner=msg.sender;
        businessInfo[msg.sender].keepBalance=keepBalance;
        businessInfo[msg.sender].status=0;
        businessInfo[msg.sender].balance=0;
        businessInfo[msg.sender].count=0;
        businessInfo[msg.sender].fee=baseFee;
        businessInfo[msg.sender].totalFee=0;
        coin.transferFrom(msg.sender,address(this),keepBalance);
        businessList.push( businessInfo[msg.sender]);
        emit createBusinessEvent(msg.sender);
        return true;
    }



    //注销商家
    function quitBusiness() public returns (bool){
        require(openStatus);
        require(businessInfo[msg.sender].used,"not a business");
        require(businessInfo[msg.sender].status==0,"forbidden operator");
        require(businessInfo[msg.sender].keepBalance>=baseKeepAmount,"keep balance not enough");
        require(businessInfo[msg.sender].balance==0,"balance must be zero");
        coin.transfer(msg.sender,businessInfo[msg.sender].keepBalance);
        delete businessInfo[msg.sender];
        emit quitBusinessEvent(msg.sender);
        return true;
    }

    // 商家提现
    function withdrawFromBalance( uint balance,address rec) public returns (bool){
        require(openStatus);
        require(businessInfo[msg.sender].used,"not a business");
        require(businessInfo[msg.sender].status==0,"forbidden operator");
        require(businessInfo[msg.sender].keepBalance>=baseKeepAmount,"keep balance not enough");
        require(businessInfo[msg.sender].balance>=balance,"balance + fee is not enough");
        uint real=0;
        uint takeFee=0;
        if (businessInfo[msg.sender].fee==0){
            takeFee=balance * baseFee /100;
        }else {
            takeFee=balance * businessInfo[msg.sender].fee /100;
        }
        real=balance- takeFee ;


        businessInfo[msg.sender].balance=businessInfo[msg.sender].balance-balance;

        coin.transfer(rec,real);
        emit withdrawFromBalanceEvent(msg.sender);
        totalFee+=takeFee;
        return true;
    }


    //下单
    function createOrder(string memory oid,uint amount) public returns (bool) {
        require(openStatus);
        require(!orderInfo[oid].used);
        require(businessInfo[msg.sender].used,"not a business");
        require(businessInfo[msg.sender].status==0,"forbidden operator");
        require(businessInfo[msg.sender].keepBalance>=baseKeepAmount,"keep balance not enough");
        orderInfo[oid].used=true;
        orderInfo[oid].amount=amount;
        orderInfo[oid].status=0;
        orderInfo[oid].block=block.number;
        orderInfo[oid].business=msg.sender;

        orderList.push( orderInfo[oid]);
        emit createOrderEvent(oid);
        return true;
    }

    //支付,在此之前需要approve
    function payOrder(string memory oid) public returns (bool){
        require(openStatus);
        require(orderInfo[oid].used,"order not found");

        coin.transferFrom(msg.sender,address(this),orderInfo[oid].amount);
        orderInfo[oid].status=1;
        orderInfo[oid].payUser=msg.sender;
        businessInfo[orderInfo[oid].business].count+=1;
        total++;
        businessInfo[orderInfo[oid].business].balance+=orderInfo[oid].amount;
        emit orderPayedEvent(oid,orderInfo[oid].business,orderInfo[oid].amount);
        return true;
    }


    //退款
    function refundsBalance(string memory oid) public returns (bool){
        require(openStatus);
        require(orderInfo[oid].used,"order not found");
        require(businessInfo[msg.sender].used,"not a business");
        require(businessInfo[msg.sender].status==0,"forbidden operator");
        require(orderInfo[oid].status==1,"order not payed");
        coin.transfer(orderInfo[oid].payUser,orderInfo[oid].amount);
        emit orderRefundedEvent(oid);
    }

    //撤单
    function cancelOrder(string memory oid) public returns (bool){
        require(openStatus);
        require(orderInfo[oid].used,"order not found");
        require(businessInfo[msg.sender].used,"not a business");
        require(orderInfo[oid].business==msg.sender,"forbidden operator not business");
        require(businessInfo[msg.sender].status==0,"forbidden operator");
        require(orderInfo[oid].status==0,"order status can not be canceled");
        delete orderInfo[oid];
        emit orderCanceledEvent(oid);
    }


    //查询订单
    function findOrder(string memory orderId) public view returns(
        string memory oid,
        uint amount,
        uint status,
        address payUser,
        uint _block,
        bool used,
        address business
    ){
        OrderInfo storage order=orderInfo[orderId];
        return (
        order.oid,
        order.amount,
        order.status,
        order.payUser,
        order.block,
        order.used,
        order.business
        );
    }


    function getAllBusiness() public view returns (
        address[] memory  _ows,
        string[] memory  _icons,
        string[] memory  _names,
        uint[] memory  _statuss,
        uint[] memory  _balances,
        uint[] memory  _counts,
        uint[] memory  _fees,
        uint[] memory  _totalFeeBalances

    ) {
        address[] memory  ows= new address[](businessList.length);
        string[] memory  icons= new string[](businessList.length);
        string[] memory  names= new string[](businessList.length);
        uint[] memory  statuss= new uint[](businessList.length);
        uint[] memory  balances= new uint[](businessList.length);
        uint[] memory  counts= new uint[](businessList.length);
        uint[] memory  fees= new uint[](businessList.length);
        uint[] memory  totalFeeBalances= new uint[](businessList.length);



        for (uint i=0;i<businessList.length;i++){
            ows[i]=businessList[i].owner;
            icons[i]=businessList[i].icon;
            names[i]=businessList[i].name;
            statuss[i]=businessList[i].status;
            balances[i]=businessList[i].balance;
            counts[i]=businessList[i].count;
            fees[i]=businessList[i].fee;
            totalFeeBalances[i]=businessList[i].totalFee;
        }
        return (
        ows,
        icons,
        names,
        statuss,
        balances,
        counts,
        fees,
        totalFeeBalances


        );
    }
    //查询商家
    function findBusiness(address business) public view returns(
        address ow,
        string memory icon,
        string memory name,
        uint status,
        uint balance,
        uint count,
        uint fee,
        uint totalFeeBalance,
        uint keepBalance,
        bool used
    ){
        Business storage busi=businessInfo[business];
        return (
        busi.owner,
        busi.icon,
        busi.name,
        busi.status,
        busi.balance,
        busi.count,
        busi.fee,
        busi.totalFee,
        busi.keepBalance,
        busi.used
        );
    }


    //------------管理员操作部分


    //操作全局开关
    function dealContractStatus() public{
        require(msg.sender == owner);
        if (openStatus){
            openStatus=false;
        }else{
            openStatus=true;
        }
    }

    //提取资金到指定账户
    function withdrawBalance(address toAddress,uint amount) public{
        require(msg.sender == owner);
        coin.transfer(toAddress,amount);
    }

    //改变商家状态
    function changeBusiness(address businessAddress) public{
        require(msg.sender == owner);
        require(businessInfo[businessAddress].used);
        uint t_status;
        if (businessInfo[businessAddress].status==0){
            businessInfo[businessAddress].status=1;
            t_status=1;
        }else{
            businessInfo[businessAddress].status=0;
            t_status=0;
        }
        for (uint i=0;i<businessList.length;i++){
            if(businessList[i].owner==address(businessAddress)){
                businessList[i].status=t_status;
            }
        }
    }


    //改变商家提现手续费
    function changeBusinessFee(address business,uint fee) public{
        require(msg.sender == owner);
        require(businessInfo[business].used);
        businessInfo[business].fee=fee;
        for (uint i=0;i<businessList.length;i++){
            if(businessList[i].owner==address(business)){
                businessList[i].fee=fee;
            }
        }
    }


    //改变最低保证金
    function changeKeepBalance(uint amount) public{
        require(msg.sender == owner);
        baseKeepAmount=amount;
    }

    //改变基础费率
    function changeBaseFee(uint fee) public{
        require(msg.sender == owner);
        baseFee=fee;
    }



    //增加一个商家
    function addBusiness(string memory  icon, string memory name,address baddr) public returns (bool){
        require(msg.sender == owner);
        require(openStatus);
        require(!businessInfo[baddr].used);
        businessInfo[baddr].used=true;
        businessInfo[baddr].icon=icon;
        businessInfo[baddr].name=name;
        businessInfo[baddr].owner=baddr;
        businessInfo[baddr].keepBalance=0;
        businessInfo[baddr].status=0;
        businessInfo[baddr].balance=0;
        businessInfo[baddr].count=0;
        businessInfo[baddr].fee=baseFee;
        businessInfo[baddr].totalFee=0;
        businessList.push( businessInfo[baddr]);
        emit createBusinessEvent(baddr);
        return true;
    }

    function clearOrder() public returns (bool){
        require(msg.sender == owner);
        for (uint i=0;i<orderList.length;i++){
            OrderInfo storage order=orderList[i];
            uint l=orderInfo[order.oid].block;
            uint c=block.number;
            uint n=c-l;
            if (n > 10000 && order.status==0){
                delete orderInfo[order.oid];
            }
        }
    }

}
