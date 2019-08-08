const Web3 = require("web3");

const web3 = new Web3(
  `https://ropsten.infura.io/v3/${process.env.ROPSTEN_API_KEY}`
);

const printTxCosts = async txHashList => {
  const promises = txHashList.map(txHash =>
    web3.eth.getTransactionReceipt(txHash).then(txReceipt => txReceipt.gasUsed)
  );

  // eslint-disable-next-line no-console
  Promise.all(promises).then(console.log);
};

module.exports = {
  printTxCosts
};
