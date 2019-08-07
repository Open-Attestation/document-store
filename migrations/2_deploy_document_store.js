const DocumentStore = artifacts.require("./DocumentStore.sol");
const { generateHashes } = require("../test/generateHashes");
let contract;

module.exports = deployer => {
  return deployer
    .then(() => {
      return DocumentStore.new(
        "Government Technology Agency of Singapore (GovTech)"
      );
    })
    .then(contractInstance => {
      contract = contractInstance;
      return contract.issue(
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6329"
      );
    })
    .then(txReceipt => {
      console.log(txReceipt);
      return contract.bulkIssue(generateHashes(256));
    })
    .then(console.log);
};
