const DocumentStore = artifacts.require("./DocumentStore.sol");
const { generateHashes } = require("../test/generateHashes");

let contract;
const startingHash =
  "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6329";
let lastIssuedHash = startingHash;
const txList = [];

module.exports = deployer =>
  deployer
    .then(() =>
      DocumentStore.new("Government Technology Agency of Singapore (GovTech)")
    )
    .then(contractInstance => {
      contract = contractInstance;
      return contract.issue(lastIssuedHash);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(1, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(2, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(4, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(8, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(16, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(32, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(64, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(128, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      const hashesToIssue = generateHashes(256, lastIssuedHash);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      return contract.bulkIssue(hashesToIssue);
    })
    .then(txReceipt => {
      txList.push(txReceipt.tx);
      console.log(txList);
    });
