const { expect } = require("chai").use(require("chai-as-promised"));
const { ethers } = require("hardhat");
const config = require("../config.js");

describe("GsnCapableDocumentStore", async () => {
  let Accounts;
  let GsnCapableDocumentStore;
  let CalculateSelector;

  before("", async () => {
    Accounts = await ethers.getSigners();
    GsnCapableDocumentStore = await ethers.getContractFactory("GsnCapableDocumentStore");
    CalculateSelector = await ethers.getContractFactory("CalculateGsnCapableSelector");
    GsnCapableDocumentStore.numberFormat = "String";
  });

  let GsnCapableDocumentStoreInstance;
  let CalculatorSelectorInstance;

  beforeEach("", async () => {
    GsnCapableDocumentStoreInstance = await GsnCapableDocumentStore.connect(Accounts[0]).deploy(
      config.INSTITUTE_NAME,
      Accounts[1].address
    );
    CalculatorSelectorInstance = await CalculateSelector.connect(Accounts[0]).deploy();
  });

  describe("trustedForwarder", () => {
    it("returns trustedForwarder address", async () => {
      const trustedForwarder = await GsnCapableDocumentStoreInstance.getTrustedForwarder();
      expect(trustedForwarder).to.be.equal(Accounts[1].address);
    });

    it("should set trustedForwarder to given address", async () => {
      await GsnCapableDocumentStoreInstance.setTrustedForwarder(Accounts[2].address);
      const trustedForwarder = await GsnCapableDocumentStoreInstance.getTrustedForwarder();
      expect(trustedForwarder).to.be.equal(Accounts[2].address);
    });
  });

  describe("supportsInterface", () => {
    it("returns true if supportsInterface for GsnCapable", async () => {
      const expectedInterface = await CalculatorSelectorInstance.calculateSelector();
      const supportsGsnCapableInterface = await GsnCapableDocumentStoreInstance.supportsInterface(expectedInterface);
      expect(supportsGsnCapableInterface).to.be.equal(true, `Expected selector: ${expectedInterface}`);
    });

    it("return false if does not support given interface", async () => {
      const supportsGsnCapableInterface = await GsnCapableDocumentStoreInstance.supportsInterface("0xffffffff");
      expect(supportsGsnCapableInterface).to.be.false;
    });
  });

  describe("paymaster", () => {
    it("should set paymaster address", async () => {
      const tx = await GsnCapableDocumentStoreInstance.setPaymaster(Accounts[2].address);
      const receipt = await tx.wait();

      expect(receipt.events[0].event).to.be.equal("PaymasterSet");
      expect(receipt.events[0].args.target).to.be.equal(Accounts[2].address);

      const paymaster = await GsnCapableDocumentStoreInstance.getPaymaster();
      expect(paymaster).to.be.equal(Accounts[2].address);
    });
  });

  describe("able to receive relayed message", async () => {
    let owner;
    let relayer;
    let dsInterface;
    let issueFnData;
    let ConfigurableTrustForwarder;

    before("", async () => {
      Accounts = await ethers.getSigners();
      GsnCapableDocumentStore = await ethers.getContractFactory("GsnCapableDocumentStore");
      ConfigurableTrustForwarder = await ethers.getContractFactory("ConfigurableTrustForwarder");
      GsnCapableDocumentStore.numberFormat = "String";
      // eslint-disable-next-line no-underscore-dangle
      dsInterface = new ethers.utils.Interface(JSON.parse(GsnCapableDocumentStore.interface.format("json")));
      issueFnData = dsInterface.encodeFunctionData("issue", [
        "0xe44e17b840f424f3764363e0fe331e812ef1a4d08ff8f63cbef5bfffe91a5e02",
      ]);
      [owner, relayer] = Accounts;
    });

    let configurableInstance;
    let configurableForwarder;

    beforeEach("", async () => {
      configurableForwarder = await ConfigurableTrustForwarder.deploy();
      configurableInstance = await GsnCapableDocumentStore.connect(owner).deploy(
        config.INSTITUTE_NAME,
        configurableForwarder.address
      );
    });

    it("should issue document when receive a relayed call by owner from relayer", async () => {
      const configurableInstanceAddress = configurableInstance.address;
      await configurableForwarder.connect(relayer).execute(issueFnData, owner.address, configurableInstanceAddress);
      const documentIssued = await configurableInstance.isIssued(
        "0xe44e17b840f424f3764363e0fe331e812ef1a4d08ff8f63cbef5bfffe91a5e02"
      );
      expect(documentIssued).to.be.true;
    });

    it("should not allow issue document when receive a relayed call not by owner", async () => {
      const configurableInstanceAddress = configurableInstance.address;
      await expect(
        configurableForwarder.connect(relayer).execute(issueFnData, relayer.address, configurableInstanceAddress)
      ).to.be.rejectedWith(/revert/);
    });
  });
});
