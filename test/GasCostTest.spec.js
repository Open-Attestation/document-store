const DocumentStore = artifacts.require("./DocumentStore.sol");
DocumentStore.numberFormat = "String";

const {expect} = require("chai").use(require("chai-as-promised"));

const {generateHashes} = require("../scripts/generateHashes");

const config = require("../config.js");

// we need access to mocha context so we're not using arrow function
// eslint-disable-next-line func-names
describe("DocumentStore", function() {
  this.timeout(100000000); // these tests take a long time so we're changing mocha timeout
  describe("Gas costs tests", () => {
    let contract;
    const startingHash =
      "0x2a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6329";
    let lastIssuedHash;
    const txList = [];

    const printTxCosts = async txHashList => {
      const promises = txHashList.map(txHash =>
        web3.eth
          .getTransactionReceipt(txHash)
          .then(txReceipt => txReceipt.gasUsed)
      );

      return Promise.all(promises);
    };

    before(async () => {
      contract = await DocumentStore.new(config.INSTITUTE_NAME);
    });

    it("has the correct institute name", async () => {
      expect(await contract.name()).to.be.equal(config.INSTITUTE_NAME);
    });

    it("can do single issuance", async () => {
      const txReceipt = await contract.issue(startingHash);
      lastIssuedHash = startingHash;
      txList.push(txReceipt.tx);
    });

    it("can do single issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(1, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 2 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(2, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 4 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(4, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 8 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(8, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 16 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(16, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 32 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(32, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 64 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(64, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 128 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(128, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });

    it("can do 256 issuance using bulk issue", async () => {
      const hashesToIssue = generateHashes(256, lastIssuedHash);
      const txReceipt = await contract.bulkIssue(hashesToIssue);
      lastIssuedHash = hashesToIssue[hashesToIssue.length - 1];
      txList.push(txReceipt.tx);
    });
    after(async () => {
      // eslint-disable-next-line no-console
      console.log("transactions:", txList);
      // eslint-disable-next-line no-console
      console.log("costs in gwei:", await printTxCosts(txList));
    });
  });
});
