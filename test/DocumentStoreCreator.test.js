const { ethers } = require("hardhat");
const config = require("../config.js");

describe("DocumentStoreCreator", async () => {
  let Accounts;
  let DocumentStore;
  let DocumentStoreCreator;

  before(async () => {
    Accounts = await ethers.getSigners();
    DocumentStore = await ethers.getContractFactory("DocumentStore");
    DocumentStoreCreator = await ethers.getContractFactory("DocumentStoreCreator");
  });

  let DocumentStoreCreatorInstance;

  beforeEach(async () => {
    DocumentStoreCreatorInstance = await DocumentStoreCreator.connect(Accounts[0]).deploy();
    const tx = DocumentStoreCreatorInstance.deploymentTransaction();
    await tx.wait();
  });

  describe("deploy", () => {
    it("should deploy new instance of DocumentStore correctly", async () => {
      // Test for events emitted by factory
      const tx = await DocumentStoreCreatorInstance.deploy(config.INSTITUTE_NAME);
      const receipt = await tx.wait();

      expect(receipt.logs[4].args[1]).to.be.equal(Accounts[0].address, "Emitted contract creator does not match");
      // Test correctness of deployed DocumentStore

      const deployedDocumentStore = await DocumentStore.attach(receipt.logs[4].args[0]);

      const name = await deployedDocumentStore.name();
      expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");

      const hasAdminRole = await deployedDocumentStore.hasRole(ethers.ZeroHash, Accounts[0].address);
      expect(hasAdminRole).to.be.true;
    });
  });
});
