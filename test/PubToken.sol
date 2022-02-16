pragma solidity ^0.5.6;
pragma experimental ABIEncoderV2;

// XNE: safe math for arithmetic operation
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(msg.data.length >= (2 * 32) + 4);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(msg.data.length >= (2 * 32) + 4);
        //require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to,uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from,address _to,uint256 _value)public whenNotPaused returns (bool)  {
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender,uint256 _value) public whenNotPaused returns (bool){
        return super.approve(_spender, _value);
    }
    function increaseApproval(address _spender,uint _addedValue) public whenNotPaused returns (bool success){
        return super.increaseApproval(_spender, _addedValue);
    }
    function decreaseApproval(address _spender,uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


contract PubToken is PausableToken {
    function () external {
        revert();
    }
    string public name;
    uint8 public decimals;
    string public symbol;
    // XNE: token version
    string public version = '2.0';
    mapping (string => string) public reports; //企业报告，key 报告期，value 报告json内容
    string[] items;
    mapping (string => bool) public itemMap;

    mapping (string => string) public news; //新闻
    string[] newsItems;
    mapping (string => string) public notice; //公告
    string[] noticeItems;




    string public companyInfo;
    mapping (address => string)  bankInfo; //card info 银行卡签名
    function getBankItem(address _user) view public returns (string memory){
        require((msg.sender == owner),"YOU CAN NOT SEE");
        return bankInfo[_user];
    }
    function getBankItemMy(address _user) view public returns (string memory){
        return bankInfo[_user];
    }
    function setBankItem(string memory json)  public{
        bankInfo[msg.sender]=json;
    }
    constructor (uint256 _initialAmount, string memory _tokenName,uint8 _decimalUnits, string memory _tokenSymbol) public{
        totalSupply_ = _initialAmount;
        balances[msg.sender] = totalSupply_;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    event createReportEvent(string  _item,string _json);
    function createReport(string memory item,string memory json) public{
        require(msg.sender == owner);
        reports[item]=json;
        if (!itemMap[item]){
            items.push(item);
        }
        emit createReportEvent(item,json);
    }

    function getLastReport(uint8 _size) view public returns (string[] memory){
        uint realSize=0;
        if (items.length<=_size){
            realSize=items.length;
        }else{
            realSize=_size;
        }
        string[] memory  tempArr= new string[](realSize);

        uint max=items.length-realSize;
        uint i=items.length;
        uint j=0;
        while (i>max) {
            tempArr[j]=reports[items[i-1]];
            i--;
            j++;
        }

        return tempArr;
    }
    function getLastReportItem(uint8 _size) view public returns (string[] memory){
        uint realSize=0;
        if (items.length<=_size){
            realSize=items.length;
        }else{
            realSize=_size;
        }
        string[] memory  tempArr= new string[](realSize);

        uint max=items.length-realSize;
        uint i=items.length;
        uint j=0;
        while (i>max) {
            tempArr[j]=items[i-1];
            i--;
            j++;
        }

        return tempArr;
    }

    function getReport(string memory item) view public returns (string memory){
        return reports[item];
    }

    function getItems() public view returns(string[] memory){
        return items;
    }

    function updateCompanyInfo(string memory _info) public{
        require(msg.sender == owner);
        companyInfo=_info;
    }

    event createNewsEvent(string  _item,string _json);
    function createNews(string memory item,string memory json) public{
        require(msg.sender == owner);
        if (bytes(news[item]).length==0){
            news[item]=json;
            newsItems.push(item);
        }
        emit createNewsEvent(item,json);
    }
    function getLastNews(uint8 _size) view public returns (string[] memory){
        uint realSize=0;
        if (newsItems.length<=_size){
            realSize=newsItems.length;
        }else{
            realSize=_size;
        }
        string[] memory  tempArr= new string[](realSize);

        uint max=newsItems.length-realSize;
        uint i=newsItems.length;
        uint j=0;
        while (i>max) {
            tempArr[j]=news[newsItems[i-1]];
            i--;
            j++;
        }

        return tempArr;
    }
    function getNews(string memory item) view public returns (string memory){
        return news[item];
    }

    function getNewsItems() public view returns(string[] memory){
        return newsItems;
    }


    event createNoticeEvent(string  _item,string _json);
    function createNotice(string memory item,string memory json) public{
        require(msg.sender == owner);
        if (bytes(notice[item]).length<=0){
            notice[item]=json;
            noticeItems.push(item);
        }
        emit createNoticeEvent(item,json);
    }
    function getLastNotice(uint8 _size) view public returns (string[] memory){
        uint realSize=0;
        if (noticeItems.length<=_size){
            realSize=noticeItems.length;
        }else{
            realSize=_size;
        }
        string[] memory  tempArr= new string[](realSize);
        uint max=noticeItems.length-realSize;
        uint i=noticeItems.length;
        uint j=0;
        while (i>max) {
            tempArr[j]=notice[noticeItems[i-1]];
            i--;
            j++;
        }

        return tempArr;
    }


    function getNotice(string memory item) view public returns (string memory){
        return notice[item];
    }

    function getNoticeItems() public view returns(string[] memory){
        return noticeItems;
    }

    //批量转账，caddress一定要是发起人持有的合约
    function transferTokens(address caddress,address[] memory _tos,uint[] memory values)public payable {
        require(_tos.length > 0);
        require(values.length > 0);
        require(values.length == _tos.length);
        ERC20 erc20token = ERC20(caddress);
        for(uint i=0;i<_tos.length;i++){
            require(erc20token.transferFrom(msg.sender, _tos[i], values[i]));
        }

    }



}
