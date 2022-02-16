##### PubToken #####
## 编译
solcjs PubToken.sol  --optimize  --bin --abi --output-dir E:\blockchain\truffle_test\redpack_test\out
## 生成java代码
web3j solidity generate -b E:\blockchain\truffle_test\redpack_test\out\PubToken_sol_PubToken.bin -a E:\blockchain\truffle_test\redpack_test\out\PubToken_sol_PubToken.abi -o E:\blockchain\truffle_test\redpack_test\java -p com.dechain.contract


##### PayCenter #####
solcjs PayCenter.sol  --optimize  --bin --abi --output-dir E:\blockchain\truffle_test\redpack_test\out
## 生成java代码
web3j solidity generate -b E:\blockchain\truffle_test\redpack_test\out\PayCenter_sol_PayCenter.bin -a E:\blockchain\truffle_test\redpack_test\out\PayCenter_sol_PayCenter.abi -o E:\blockchain\truffle_test\redpack_test\java -p com.dechain.contract
#####

##### Redpack #####
solcjs Redpack.sol  --optimize  --bin --abi --output-dir E:\blockchain\truffle_test\redpack_test\out
## 生成java代码
web3j solidity generate -b E:\blockchain\truffle_test\redpack_test\out\Redpack_sol_Redpack.bin -a E:\blockchain\truffle_test\redpack_test\out\Redpack_sol_Redpack.abi -o E:\blockchain\truffle_test\redpack_test\java -p com.dechain.contract
#####

##### NFT #####
solcjs NFT.sol  --optimize  --bin --abi --output-dir E:\blockchain\truffle_test\redpack_test\out
## 生成java代码
web3j solidity generate -b E:\blockchain\truffle_test\redpack_test\out\NFT_sol_NFT.bin -a E:\blockchain\truffle_test\redpack_test\out\NFT_sol_NFT.abi -o E:\blockchain\truffle_test\redpack_test\java -p com.dechain.contract
#####



## 切换编译版本
npm install -g solc@0.4.22
