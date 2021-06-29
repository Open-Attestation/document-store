const { expect } = require("chai").use(require("chai-as-promised"));
const { ethers } = require("hardhat");
const config = require("../config.js");

describe("DocumentStoreCreator", async () => {
  let Accounts;
  let UpgradableDocumentStore;
  let DocumentStoreCreator;

  before("", async () => {
    Accounts = await ethers.getSigners();
    UpgradableDocumentStore = await ethers.getContractFactory("UpgradableDocumentStore");
    DocumentStoreCreator = await ethers.getContractFactory("DocumentStoreCreator");
  });

  let DocumentStoreCreatorInstance;

  beforeEach("", async () => {
    DocumentStoreCreatorInstance = await DocumentStoreCreator.connect(Accounts[0]).deploy();
  });

  describe("deploy", () => {
    it("should deploy new instance of DocumentStore correctly", async () => {
      // Test for events emitted by factory
      const tx = await DocumentStoreCreatorInstance.deploy(config.INSTITUTE_NAME);
      const receipt = await tx.wait();
      expect(receipt.events[2].args.creator).to.be.equal(
        Accounts[0].address,
        "Emitted contract creator does not match"
      );
      // Test correctness of deployed DocumentStore
      const deployedDocumentStore = await UpgradableDocumentStore.attach(receipt.events[2].args.instance);
      const name = await deployedDocumentStore.name();
      expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
      const owner = await deployedDocumentStore.owner();
      expect(owner).to.be.equal(Accounts[0].address, "Owner of deployed contract does not match creator");
    });
  });
});
