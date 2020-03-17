const DocumentStore = artifacts.require("./DocumentStore.sol");
const DocumentStoreFactory = artifacts.require("./DocumentStoreFactory.sol");

const {expect} = require("chai").use(require("chai-as-promised"));
const config = require("../config.js");

contract("DocumentStoreFactory", accounts => {
  let instance = null;

  beforeEach(async () => {
    instance = await DocumentStoreFactory.new();
  });

  describe("deploy", () => {
    it("should deploy new instance of DocumentStore correctly", async () => {
      // Test for events emitted
      const deployReceipt = await instance.deploy(config.INSTITUTE_NAME, {from: accounts[1]});
      expect(deployReceipt.logs[0].args.creator).to.be.equal(accounts[1], "Emitted contract creator does not match");

      // Test correctness of deployed DocumentStore
      const deployedDocumentStore = await DocumentStore.at(deployReceipt.logs[0].args.instance);
      const name = await deployedDocumentStore.name();
      expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
      const owner = await deployedDocumentStore.owner();
      expect(owner).to.be.equal(accounts[1], "Owner of deployed contract does not match creator");
    });
  });
});
