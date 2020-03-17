const {groupBy, mapValues} = require("lodash");

const DocumentStore = artifacts.require("./DocumentStore.sol");
const DocumentStoreWithRevokeReasons = artifacts.require("./DocumentStoreWithRevokeReasons.sol");
const ProxyFactory = artifacts.require("./ProxyFactory.sol");
const DocumentStoreCreator = artifacts.require("./DocumentStoreCreator.sol");
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

  const benchmarkBulkIssue = async (contractName, contractInstance) => {
    const issue1 = await contractInstance.bulkIssue(randomHashes(1));
    recordGasCost(contractName, "bulkIssue - 1 hash", issue1.receipt.cumulativeGasUsed);
    const issue2 = await contractInstance.bulkIssue(randomHashes(2));
    recordGasCost(contractName, "bulkIssue - 2 hash", issue2.receipt.cumulativeGasUsed);
    const issue4 = await contractInstance.bulkIssue(randomHashes(4));
    recordGasCost(contractName, "bulkIssue - 4 hash", issue4.receipt.cumulativeGasUsed);
    const issue8 = await contractInstance.bulkIssue(randomHashes(8));
    recordGasCost(contractName, "bulkIssue - 8 hash", issue8.receipt.cumulativeGasUsed);
    const issue16 = await contractInstance.bulkIssue(randomHashes(16));
    recordGasCost(contractName, "bulkIssue - 16 hash", issue16.receipt.cumulativeGasUsed);
    const issue32 = await contractInstance.bulkIssue(randomHashes(32));
    recordGasCost(contractName, "bulkIssue - 32 hash", issue32.receipt.cumulativeGasUsed);
    const issue64 = await contractInstance.bulkIssue(randomHashes(64));
    recordGasCost(contractName, "bulkIssue - 64 hash", issue64.receipt.cumulativeGasUsed);
    const issue128 = await contractInstance.bulkIssue(randomHashes(128));
    recordGasCost(contractName, "bulkIssue - 128 hash", issue128.receipt.cumulativeGasUsed);
    const issue256 = await contractInstance.bulkIssue(randomHashes(256));
    recordGasCost(contractName, "bulkIssue - 256 hash", issue256.receipt.cumulativeGasUsed);
  };

  const benchmarkBulkRevoke = async (contractName, contractInstance) => {
    const revoke1 = await contractInstance.bulkRevoke(randomHashes(1));
    recordGasCost(contractName, "bulkRevoke - 1 hash", revoke1.receipt.cumulativeGasUsed);
    const revoke2 = await contractInstance.bulkRevoke(randomHashes(2));
    recordGasCost(contractName, "bulkRevoke - 2 hash", revoke2.receipt.cumulativeGasUsed);
    const revoke4 = await contractInstance.bulkRevoke(randomHashes(4));
    recordGasCost(contractName, "bulkRevoke - 4 hash", revoke4.receipt.cumulativeGasUsed);
    const revoke8 = await contractInstance.bulkRevoke(randomHashes(8));
    recordGasCost(contractName, "bulkRevoke - 8 hash", revoke8.receipt.cumulativeGasUsed);
    const revoke16 = await contractInstance.bulkRevoke(randomHashes(16));
    recordGasCost(contractName, "bulkRevoke - 16 hash", revoke16.receipt.cumulativeGasUsed);
    const revoke32 = await contractInstance.bulkRevoke(randomHashes(32));
    recordGasCost(contractName, "bulkRevoke - 32 hash", revoke32.receipt.cumulativeGasUsed);
    const revoke64 = await contractInstance.bulkRevoke(randomHashes(64));
    recordGasCost(contractName, "bulkRevoke - 64 hash", revoke64.receipt.cumulativeGasUsed);
    const revoke128 = await contractInstance.bulkRevoke(randomHashes(128));
    recordGasCost(contractName, "bulkRevoke - 128 hash", revoke128.receipt.cumulativeGasUsed);
    const revoke256 = await contractInstance.bulkRevoke(randomHashes(256));
    recordGasCost(contractName, "bulkRevoke - 256 hash", revoke256.receipt.cumulativeGasUsed);
  };

  const benchmarkRevoke = async (contractName, contractInstance) => {
    const revokeTx = await contractInstance.revoke(randomHash());
    recordGasCost(contractName, "revoke", revokeTx.receipt.cumulativeGasUsed);
  };

  const benchmarkIssue = async (contractName, contractInstance) => {
    const issueTx = await contractInstance.issue(randomHash());
    recordGasCost(contractName, "issue", issueTx.receipt.cumulativeGasUsed);
  };

  const benchmarkTransfer = async (contractName, contractInstance, accounts) => {
    const transferTx = await contractInstance.transferOwnership(accounts[2]);
    recordGasCost(contractName, "transferOwnership", transferTx.receipt.cumulativeGasUsed);

    // Revert the owner by transferring back
    await contractInstance.transferOwnership(accounts[0], {from: accounts[2]});
  };

  after(() => {
    const groupedRecords = groupBy(gasRecords, record => record.context);
    const records = mapValues(groupedRecords, contextualizedRecords =>
      contextualizedRecords.reduce(
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

  contract(
    "DocumentStore",
    accounts => {
      const contractName = "DocumentStore";

      it("runs benchmark", async () => {
        // Deploy & initialize document store contract
        const documentStoreInstance = await DocumentStore.new();
        const deploymentReceipt = await web3.eth.getTransactionReceipt(documentStoreInstance.transactionHash);
        const initializeReceipt = await documentStoreInstance.initialize(STORE_NAME, accounts[0]);
        recordGasCost(
          contractName,
          "deployment & initialize",
          deploymentReceipt.cumulativeGasUsed + initializeReceipt.receipt.cumulativeGasUsed
        );

        await benchmarkTransfer(contractName, documentStoreInstance, accounts);
        await benchmarkIssue(contractName, documentStoreInstance);
        await benchmarkBulkIssue(contractName, documentStoreInstance);
        await benchmarkRevoke(contractName, documentStoreInstance);
        await benchmarkBulkRevoke(contractName, documentStoreInstance);
      });
    },
    20000
  );

  contract("ProxyFactory", () => {
    it("runs benchmark", async () => {
      const deployment = await ProxyFactory.new();
      const receipt = await web3.eth.getTransactionReceipt(deployment.transactionHash);
      recordGasCost("ProxyFactory", "deployment", receipt.cumulativeGasUsed);
    });
  });

  contract("DocumentStoreCreator", () => {
    it("runs benchmark", async () => {
      const deployment = await DocumentStoreCreator.new();
      const receipt = await web3.eth.getTransactionReceipt(deployment.transactionHash);
      recordGasCost("DocumentStoreCreator", "deployment", receipt.cumulativeGasUsed);
    });
  });

  contract(
    "DocumentStore (Minimal Proxy)",
    accounts => {
      const contractName = "DocumentStore (Minimal Proxy)";

      it("runs benchmark", async () => {
        // Deploy & initialize document store contract in one transaction
        const encodedInitializeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
        const deployTx = await staticProxyFactoryInstance.deployMinimal(
          staticDocumentStoreInstance.address,
          encodedInitializeCall
        );
        const minimalProxyAddress = deployTx.logs[0].args.proxy;
        recordGasCost(contractName, "deployment & initialize", deployTx.receipt.cumulativeGasUsed);

        const proxiedDocumentStoreInstance = await DocumentStore.at(minimalProxyAddress);

        await benchmarkTransfer(contractName, proxiedDocumentStoreInstance, accounts);
        await benchmarkIssue(contractName, proxiedDocumentStoreInstance);
        await benchmarkBulkIssue(contractName, proxiedDocumentStoreInstance);
        await benchmarkRevoke(contractName, proxiedDocumentStoreInstance);
        await benchmarkBulkRevoke(contractName, proxiedDocumentStoreInstance);
      });
    },
    20000
  );

  contract(
    "DocumentStore (AdminUpgradableProxy)",
    accounts => {
      const contractName = "DocumentStore (AdminUpgradableProxy)";

      it("runs benchmark", async () => {
        // Deploy & initialize document store contract
        const encodedInitializeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
        const salt = 1337;
        const deployTx = await staticProxyFactoryInstance.deploy(
          salt,
          staticDocumentStoreInstance.address,
          accounts[1], // Must use separate account for proxy admin
          encodedInitializeCall
        );
        recordGasCost(contractName, "deployment & initialize", deployTx.receipt.cumulativeGasUsed);

        const adminUpgradableProxyAddress = deployTx.logs[0].args.proxy;
        const proxiedDocumentStoreInstance = await DocumentStore.at(adminUpgradableProxyAddress);

        await benchmarkTransfer(contractName, proxiedDocumentStoreInstance, accounts);
        await benchmarkIssue(contractName, proxiedDocumentStoreInstance);
        await benchmarkBulkIssue(contractName, proxiedDocumentStoreInstance);
        await benchmarkRevoke(contractName, proxiedDocumentStoreInstance);
        await benchmarkBulkRevoke(contractName, proxiedDocumentStoreInstance);

        // update
        const proxyInstance = await BaseAdminUpgradeabilityProxy.at(adminUpgradableProxyAddress);
        const {receipt} = await proxyInstance.upgradeTo(staticDocumentStoreWithRevokeReasons.address, {
          from: accounts[1]
        });
        recordGasCost(contractName, "upgrade", receipt.cumulativeGasUsed);
      });
    },
    20000
  );
});
