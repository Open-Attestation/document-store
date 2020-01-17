const DocumentStore = artifacts.require("./DocumentStore.sol");
const DocumentStoreWithRevokeReasons = artifacts.require("./DocumentStoreWithRevokeReasons.sol");
const ProxyFactory = artifacts.require("./ProxyFactory.sol");
const BaseAdminUpgradeabilityProxy = artifacts.require("./BaseAdminUpgradeabilityProxy.sol");

DocumentStore.numberFormat = "String";

const {expect} = require("chai").use(require("chai-as-promised"));

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

contract("DocumentStore (Proxied)", accounts => {
  let documentStoreInstance = null;
  let documentStoreWithRevokeInstance = null;
  let proxyFactoryInstance = null;

  before(async () => {
    documentStoreInstance = await DocumentStore.new();
    proxyFactoryInstance = await ProxyFactory.new();
    documentStoreWithRevokeInstance = await DocumentStoreWithRevokeReasons.new();
  });

  describe("deployMinimal", () => {
    let proxyAddress;

    it("should deploy a minimal proxy of the DocumentStore", async () => {
      const encodedInitilizeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
      const receipt = await proxyFactoryInstance.deployMinimal(documentStoreInstance.address, encodedInitilizeCall);

      proxyAddress = receipt.logs[0].args.proxy;
      expect(receipt.logs[0].event).to.be.equal("ProxyCreated", "Proxy is not created");
      expect(web3.utils.isAddress(proxyAddress)).to.be.equal(true, "Proxy address is invalid");
    });

    it("should initialize DocumentStore with name and owner", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(proxyAddress);

      const name = await proxiedDocumentStoreInstance.name();
      const owner = await proxiedDocumentStoreInstance.owner();
      expect(name).to.be.equal(STORE_NAME, "Name of institute does not match");
      expect(owner).to.be.equal(accounts[0], "Owner of document store is incorrect");
    });

    it("should handle delegated calls to DocumentStore", async () => {
      const issuedHash = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const revokedHash = "0x99967813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6999";
      const proxiedDocumentStoreInstance = await DocumentStore.at(proxyAddress);
      await proxiedDocumentStoreInstance.issue(issuedHash);
      await proxiedDocumentStoreInstance.revoke(revokedHash);
      const isIssued = await proxiedDocumentStoreInstance.isIssued(issuedHash);
      const isRevoked = await proxiedDocumentStoreInstance.isRevoked(revokedHash);
      expect(isIssued).to.be.equal(true, "Document not issued");
      expect(isRevoked).to.be.equal(true, "Document not revoked");
    });
  });

  describe("deploy", () => {
    const initialIssuedHash = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
    const initialRevokedHash = "0x99967813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6999";
    const upgradedRevokedHash = "0x22222213bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6999";

    let proxyAddress;

    it("should deploy a InitializableAdminUpgradeabilityProxy of the DocumentStore", async () => {
      const salt = 1337;
      const encodedInitilizeCall = web3.eth.abi.encodeFunctionCall(initializeAbi, [STORE_NAME, accounts[0]]);
      const receipt = await proxyFactoryInstance.deploy(
        salt,
        documentStoreInstance.address,
        accounts[1], // Must use separate account for admin
        encodedInitilizeCall
      );

      proxyAddress = receipt.logs[0].args.proxy;

      expect(receipt.logs[0].event).to.be.equal("ProxyCreated", "Proxy is not created");
      expect(web3.utils.isAddress(proxyAddress)).to.be.equal(true, "Proxy address is invalid");
    });

    it("should initialise DocumentStore correctly", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(proxyAddress);

      const name = await proxiedDocumentStoreInstance.name.call();
      const owner = await proxiedDocumentStoreInstance.owner.call();

      expect(name).to.be.equal(STORE_NAME, "Name of institute does not match");
      expect(owner).to.be.equal(accounts[0], "Owner of document store is incorrect");
    });

    it("should handle delegated calls to DocumentStore", async () => {
      const proxiedDocumentStoreInstance = await DocumentStore.at(proxyAddress);
      await proxiedDocumentStoreInstance.issue(initialIssuedHash);
      await proxiedDocumentStoreInstance.revoke(initialRevokedHash);
      const isIssued = await proxiedDocumentStoreInstance.isIssued(initialIssuedHash);
      const isRevoked = await proxiedDocumentStoreInstance.isRevoked(initialRevokedHash);
      expect(isIssued).to.be.equal(true, "Document not issued");
      expect(isRevoked).to.be.equal(true, "Document not revoked");
    });

    it("should be upgradable to DocumentStoreWithRevokeReason", async () => {
      // Using adming account to upgrade contract implementation
      const proxyInstance = await BaseAdminUpgradeabilityProxy.at(proxyAddress);
      const upgradeReceipt = await proxyInstance.upgradeTo(documentStoreWithRevokeInstance.address, {
        from: accounts[1]
      });
      expect(upgradeReceipt.logs[0].event).to.be.equal("Upgraded", "Upgraded event is not emitted");
      expect(upgradeReceipt.logs[0].args.implementation).to.be.equal(
        documentStoreWithRevokeInstance.address,
        "Incorrect implementation contract address"
      );
    });

    it("should preserve state after upgrade", async () => {
      const proxiedDocumentStoreInstance = await DocumentStoreWithRevokeReasons.at(proxyAddress);

      const isIssued = await proxiedDocumentStoreInstance.isIssued(initialIssuedHash);
      const isRevoked = await proxiedDocumentStoreInstance.isRevoked(initialRevokedHash);

      expect(isIssued).to.be.equal(true, "Document issued state is not preserved");
      expect(isRevoked).to.be.equal(true, "Document revoked state is not preserved");
    });

    it("should delegate contract calls to DocumentStoreWithRevokeReasons", async () => {
      const proxiedDocumentStoreInstance = await DocumentStoreWithRevokeReasons.at(proxyAddress);

      const revokeReceipt = await proxiedDocumentStoreInstance.revoke(upgradedRevokedHash, 1337);
      expect(revokeReceipt.logs.length).to.be.equal(2, "Incorrect number of events");
      expect(revokeReceipt.logs[1].event).to.be.equal(
        "DocumentRevokedWithReason",
        "DocumentRevokedWithReason not emitted"
      );
      expect(revokeReceipt.logs[1].args.document).to.be.equal(upgradedRevokedHash, "Incorrect document revoked");
      expect(revokeReceipt.logs[1].args.reason.toString()).to.be.equal("1337", "Incorrect reasons");

      const revokeReason = await proxiedDocumentStoreInstance.revokeReason.call(upgradedRevokedHash);
      expect(revokeReason.toString()).to.be.equal("1337", "Incorrect reasons");
    });
  });
});

// SEE https://github.com/trufflesuite/truffle/issues/1230
