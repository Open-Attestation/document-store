let Web3 = require("web3");
let web3 = new Web3(
  "https://ropsten.infura.io/v3/1f1ff2b3fca04f8d99f67d465c59e4ef"
);

const getTxCosts = async txHashList => {
  const promises = txHashList.map(txHash => {
    return web3.eth.getTransactionReceipt(txHash).then(txReceipt => {
        return txReceipt.gasUsed
    });
  });

  const resolved = Promise.all(promises).then(console.log);
};

module.exports = {
    getTxCosts
}