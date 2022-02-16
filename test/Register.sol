pragma solidity ^0.5.6;
pragma experimental ABIEncoderV2;
contract NFTRegister{
    struct NFTMarket{
        string img;
        string title;
        string content;
        address contractAddr;
        address creator;
        bool used;
    }
    uint public nftPublishFee=1*(10**18);
    //NFT
    mapping(address => NFTMarket) public nftTokenMap;
    address[] public nftMarkets;
}

/// @title 注册合约
contract Register is NFTRegister{
    address public owner;

    uint public registerTokenFee=1*(10**18);
    uint public registerRedFee=1*(10**18);
    uint public registerPayFee=1*(10**18);

    //token地址映射 token信息
    mapping(address => Token) public tokenInfo;
    // token symbol 映射 token信息
    mapping(string => Token) public symbolTokenInfo;

    uint openContractCount;
    uint openRedCount;
    uint openPayCount;
    // red contract
    mapping(address => address) public redPackTokenMap;
    //pay contract
    mapping(address => address) public payTokenMap;

    Token[] public tokens;
    address[] public tokenAddress;


    constructor(uint _registerTokenFee,uint _registerRedFee,uint _registerPayFee,uint _nftPublishFee) public{
        owner=msg.sender;
        registerTokenFee=_registerTokenFee;
        registerRedFee=_registerRedFee;
        registerPayFee=_registerPayFee;
        nftPublishFee=_nftPublishFee;
    }

    struct User {
        address owner;
        string username;
        string icon;
        bool used;
    }
    struct Token{
        address owner;
        address token;
        string symbol;
        string icon;
        uint len;
        string tokenName;
        bool used;
        uint sort;
        bool status;
        address red;
        address pay;
        uint ctype;
    }

    function getBaseInfo() public view returns(uint _registerTokenFee,uint _registerRedFee,uint _registerPayFee,uint _openContractCount,uint _openRedCount,uint _openPayCount){
        return (registerTokenFee,registerRedFee,registerPayFee,openContractCount,openRedCount,openPayCount);
    }
    function getRedMap(address _addr) public view returns(address  _redAddr){
        address  addr=redPackTokenMap[_addr];
        return addr;
    }
    function getPayMap(address _addr) public view returns(address  _payAddr){
        address  addr=payTokenMap[_addr];
        return addr;
    }
    function getTokenList() public view returns(address[] memory _tokenAddress){
        return tokenAddress;
    }

    function getTokenInfo(address _addr) public view returns(address _owner, address token,string memory symbol,string memory icon,uint len,string memory tokenName,uint sort, bool status,address red,address pay,uint _ctype){
        Token storage tok=tokenInfo[_addr];
        return (tok.owner,tok.token,tok.symbol,tok.icon,tok.len,tok.tokenName,tok.sort,tok.status,tok.red,tok.pay,tok.ctype);
    }

    function updateTokenSort(address[] memory _addrs,uint[] memory sorts) public payable{
        require(msg.sender==owner);
        require(_addrs.length == sorts.length);
        for(uint i=0;i<_addrs.length;i++){
            tokenInfo[_addrs[i]].sort=sorts[i];
        }
    }
    function updateTokenIcon(address[] memory _addrs,string[] memory icons) public payable{
        require(msg.sender==owner);
        require(_addrs.length == icons.length);
        for(uint i=0;i<_addrs.length;i++){
            tokenInfo[_addrs[i]].icon=icons[i];
        }
    }
    function updateTokenName(address[] memory _addrs,string[] memory names) public payable{
        require(msg.sender==owner);
        require(_addrs.length == names.length);
        for(uint i=0;i<_addrs.length;i++){
            tokenInfo[_addrs[i]].tokenName=names[i];
        }
    }
    function updateTokenSymbol(address[] memory _addrs,string[] memory symbols) public payable{
        require(msg.sender==owner);
        require(_addrs.length == symbols.length);
        for(uint i=0;i<_addrs.length;i++){
            tokenInfo[_addrs[i]].symbol=symbols[i];
        }
    }

    function getNFTList() public view returns(address[] memory _tokenAddress){
        return nftMarkets;
    }
    function getNFTInfo(address _addr) public view returns(string memory _img,string memory _title,string memory _content,address _contractAddr,address _creator,bool _used){
        NFTMarket storage tok=nftTokenMap[_addr];
        return (tok.img,tok.title,tok.content,tok.contractAddr,tok.creator,tok.used);
    }
    function mapperRedContract(address  _redAddr,address  _tokenAddr) public payable{
        require(msg.value==registerRedFee);
        require(tokenInfo[_tokenAddr].owner==msg.sender);
        redPackTokenMap[_tokenAddr]=_redAddr;
        tokenInfo[_tokenAddr].red=_redAddr;
        openRedCount+=1;
    }
    function mapperPayContract(address  _payAddr,address  _tokenAddr) public payable{
        require(msg.value==registerPayFee);
        require(tokenInfo[_tokenAddr].owner==msg.sender);
        payTokenMap[_tokenAddr]=_payAddr;
        tokenInfo[_tokenAddr].pay=_payAddr;
        openPayCount+=1;
    }

    function createToken(address _token,string memory _symbol,string memory _icon,string memory _tokenName,uint _len,uint _ctype) public payable{
        require(bytes(_symbol).length<20);
        require(bytes(_icon).length<300);
        require(bytes(_tokenName).length<30);
        require(_len==18 ||_len==6);
        require(!symbolTokenInfo[_symbol].used,"can not create");
        require(msg.value==registerTokenFee);
        tokenInfo[_token].owner=msg.sender;
        tokenInfo[_token].token=_token;
        tokenInfo[_token].symbol=_symbol;
        tokenInfo[_token].tokenName=_tokenName;
        tokenInfo[_token].len=_len;
        tokenInfo[_token].icon=_icon;
        tokenInfo[_token].used=true;
        tokenInfo[_token].status=true;
        tokenInfo[_token].ctype=_ctype;
        symbolTokenInfo[_symbol]=tokenInfo[_token];
        openContractCount+=1;
        tokens.push(tokenInfo[_token]);
        tokenAddress.push(_token);
    }
    function createNFT(address _contractAddr,string memory _img,string memory _title,string memory _content) public payable{
        require(bytes(_title).length<50);
        require(bytes(_img).length<300);
        require(bytes(_content).length<1000);
        require(!nftTokenMap[_contractAddr].used,"can not create");
        require(msg.value==nftPublishFee);
        nftTokenMap[_contractAddr].creator=msg.sender;
        nftTokenMap[_contractAddr].contractAddr=_contractAddr;
        nftTokenMap[_contractAddr].img=_img;
        nftTokenMap[_contractAddr].title=_title;
        nftTokenMap[_contractAddr].content=_content;
        nftTokenMap[_contractAddr].used=true;
        nftMarkets.push(_contractAddr);
    }

    function updateNFTUsed(address  _nftAddr,bool   _state) public{
        require(msg.sender==owner);
        nftTokenMap[_nftAddr].used=_state;
    }
    function addToken(address _token,string memory _symbol,string memory _icon,string memory _tokenName,uint _len,uint _red,uint _pay,address _raddr,address _paddr,uint _ctype) public payable{
        require(msg.sender==owner);
        require(bytes(_symbol).length<20);
        require(bytes(_icon).length<300);
        require(bytes(_tokenName).length<30);
        require(_len==18 ||_len==6);
        require(!symbolTokenInfo[_symbol].used,"can not create");
        require(msg.value==registerTokenFee);
        tokenInfo[_token].owner=msg.sender;
        tokenInfo[_token].token=_token;
        tokenInfo[_token].symbol=_symbol;
        tokenInfo[_token].tokenName=_tokenName;
        tokenInfo[_token].len=_len;
        tokenInfo[_token].ctype=_ctype;
        tokenInfo[_token].status=true;
        tokenInfo[_token].icon=_icon;
        tokenInfo[_token].used=true;
        if(_red==1){
            tokenInfo[_token].red=_raddr;
            redPackTokenMap[_token]=_raddr;
        }
        if(_pay==1){
            payTokenMap[_token]=_paddr;
            tokenInfo[_token].red=_paddr;
        }
        symbolTokenInfo[_symbol]=tokenInfo[_token];
        openContractCount+=1;
        tokens.push(tokenInfo[_token]);
        tokenAddress.push(_token);
    }
    function addOrChangeNFT(address _contractAddr,string memory _img,string memory _title,string memory _content) public payable{
        require(msg.sender==owner);
        if(!nftTokenMap[_contractAddr].used){
            nftMarkets.push(_contractAddr);
        }
        nftTokenMap[_contractAddr].creator=msg.sender;
        nftTokenMap[_contractAddr].contractAddr=_contractAddr;
        nftTokenMap[_contractAddr].img=_img;
        nftTokenMap[_contractAddr].title=_title;
        nftTokenMap[_contractAddr].content=_content;
        nftTokenMap[_contractAddr].used=true;

    }
    function changeTokenSort(address _token,uint _sort) public{
        require(msg.sender==owner);
        for (uint i=0;i<tokens.length;i++){
            if (tokens[i].token==_token){
                tokens[i].sort=_sort;
                tokenInfo[_token].sort=_sort;
                break;
            }
        }
    }

    function changeTokenCtype(address _token,uint _ctype) public{
        require(msg.sender==owner);
        for (uint i=0;i<tokens.length;i++){
            if (tokens[i].token==_token){
                tokens[i].ctype=_ctype;
                tokenInfo[_token].ctype=_ctype;
                break;
            }
        }
    }


    function lockToken(address _token) public{
        require(msg.sender==owner);
        for (uint i=0;i<tokens.length;i++){
            if (tokens[i].token==_token){
                tokens[i].status=false;
                tokenInfo[_token].status=false;
                break;
            }
        }
    }
    function unlockToken(address _token) public{
        require(msg.sender==owner);
        for (uint i=0;i<tokens.length;i++){
            if (tokens[i].token==_token){
                tokens[i].status=true;
                tokenInfo[_token].status=true;
                break;
            }
        }
    }
    function changeFee(uint _registerTokenFee,uint _registerRedFee,uint _registerPayFee,uint _nftPublishFee) public{
        require(msg.sender==owner);

        if (_registerTokenFee>0) {
            registerTokenFee=_registerTokenFee;
        }
        if (_registerRedFee>0) {
            registerRedFee=_registerRedFee;
        }
        if (_registerPayFee>0) {
            registerPayFee=_registerPayFee;
        }
        if (_nftPublishFee>0) {
            nftPublishFee=_nftPublishFee;
        }
    }
    function withdrawBalance(uint amount) public payable{
        require(msg.sender == owner);
        msg.sender.transfer(amount);
    }


}
