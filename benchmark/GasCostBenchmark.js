const {groupBy, mapValues} = require("lodash");

const DocumentStore = artifacts.require("./DocumentStore.sol");
const DocumentStoreWithRevokeReasons = artifacts.require("./DocumentStoreWithRevokeReasons.sol");
const ProxyFactory = artifacts.require("./ProxyFactory.sol");
const BaseAdminUpgradeabilityProxy = artifacts.require("./BaseAdminUpgradeabilityProxy.sol");

DocumentStore.numberFormat = "String";
const {generateHashes} = require("../scripts/generateHashes");

const initializeAbi = {
  constant: false,
  inputs: [
    {
      internalType: "string",
      name: "_name",
      type: "string"
    },
    {
      internalType: "address",
      name: "owner",
      type: "address"
    }
  ],
  name: "initialize",
  outputs: [],
  payable: false,
  stateMutability: "nonpayable",
  type: "function"
};

const STORE_NAME = "THE_STORE_NAME";
let lastIssuedHash = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6432";
const randomHashes = num => {
  const generated = generateHashes(num, lastIssuedHash);
  lastIssuedHash = generated[generated.length - 1];
  return generated;
};
const randomHash = () => randomHashes(1)[0];

describe("Gas Cost Benchmarks", () => {
  const gasRecords = [];
  const recordGasCost = (contract, context, gas) => {
    gasRecords.push({
      contract,
      context,
      gas
    });
  };
  after(() => {
    const groupedRecords = groupBy(gasRecords, record => record.context);
    const records = mapValues(groupedRecords, contextualisedRecords =>
      contextualisedRecords.reduce(
        (state, current) => ({
          ...state,
          [current.contract]: current.gas
        }),
        {}
      )
    );
    // eslint-disable-next-line no-console
    console.table(records);
  });

  let staticDocumentStoreInstance;
  let staticProxyFactoryInstance;
  let staticDocumentStoreWithRevokeReasons;

  before(async () => {
    staticDocumentStoreInstance = await DocumentStore.new();
    staticProxyFactoryInstance = await ProxyFactory.new();
    staticDocumentStoreWithRevokeReasons = await DocumentStoreWithRevokeReasons.new();
  });

  contract("DocumentStore", accounts => {
    let documentStoreInstance;
    it("deploy & initialize", async () => {
      const deployment = await DocumentStore.new();
      documentStoreInstance = deployment;
      const deploymentReceipt = await web3.eth.getTransactionReceipt(deployment.transactionHash);
      const initializeReceipt = await documentStoreInstance.initialize(STORE_NAME, accounts[0]);
      recordGasCost(
        "DocumentStore",
        "deployment & initialize",
        deploymentReceipt.cumulativeGasUsed + initializeReceipt.receipt.cumulativeGasUsed
      );
    });
    it("transferOwnership", async () => {
      const newDocumentStoreInstance = await DocumentStore.new();
      await newDocumentStoreInstance.initialize(STORE_NAME, accounts[0]);
      const {receipt} = await newDocumentStoreInstance.transferOwnership(accounts[1]);
      recordGasCost("DocumentStore", "transferOwnership", receipt.cumulativeGasUsed);
    });
    it("issue", async () => {
      const {receipt} = await documentStoreInstance.issue(randomHash());
      recordGasCost("DocumentStore", "issue", receipt.cumulativeGasUsed);
    });
    it("bulkIssue", async () => {
      const issue1 = await documentStoreInstance.bulkIssue(randomHashes(1));
      recordGasCost("DocumentStore", "bulkIssue - 1 hash", issue1.receipt.cumulativeGasUsed);
      const issue2 = await documentStoreInstance.bulkIssue(randomHashes(2));
      recordGasCost("DocumentStore", "bulkIssue - 2 hash", issue2.receipt.cumulativeGasUsed);
      const issue4 = await documentStoreInstance.bulkIssue(randomHashes(4));
      recordGasCost("DocumentStore", "bulkIssue - 4 hash", issue4.receipt.cumulativeGasUsed);
      const issue8 = await documentStoreInstance.bulkIssue(randomHashes(8));
      recordGasCost("DocumentStore", "bulkIssue - 8 hash", issue8.receipt.cumulativeGasUsed);
      const issue16 = await documentStoreInstance.bulkIssue(randomHashes(16));
      recordGasCost("DocumentStore", "bulkIssue - 16 hash", issue16.receipt.cumulativeGasUsed);
      const issue32 = await documentStoreInstance.bulkIssue(randomHashes(32));
      recordGasCost("DocumentStore", "bulkIssue - 32 hash", issue32.receipt.cumulativeGasUsed);
      const issue64 = await documentStoreInstance.bulkIssue(randomHashes(64));
      recordGasCost("DocumentStore", "bulkIssue - 64 hash", issue64.receipt.cumulativeGasUsed);
      const issue128 = await documentStoreInstance.bulkIssue(randomHashes(128));
      recordGasCost("DocumentStore", "bulkIssue - 128 hash", issue128.receipt.cumulativeGasUsed);
      const issue256 = await documentStoreInstance.bulkIssue(randomHashes(256));
      recordGasCost("DocumentStore", "bulkIssue - 256 hash", issue256.receipt.cumulativeGasUsed);
    });
    it("revoke", async () => {
      const {receipt} = await documentStoreInstance.revoke(randomHash());
      recordGasCost("DocumentStore", "revoke", receipt.cumulativeGasUsed);
    });
    it("bulkRevoke", async () => {
      const issue1 = await documentStoreInstance.bulkRevoke(randomHashes(1));
      recordGasCost("DocumentStore", "bulkRevoke - 1 hash", issue1.receipt.cumulativeGasUsed);
      const issue2 = await documentStoreInstance.bulkRevoke(randomHashes(2));
      recordGasCost("DocumentStore", "bulkRevoke - 2 hash", issue2.receipt.cumulativeGasUsed);
      const issue4 = await documentStoreInstance.bulkRevoke(randomHashes(4));
      recordGasCost("DocumentStore", "bulkRevoke - 4 hash", issue4.receipt.cumulativeGasUsed);
      const issue8 = await documentStoreInstance.bulkRevoke(randomHashes(8));
      recordGasCost("DocumentStore", "bulkRevoke - 8 hash", issue8.receipt.cumulativeGasUsed);
      const issue16 = await documentStoreInstance.bulkRevoke(randomHashes(16));
      recordGasCost("DocumentStore", "bulkRevoke - 16 hash", issue16.receipt.cumulativeGasUsed);
      const issue32 = await documentStoreInstance.bulkRevoke(randomHashes(32));
      recordGasCost("DocumentStore", "bulkRevoke - 32 hash", issue32.receipt.cumulativeGasUsed);
      const issue64 = await documentStoreInstance.bulkRevoke(randomHashes(64));
      recordGasCost("DocumentStore", "bulkRevoke - 64 hash", issue64.receipt.cumulativeGasUsed);
      const issue128 = await documentStoreInstance.bulkRevoke(randomHashes(128));
      recordGasCost("DocumentStore", "bulkRevoke - 128 hash", issue128.receipt.cumulativeGasUsed);
      const issue256 = await documentStoreInstance.bulkRevoke(randomHashes(256));
      recordGasCost("DocumentStore", "bulkRevoke - 256 hash", issue256.receipt.cumulativeGasUsed);
    });
  });

  contract("ProxyFactory", () => {
    it("deploy", async () => {
      const deployment = await ProxyFactory.new();
      const receipt = await web3.eth.getTransactionReceipt(deployment.transactionHash);
      recordGasCost("ProxyFactory", "deployment", receipt.cumulativeGasUsed);
    });
  });

  contract("DocumentStore (Minimal Proxy)", accounts => {
    let minimalProxyAddress;

    it("deploy", async () => {
      const encodedInitilizeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
      const {receipt, logs} = await staticProxyFactoryInstance.deployMinimal(
        staticDocumentStoreInstance.address,
        encodedInitilizeCall
      );
      minimalProxyAddress = logs[0].args.proxy;
      recordGasCost("DocumentStore (Minimal Proxy)", "deployment & initialize", receipt.cumulativeGasUsed);
    });
    it("transferOwnership", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(minimalProxyAddress);
      const {receipt} = await proxiedDocumentStoreInstance.transferOwnership(accounts[1]);
      recordGasCost("DocumentStore (Minimal Proxy)", "transferOwnership", receipt.cumulativeGasUsed);
      await proxiedDocumentStoreInstance.transferOwnership(accounts[0], {from: accounts[1]});
    });
    it("issue", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(minimalProxyAddress);
      const {receipt} = await proxiedDocumentStoreInstance.issue(randomHash());
      recordGasCost("DocumentStore (Minimal Proxy)", "issue", receipt.cumulativeGasUsed);
    });
    it("bulkIssue", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(minimalProxyAddress);
      const issue1 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(1));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 1 hash", issue1.receipt.cumulativeGasUsed);
      const issue2 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(2));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 2 hash", issue2.receipt.cumulativeGasUsed);
      const issue4 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(4));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 4 hash", issue4.receipt.cumulativeGasUsed);
      const issue8 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(8));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 8 hash", issue8.receipt.cumulativeGasUsed);
      const issue16 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(16));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 16 hash", issue16.receipt.cumulativeGasUsed);
      const issue32 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(32));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 32 hash", issue32.receipt.cumulativeGasUsed);
      const issue64 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(64));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 64 hash", issue64.receipt.cumulativeGasUsed);
      const issue128 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(128));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 128 hash", issue128.receipt.cumulativeGasUsed);
      const issue256 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(256));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkIssue - 256 hash", issue256.receipt.cumulativeGasUsed);
    });
    it("revoke", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(minimalProxyAddress);
      const {receipt} = await proxiedDocumentStoreInstance.revoke(randomHash());
      recordGasCost("DocumentStore (Minimal Proxy)", "revoke", receipt.cumulativeGasUsed);
    });
    it("bulkRevoke", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(minimalProxyAddress);
      const issue1 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(1));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 1 hash", issue1.receipt.cumulativeGasUsed);
      const issue2 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(2));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 2 hash", issue2.receipt.cumulativeGasUsed);
      const issue4 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(4));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 4 hash", issue4.receipt.cumulativeGasUsed);
      const issue8 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(8));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 8 hash", issue8.receipt.cumulativeGasUsed);
      const issue16 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(16));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 16 hash", issue16.receipt.cumulativeGasUsed);
      const issue32 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(32));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 32 hash", issue32.receipt.cumulativeGasUsed);
      const issue64 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(64));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 64 hash", issue64.receipt.cumulativeGasUsed);
      const issue128 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(128));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 128 hash", issue128.receipt.cumulativeGasUsed);
      const issue256 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(256));
      recordGasCost("DocumentStore (Minimal Proxy)", "bulkRevoke - 256 hash", issue256.receipt.cumulativeGasUsed);
    });
  });

  contract("DocumentStore (AdminUpgradableProxy)", accounts => {
    let adminUpgradableProxyAddress;
    it("deploy", async () => {
      const encodedInitilizeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
      const salt = 1337;
      const {receipt, logs} = await staticProxyFactoryInstance.deploy(
        salt,
        staticDocumentStoreInstance.address,
        accounts[1], // Must use separate account for proxy admin
        encodedInitilizeCall
      );
      adminUpgradableProxyAddress = logs[0].args.proxy;
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "deployment & initialize", receipt.cumulativeGasUsed);
    });
    it("transferOwnership", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(adminUpgradableProxyAddress);
      const {receipt} = await proxiedDocumentStoreInstance.transferOwnership(accounts[2]);
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "transferOwnership", receipt.cumulativeGasUsed);
      await proxiedDocumentStoreInstance.transferOwnership(accounts[0], {from: accounts[2]});
    });
    it("issue", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(adminUpgradableProxyAddress);
      const {receipt} = await proxiedDocumentStoreInstance.issue(randomHash());
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "issue", receipt.cumulativeGasUsed);
    });
    it("bulkIssue", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(adminUpgradableProxyAddress);
      const issue1 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(1));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 1 hash", issue1.receipt.cumulativeGasUsed);
      const issue2 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(2));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 2 hash", issue2.receipt.cumulativeGasUsed);
      const issue4 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(4));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 4 hash", issue4.receipt.cumulativeGasUsed);
      const issue8 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(8));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 8 hash", issue8.receipt.cumulativeGasUsed);
      const issue16 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(16));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 16 hash", issue16.receipt.cumulativeGasUsed);
      const issue32 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(32));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 32 hash", issue32.receipt.cumulativeGasUsed);
      const issue64 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(64));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 64 hash", issue64.receipt.cumulativeGasUsed);
      const issue128 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(128));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 128 hash", issue128.receipt.cumulativeGasUsed);
      const issue256 = await proxiedDocumentStoreInstance.bulkIssue(randomHashes(256));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkIssue - 256 hash", issue256.receipt.cumulativeGasUsed);
    });
    it("revoke", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(adminUpgradableProxyAddress);
      const {receipt} = await proxiedDocumentStoreInstance.revoke(randomHash());
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "revoke", receipt.cumulativeGasUsed);
    });
    it("bulkRevoke", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(adminUpgradableProxyAddress);
      const issue1 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(1));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 1 hash", issue1.receipt.cumulativeGasUsed);
      const issue2 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(2));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 2 hash", issue2.receipt.cumulativeGasUsed);
      const issue4 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(4));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 4 hash", issue4.receipt.cumulativeGasUsed);
      const issue8 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(8));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 8 hash", issue8.receipt.cumulativeGasUsed);
      const issue16 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(16));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 16 hash", issue16.receipt.cumulativeGasUsed);
      const issue32 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(32));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 32 hash", issue32.receipt.cumulativeGasUsed);
      const issue64 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(64));
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "bulkRevoke - 64 hash", issue64.receipt.cumulativeGasUsed);
      const issue128 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(128));
      recordGasCost(
        "DocumentStore (AdminUpgradableProxy)",
        "bulkRevoke - 128 hash",
        issue128.receipt.cumulativeGasUsed
      );
      const issue256 = await proxiedDocumentStoreInstance.bulkRevoke(randomHashes(256));
      recordGasCost(
        "DocumentStore (AdminUpgradableProxy)",
        "bulkRevoke - 256 hash",
        issue256.receipt.cumulativeGasUsed
      );
    });
    it("update", async () => {
      const proxyInstance = await BaseAdminUpgradeabilityProxy.at(adminUpgradableProxyAddress);
      const {receipt} = await proxyInstance.upgradeTo(staticDocumentStoreWithRevokeReasons.address, {
        from: accounts[1]
      });
      recordGasCost("DocumentStore (AdminUpgradableProxy)", "upgrade", receipt.cumulativeGasUsed);
    });
  });
});
