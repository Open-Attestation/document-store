const { expect } = require("chai").use(require("chai-as-promised"));
const config = require("../config.js");

describe("DocumentStoreCreator", async () => {
  let Accounts;
  let DocumentStore;

  before("", async () => {
    Accounts = await ethers.getSigners();
    DocumentStore = await ethers.getContractFactory("DocumentStore");
    DocumentStoreCreator = await ethers.getContractFactory("DocumentStoreCreator");
  })

  let DocumentStoreInstance;
  let DocumentStoreCreatorInstance;

  beforeEach("", async () => {
    // DocumentStoreInstance = await DocumentStore.connect(Accounts[0]).deploy(config.INSTITUTE_NAME);
    DocumentStoreCreatorInstance = await DocumentStoreCreator.connect(Accounts[0]);
    // await DocumentStoreInstance.deployed();
    // await DocumentStoreCreatorInstance.deployed();
  })

  describe("deploy", () => {
    it("should deploy new instance of DocumentStore correctly", async () => {
      // Test for events emitted by factory
      // const deployReceipt = await DocumentStoreCreatorInstance.deploy(config.INSTITUTE_NAME);
      // await DocumentStoreCreatorInstance.deployed();
      // expect(deployReceipt.logs[0].args.creator).to.be.equal(Accounts[0], "Emitted contract creator does not match");

      // // Test correctness of deployed DocumentStore
      // const deployedDocumentStore = await DocumentStore.at(deployReceipt.logs[0].args.instance);
      // const name = await deployedDocumentStore.name();
      // expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
      // const owner = await deployedDocumentStore.owner();
      // expect(owner).to.be.equal(Accounts[0], "Owner of deployed contract does not match creator");
    });
  });
})

// const UpgradableDocumentStore = artifacts.require("./UpgradableDocumentStore.sol");
// const DocumentStoreCreator = artifacts.require("./DocumentStoreCreator.sol");

// const { expect } = require("chai").use(require("chai-as-promised"));
// const config = require("../config.js");

// contract("DocumentStoreCreator", (accounts) => {
//   describe("deploy", () => {
//     it("should deploy new instance of DocumentStore correctly", async () => {
//       const documentStoreCreatorInstance = await DocumentStoreCreator.new();

//       // Test for events emitted by factory
//       const deployReceipt = await documentStoreCreatorInstance.deploy(config.INSTITUTE_NAME, { from: accounts[1] });
//       expect(deployReceipt.logs[0].args.creator).to.be.equal(accounts[1], "Emitted contract creator does not match");

//       // Test correctness of deployed DocumentStore
//       const deployedDocumentStore = await UpgradableDocumentStore.at(deployReceipt.logs[0].args.instance);
//       const name = await deployedDocumentStore.name();
//       expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
//       const owner = await deployedDocumentStore.owner();
//       expect(owner).to.be.equal(accounts[1], "Owner of deployed contract does not match creator");
//     });
//   });
// });
