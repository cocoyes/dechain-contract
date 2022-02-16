pragma solidity ^0.5.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}


/// @title 红包合约
contract Redpack {
    address public owner;

    uint public minPackAmount = 1 * (10 ** 18); // 最低参与金额, 1 moac/mfc
    uint public maxPackAmount = 10000 * (10 ** 18); // 最高参与金额, 10000 moac/mfc
    uint public constant LIMIT_AMOUNT_OF_PACK = 100000 * (10 ** 18);

    uint public minPackCount = 1; // 最少1个红包可抢
    uint public maxPackCount = 10000; // 最多10000个红包可抢

    uint public totalPackAmounts = 0; // 该合约的余额
    uint public numberOfPlayers = 0; // 总的发红包数量
    address[] public players; // 发红包的人的列表
    // 指定aim token
    IERC20 public mytoken;

    function getTokenInfo() public view returns(uint _dec,address _token,string memory _name,string memory _symbol) {
        return (mytoken.decimals(),address(mytoken),mytoken.name(),mytoken.symbol());
    }


    struct Player {
        string id; // 红包的id
        address owner; // 红包创建者的地址
        uint amount; // 红包里面塞钱塞了多少？
        uint balance; // 红包余额
        uint count; // 指定多少个红包数量
        uint[] randomAmount; // 随机分配时，先产生count个随机数
        address[] hunterList; // 抢红包的地址列表
        mapping(address => uint) hunterInfo; // 领取红包的人的列表：地址:数量
        bool used;
    }

    // 红包id到红包发红包人详细映射
    mapping(string => Player) private playerInfo;


    /// @notice 构造函数
    constructor (IERC20 _token) public {
        owner = msg.sender;
        mytoken=_token;
    }



    //绑定合约单位
    function decimals() public view returns (
        uint _amount
    ) {
        return (mytoken.decimals());
    }
    //绑定合约符号
    function symbol() public view returns (
        string memory _symbol
    ) {
        return (mytoken.symbol());
    }
    //绑定合约名称
    function name() public view returns (
        string memory _name
    ) {
        return (mytoken.name());
    }



    /// @notice 总红包数
    function getPlayerInfo() public view returns (
        uint nTotalPackAmounts,
        uint nNumberOfPlayers,
        address[] memory playerList
    ) {
        return (
        totalPackAmounts,
        numberOfPlayers,
        players
        );
    }

    //********************************************************************/
    // 创建红包
    //********************************************************************/

    event redpackCreated(string id);
    event redpackWithdraw(string id,uint amount);

    /// @notice 发红包充值
    /// @param count 可抢多少个红包
    function toll(uint count,uint value,string memory  id) public payable {
        require(!playerInfo[id].used);
        playerInfo[id].amount = value;
        playerInfo[id].owner = msg.sender;
        playerInfo[id].balance = value;
        playerInfo[id].count = count;
        playerInfo[id].id = id;
        playerInfo[id].randomAmount = new uint[](count);

        totalPackAmounts += value;
        numberOfPlayers++; // 创建的红包数量增加
        players.push(msg.sender); // player列表增加
        mytoken.transferFrom(msg.sender,address(this),value);
        playerInfo[id].used=true;
        emit redpackCreated(id);
    }

    /// @notice 创建者提取余下的金额
    /// @param id 红包的id
    function withdrawBalance(string memory  id) public {
        require(msg.sender == playerInfo[id].owner, "not the owner.");
        require(playerInfo[id].balance > 0, "balance is 0.");
        require(playerInfo[id].balance <= totalPackAmounts, "not enough budget.");

        mytoken.transfer(msg.sender,playerInfo[id].balance);
        totalPackAmounts -= playerInfo[id].balance;
        playerInfo[id].balance -= playerInfo[id].balance;
        emit redpackWithdraw(id,playerInfo[id].balance);
    }

    /// @notice 某个红包统计信息
    /// @param id - 地址
    // 红包创建时间
    // 金额
    // 随机 / 平均
    // 个数
    // 余额
    // 已经抢了多少，还有多少
    function getPackInfo(string memory  id) public view returns (
        uint amount,
        uint balance,
        uint count,
        address[] memory  hunterInfos,
        uint[] memory  pickAmounts
    ) {
        Player storage player = playerInfo[id];
        address[] memory  tmp1= new address[](player.hunterList.length);
        uint[] memory  tmp2= new uint[](player.hunterList.length);
        for (uint i=0;i<player.hunterList.length;i++){
            tmp1[i]=player.hunterList[i];
            tmp2[i]=player.hunterInfo[player.hunterList[i]];
        }
        return (
        player.amount,
        player.balance,
        player.count,
        tmp1,
        tmp2
        );
    }

    //********************************************************************/
    // 抢红包
    //********************************************************************/

    event redpackGrabbed(string  _id,uint amount);

    /// @notice 检查地址是否已经抢过该红包了。
    /// @param _id 哪一个红包
    /// @param _hunter 哪一个抢红包的人
    function checkHunterExists(string memory  _id, address _hunter) public view returns(bool) {
        for (uint256 i = 0; i < playerInfo[_id].hunterList.length; i++){
            if(playerInfo[_id].hunterList[i] == _hunter) return true;
        }
        return false;
    }

    /// @notice 抢红包。注意：抢完红包以后，抢的数据还保留着，以备查询
    /// @param id 抢的是哪一个红包
    function hunting(string memory  id) public payable {
        // 先检查该红包有没有余额
        require(playerInfo[id].balance > 0, "redpack is empty");
        require(playerInfo[id].count > playerInfo[id].hunterList.length, "exceed number of redpacks");
        require(!checkHunterExists(id, msg.sender), 'already grabbed');

        bytes memory entropy = abi.encode(
            msg.sender,
            playerInfo[id].balance,
            block.timestamp,
            block.number
        );
        uint256 value=0;
        uint256 val = uint256(keccak256(entropy)) % playerInfo[id].balance;
        uint256 max = uint256(playerInfo[id].balance) / uint256(playerInfo[id].count-playerInfo[id].hunterList.length);
        if (val == 0) {
            value = 1;
        } else if (val > max) {
            value = max;
        } else {
            value = val;
        }
        if(playerInfo[id].count==(playerInfo[id].hunterList.length+1)){
            value=playerInfo[id].balance;
        }
        playerInfo[id].randomAmount[playerInfo[id].count-playerInfo[id].hunterList.length-1]=value;
        hunted(id, value);
        playerInfo[id].balance -= value;
    }
    function hunted(string memory  _id, uint _amount) internal {
        require(_amount <= totalPackAmounts, "grab: not enough budget.");
        mytoken.transfer(msg.sender,_amount);
        totalPackAmounts -= _amount;
        playerInfo[_id].hunterList.push(msg.sender);
        playerInfo[_id].hunterInfo[msg.sender]=_amount;
        emit redpackGrabbed(_id,_amount);
    }
}
