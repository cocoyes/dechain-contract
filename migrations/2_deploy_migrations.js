var Redpack = artifacts.require("./Redpack.sol");
//var Storage = artifacts.require("./PubToken.sol");

module.exports = function(deployer) {
    deployer.deploy(Redpack,"0xF36e606d0032fd76e029F192EF2c967bAfD6464e");
    //deployer.deploy(Storage);
}
