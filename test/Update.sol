pragma solidity ^0.5.6;


/// @title 版本控制合约
contract Update {

    address public owner;

    // app1 -> 1.0.1
    mapping(string => string) public lastVersionMap;

    // app >> 1.0.1 -> http://xx.xx.exe
    mapping(string => mapping(string => string)) public allVersionMap;



    constructor () public {
        owner = msg.sender;
    }

    function uploadApp(string memory  _name,string memory  _version,string memory  _url) public {
        require(msg.sender == owner, "not the owner.");
        lastVersionMap[_name]=_version;
        allVersionMap[_name][_version]=_url;

    }

    function getAppInfo(string memory _app) public view returns (
        string memory _name,
        string memory _version,
        string memory _url
    ) {
        string memory version=lastVersionMap[_app];
        string memory url=allVersionMap[_app][version];
        return (_app,version,url);
    }

}
