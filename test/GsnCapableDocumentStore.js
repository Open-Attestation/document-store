const GsnCapableDocumentStore = artifacts.require("./GsnCapableDocumentStore.sol");
const ConfigurableTrustForwarder = artifacts.require("./ConfigurableTrustForwarder.sol");
const CalculateSelector = artifacts.require("calculateGsnCapableSelector");
GsnCapableDocumentStore.numberFormat = "String";

const {utils} = require("ethers");
const {expect} = require("chai").use(require("chai-as-promised"));
const config = require("../config.js");

contract("GsnCapableDocumentStore", accounts => {
  let instance = null;

  // Related: https://github.com/trufflesuite/truffle-core/pull/98#issuecomment-360619561
  beforeEach(async () => {
    instance = await GsnCapableDocumentStore.new(config.INSTITUTE_NAME, accounts[1], {from: accounts[0]});
  });

  describe("trustedForwarder", () => {
    it("returns trustedForwarder address", async () => {
      const trustedForwarder = await instance.getTrustedForwarder();
      expect(trustedForwarder).to.be.equal(accounts[1]);
    });

    it("should set trustedForwarder to given address", async () => {
      await instance.setTrustedForwarder(accounts[2]);
      const trustedForwarder = await instance.getTrustedForwarder();
      expect(trustedForwarder).to.be.equal(accounts[2]);
    });
  });

  describe("supportsInterface", () => {
    it("returns true if supportsInterface for GsnCapable", async () => {
      const calculatorInstance = await CalculateSelector.new();
      const expectedInterface = await calculatorInstance.calculateSelector();
      const supportsGsnCapableInterface = await instance.supportsInterface(expectedInterface);
      expect(supportsGsnCapableInterface).to.be.equal(true, `Expected selector: ${expectedInterface}`);
    });

    it("return false if does not support given interface", async () => {
      const supportsGsnCapableInterface = await instance.supportsInterface("0xffffffff");
      expect(supportsGsnCapableInterface).to.be.false;
    });
  });

  describe("paymaster", () => {
    it("should set paymaster address", async () => {
      const receipt = await instance.setPaymaster(accounts[2]);

      expect(receipt.logs[0].event).to.be.equal("PaymasterSet");
      expect(receipt.logs[0].args.target).to.be.equal(accounts[2]);

      const paymaster = await instance.getPaymaster();
      expect(paymaster).to.be.equal(accounts[2]);
    });
  });

  describe("able to receive relayed message", () => {
    let configurableInstance;
    let configurableForwarder;

    const owner = accounts[0];
    const relayer = accounts[1];

    // eslint-disable-next-line no-underscore-dangle
    const dsInterface = new utils.Interface(GsnCapableDocumentStore._json.abi);
    const issueFnData = dsInterface.encodeFunctionData("issue", [
      "0xe44e17b840f424f3764363e0fe331e812ef1a4d08ff8f63cbef5bfffe91a5e02"
    ]);

    beforeEach(async () => {
      configurableForwarder = await ConfigurableTrustForwarder.new();
      configurableInstance = await GsnCapableDocumentStore.new(config.INSTITUTE_NAME, configurableForwarder.address, {
        from: owner
      });
    });

    it("should issue document when receive a relayed call by owner from relayer", async () => {
      const configurableInstanceAddress = configurableInstance.address;
      await configurableForwarder.execute(issueFnData, owner, configurableInstanceAddress, {
        from: relayer
      });
      const documentIssued = await configurableInstance.isIssued(
        "0xe44e17b840f424f3764363e0fe331e812ef1a4d08ff8f63cbef5bfffe91a5e02"
      );
      expect(documentIssued).to.be.true;
    });

    it("should not allow issue document when receive a relayed call not by owner", async () => {
      const configurableInstanceAddress = configurableInstance.address;
      await expect(
        configurableForwarder.execute(issueFnData, relayer, configurableInstanceAddress, {
          from: relayer
        })
      ).to.be.rejectedWith(/revert/);
    });
  });
});
