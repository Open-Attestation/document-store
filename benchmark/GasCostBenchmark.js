const { ethers } = require("hardhat");
const { groupBy, mapValues } = require("lodash");
const { generateHashes } = require("../scripts/generateHashes");

// const initializeAbi = {
//   constant: false,
//   inputs: [
//     {
//       internalType: "string",
//       name: "_name",
//       type: "string",
//     },
//     {
//       internalType: "address",
//       name: "owner",
//       type: "address",
//     },
//   ],
//   name: "initialize",
//   outputs: [],
//   payable: false,
//   stateMutability: "nonpayable",
//   type: "function",
// };

// const STORE_NAME = "THE_STORE_NAME";
let lastIssuedHash = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6432";

const randomHashes = (num) => {
  const generated = generateHashes(num, lastIssuedHash);
  lastIssuedHash = generated[generated.length - 1];
  return generated;
};

const randomHash = () => randomHashes(1)[0];

const getCumulativeGasUsed = async (tx) => {
  let cumulativeGasUsed;
  let receipt;

  if (tx.deployTransaction) {
    receipt = await tx.deployTransaction.wait();
    cumulativeGasUsed = receipt.cumulativeGasUsed.toNumber();
  } else {
    receipt = await tx.wait();
    cumulativeGasUsed = await receipt.cumulativeGasUsed.toNumber();
  }

  return cumulativeGasUsed;
};

describe("Gas Cost Benchmarks", () => {
  const gasRecords = [];
  const recordGasCost = (contract, context, gas) => {
    gasRecords.push({
      contract,
      context,
      gas,
    });
  };

  const benchmarkTransfer = async (contractName, contractInstance, accounts) => {
    const tx = await contractInstance.transferOwnership(accounts[2].address);
    recordGasCost(contractName, "transferOwnership", await getCumulativeGasUsed(tx));

    // Revert the owner by transferring back
    await contractInstance.connect(accounts[2]).transferOwnership(accounts[0].address);
  };

  const benchmarkIssue = async (contractName, contractInstance) => {
    const tx = await contractInstance.issue(randomHash());
    recordGasCost(contractName, "issue", await getCumulativeGasUsed(tx));
  };

  const benchmarkBulkIssue = async (contractName, contractInstance) => {
    const tx1 = await contractInstance.bulkIssue(randomHashes(1));
    recordGasCost(contractName, "bulkIssue - 1 hash", await getCumulativeGasUsed(tx1));
    const tx2 = await contractInstance.bulkIssue(randomHashes(2));
    recordGasCost(contractName, "bulkIssue - 2 hash", await getCumulativeGasUsed(tx2));
    const tx3 = await contractInstance.bulkIssue(randomHashes(4));
    recordGasCost(contractName, "bulkIssue - 4 hash", await getCumulativeGasUsed(tx3));
    const tx4 = await contractInstance.bulkIssue(randomHashes(8));
    recordGasCost(contractName, "bulkIssue - 8 hash", await getCumulativeGasUsed(tx4));
    const tx5 = await contractInstance.bulkIssue(randomHashes(16));
    recordGasCost(contractName, "bulkIssue - 16 hash", await getCumulativeGasUsed(tx5));
    const tx6 = await contractInstance.bulkIssue(randomHashes(32));
    recordGasCost(contractName, "bulkIssue - 32 hash", await getCumulativeGasUsed(tx6));
    const tx7 = await contractInstance.bulkIssue(randomHashes(64));
    recordGasCost(contractName, "bulkIssue - 64 hash", await getCumulativeGasUsed(tx7));
    const tx8 = await contractInstance.bulkIssue(randomHashes(128));
    recordGasCost(contractName, "bulkIssue - 128 hash", await getCumulativeGasUsed(tx8));
    const tx9 = await contractInstance.bulkIssue(randomHashes(256));
    recordGasCost(contractName, "bulkIssue - 256 hash", await getCumulativeGasUsed(tx9));
  };

  const benchmarkRevoke = async (contractName, contractInstance) => {
    const tx = await contractInstance.revoke(randomHash());
    recordGasCost(contractName, "revoke", await getCumulativeGasUsed(tx));
  };

  const benchmarkBulkRevoke = async (contractName, contractInstance) => {
    const tx1 = await contractInstance.bulkRevoke(randomHashes(1));
    recordGasCost(contractName, "bulkRevoke - 1 hash", await getCumulativeGasUsed(tx1));
    const tx2 = await contractInstance.bulkRevoke(randomHashes(2));
    recordGasCost(contractName, "bulkRevoke - 2 hash", await getCumulativeGasUsed(tx2));
    const tx3 = await contractInstance.bulkRevoke(randomHashes(4));
    recordGasCost(contractName, "bulkRevoke - 4 hash", await getCumulativeGasUsed(tx3));
    const tx4 = await contractInstance.bulkRevoke(randomHashes(8));
    recordGasCost(contractName, "bulkRevoke - 8 hash", await getCumulativeGasUsed(tx4));
    const tx5 = await contractInstance.bulkRevoke(randomHashes(16));
    recordGasCost(contractName, "bulkRevoke - 16 hash", await getCumulativeGasUsed(tx5));
    const tx6 = await contractInstance.bulkRevoke(randomHashes(32));
    recordGasCost(contractName, "bulkRevoke - 32 hash", await getCumulativeGasUsed(tx6));
    const tx7 = await contractInstance.bulkRevoke(randomHashes(64));
    recordGasCost(contractName, "bulkRevoke - 64 hash", await getCumulativeGasUsed(tx7));
    const tx8 = await contractInstance.bulkRevoke(randomHashes(128));
    recordGasCost(contractName, "bulkRevoke - 128 hash", await getCumulativeGasUsed(tx8));
    const tx9 = await contractInstance.bulkRevoke(randomHashes(256));
    recordGasCost(contractName, "bulkRevoke - 256 hash", await getCumulativeGasUsed(tx9));
  };

  after(() => {
    const groupedRecords = groupBy(gasRecords, (record) => record.context);
    const records = mapValues(groupedRecords, (contextualizedRecords) =>
      contextualizedRecords.reduce(
        (state, current) => ({
          ...state,
          [current.contract]: current.gas,
        }),
        {}
      )
    );
    // eslint-disable-next-line no-console
    console.table(records);
  });

  let Accounts;
  let DocumentStore;
  let UpgradableDocumentStore;
  let DocumentStoreCreator;

  before(async () => {
    Accounts = await ethers.getSigners();
    DocumentStore = await ethers.getContractFactory("DocumentStore");
    UpgradableDocumentStore = await ethers.getContractFactory("UpgradableDocumentStore");
    DocumentStoreCreator = await ethers.getContractFactory("DocumentStoreCreator");
    UpgradableDocumentStore.numberFormat = "String";
  });

  describe("DocumentStore", () => {
    const contractName = "DocumentStore";

    it("runs benchmark", async () => {
      // Deploy & initialize document store contract
      const documentStoreInstance = await DocumentStore.deploy(contractName);
      const tx = await documentStoreInstance.deployed();
      recordGasCost(contractName, "deployment", await getCumulativeGasUsed(tx));

      // const documentStoreInstance = await UpgradableDocumentStore.deploy();
      // const initializeTx = await documentStoreInstance.functions["initialize(string)"](STORE_NAME);
      // recordGasCost(
      //   contractName,
      //   "deployment",
      //   (await getCumulativeGasUsed(documentStoreInstance)) + (await getCumulativeGasUsed(initializeTx))
      // );

      await benchmarkTransfer(contractName, documentStoreInstance, Accounts);
      await benchmarkIssue(contractName, documentStoreInstance);
      await benchmarkBulkIssue(contractName, documentStoreInstance);
      await benchmarkRevoke(contractName, documentStoreInstance);
      await benchmarkBulkRevoke(contractName, documentStoreInstance);
    });
  }, 20000);

  describe("DocumentStoreCreator", () => {
    it("runs benchmark", async () => {
      const documentStoreCreatorInstance = await DocumentStoreCreator.deploy();
      const tx = await documentStoreCreatorInstance.deployed();
      recordGasCost("DocumentStoreCreator", "deployment", await getCumulativeGasUsed(tx));
    });
  });

  // describe(
  //   "DocumentStore (Minimal Proxy)",
  //   (accounts) => {
  //     const contractName = "DocumentStore (Minimal Proxy)";

  //     it("runs benchmark", async () => {
  //       // Deploy & initialize document store contract in one transaction
  //       const encodedInitializeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
  //       const deployTx = await staticProxyFactoryInstance.deployMinimal(
  //         staticUpgradableDocumentStoreInstance.address,
  //         encodedInitializeCall
  //       );
  //       const minimalProxyAddress = deployTx.logs[0].args.proxy;
  //       recordGasCost(contractName, "deployment", deployTx.receipt.cumulativeGasUsed);

  //       const proxiedDocumentStoreInstance = await UpgradableDocumentStore.at(minimalProxyAddress);

  //       await benchmarkTransfer(contractName, proxiedDocumentStoreInstance, accounts);
  //       await benchmarkIssue(contractName, proxiedDocumentStoreInstance);
  //       await benchmarkBulkIssue(contractName, proxiedDocumentStoreInstance);
  //       await benchmarkRevoke(contractName, proxiedDocumentStoreInstance);
  //       await benchmarkBulkRevoke(contractName, proxiedDocumentStoreInstance);
  //     });
  //   },
  //   20000
  // );

  // describe(
  //   "DocumentStore (AdminUpgradableProxy)",
  //   (accounts) => {
  //     const contractName = "DocumentStore (AdminUpgradableProxy)";

  //     it("runs benchmark", async () => {
  //       // Deploy & initialize document store contract
  //       const encodedInitializeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
  //       const salt = 1337;
  //       const deployTx = await staticProxyFactoryInstance.deploy(
  //         salt,
  //         staticUpgradableDocumentStoreInstance.address,
  //         accounts[1], // Must use separate account for proxy admin
  //         encodedInitializeCall
  //       );
  //       recordGasCost(contractName, "deployment", deployTx.receipt.cumulativeGasUsed);

  //       const adminUpgradableProxyAddress = deployTx.logs[0].args.proxy;
  //       const proxiedDocumentStoreInstance = await UpgradableDocumentStore.at(adminUpgradableProxyAddress);

  //       await benchmarkTransfer(contractName, proxiedDocumentStoreInstance, accounts);
  //       await benchmarkIssue(contractName, proxiedDocumentStoreInstance);
  //       await benchmarkBulkIssue(contractName, proxiedDocumentStoreInstance);
  //       await benchmarkRevoke(contractName, proxiedDocumentStoreInstance);
  //       await benchmarkBulkRevoke(contractName, proxiedDocumentStoreInstance);

  //       // update
  //       const proxyInstance = await BaseAdminUpgradeabilityProxy.at(adminUpgradableProxyAddress);
  //       const { receipt } = await proxyInstance.upgradeTo(staticDocumentStoreWithRevokeReasons.address, {
  //         from: accounts[1],
  //       });
  //       recordGasCost(contractName, "upgrade", receipt.cumulativeGasUsed);
  //     });
  //   },
  //   20000
  // );
});
