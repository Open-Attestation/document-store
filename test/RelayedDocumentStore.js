const RelayedDocumentStore = artifacts.require("./RelayedDocumentStore.sol");
RelayedDocumentStore.numberFormat = "String";

const {expect} = require("chai").use(require("chai-as-promised"));
const config = require("../config.js");

let instance = null;

const signMessage = async (message, nonce, signer) => {
  const store = instance.address; // Replays on different stores
  const messageHash = web3.utils.soliditySha3(message, nonce, store);
  const rawSignature = await web3.eth.sign(messageHash, signer);

  // see https://github.com/ethereum/go-ethereum/blob/v1.8.23/internal/ethapi/api.go#L465
  let v = parseInt(rawSignature.slice(130, 132), 16);
  if (v < 27) {
    v += 27;
  }
  const vHex = v.toString(16);
  const signature = rawSignature.slice(0, 130) + vHex;
  return signature;
};

contract("RelayedDocumentStore", accounts => {
  const relayer = accounts[0];
  const trustedSigner = accounts[1];

  // Related: https://github.com/trufflesuite/truffle-core/pull/98#issuecomment-360619561
  beforeEach(async () => {
    instance = await RelayedDocumentStore.new();
    await instance.initialize(config.INSTITUTE_NAME, trustedSigner, relayer, {from: relayer});
  });

  describe("initializer", () => {
    it("should have correct name", async () => {
      const name = await instance.name();
      expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
    });

    it("sets the owner properly", async () => {
      const owner = await instance.owner();
      expect(owner).to.be.equal(relayer);
    });
  });

  describe("version", () => {
    it("should have a version field value that should be bumped on new versions of the contract", async () => {
      const versionFromSolidity = await instance.version();
      expect(versionFromSolidity).to.be.equal("3.0.0");
    });
  });

  describe("issueRelayed", () => {
    it("should be able to issue a document signed by trusted signer and sent by relayer", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const nonce = await web3.eth.getTransactionCount(relayer); // Replays
      const signature = await signMessage(documentMerkleRoot, nonce, trustedSigner);
      const receipt = await instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer});

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentIssued", "Document issued event not emitted.");
      expect(receipt.logs[0].args.document).to.be.equal(documentMerkleRoot, "Incorrect event arguments emitted");

      const issued = await instance.isIssued(documentMerkleRoot);
      expect(issued, "Document is not issued").to.be.true;
    });

    it("should not be able to issue a document not signed by the trusted signer", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const nonce = await web3.eth.getTransactionCount(relayer); // Replays
      const signature = await signMessage(documentMerkleRoot, nonce, relayer);

      await expect(instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer})).to.be.rejectedWith(
        /revert/
      );

      const issued = await instance.isIssued(documentMerkleRoot);
      expect(issued, "Document is not issued").to.be.false;
    });

    it("should not allow duplicate issues", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const nonce = await web3.eth.getTransactionCount(relayer); // Replays
      const signature = await signMessage(documentMerkleRoot, nonce, trustedSigner);
      await instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer});

      // Check that reissue is rejected
      await expect(instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer})).to.be.rejectedWith(
        /revert/,
        "Duplicate issue was not rejected"
      );
    });

    it("only allows the owner to issue", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      await expect(instance.issue(documentMerkleRoot, {from: nonOwner})).to.be.rejectedWith(/revert/);
    });
  });

  describe("bulkIssueRelayed", () => {
    it("should be able to issue one document", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      // Using the has of the batch to then sign and broadcast on-chain limit data size
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer); // Replays
      const signature = await signMessage(documentsHash, nonce, trustedSigner);
      const receipt = await instance.bulkIssueRelayed(documentMerkleRoots, documentsHash, nonce, signature, {
        from: relayer
      });

      expect(receipt.logs[0].event).to.be.equal("DocumentIssued", "Document issued event not emitted.");

      const document1Issued = await instance.isIssued(documentMerkleRoots[0]);
      expect(document1Issued, "Document 1 is not issued").to.be.true;
    });

    it("should not be able to bulk issue if not signed by the trusted signer", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      // Using the has of the batch to then sign and broadcast on-chain limit data size
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, relayer); // singed by relayer instead of trustedSigner

      await expect(
        instance.bulkIssueRelayed(documentMerkleRoots, documentsHash, nonce, signature, {from: relayer})
      ).to.be.rejectedWith(/revert/);

      const issued = await instance.isIssued(documentMerkleRoots[0]);
      expect(issued, "Document is not issued").to.be.false;
    });

    it("should be able to issue multiple documents", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6332"
      ];
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);
      const receipt = await instance.bulkIssueRelayed(documentMerkleRoots, documentsHash, nonce, signature, {
        from: relayer
      });

      expect(receipt.logs[0].event).to.be.equal("DocumentIssued", "Document issued event not emitted.");
      expect(receipt.logs[0].args.document).to.be.equal(documentMerkleRoots[0], "Event not emitted for document 1");
      expect(receipt.logs[1].args.document).to.be.equal(documentMerkleRoots[1], "Event not emitted for document 2");
      expect(receipt.logs[2].args.document).to.be.equal(documentMerkleRoots[2], "Event not emitted for document 3");

      const document1Issued = await instance.isIssued(documentMerkleRoots[0]);
      expect(document1Issued, "Document 1 is not issued").to.be.true;
      const document2Issued = await instance.isIssued(documentMerkleRoots[1]);
      expect(document2Issued, "Document 2 is not issued").to.be.true;
      const document3Issued = await instance.isIssued(documentMerkleRoots[2]);
      expect(document3Issued, "Document 3 is not issued").to.be.true;
    });

    it("should not allow duplicate issues", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"
      ];
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);
      // Check that reissue is rejected
      await expect(
        instance.bulkIssueRelayed(documentMerkleRoots, documentsHash, nonce, signature, {from: relayer})
      ).to.be.rejectedWith(/revert/, "Duplicate issue was not rejected");
    });

    it("only allows the owner to issue", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);

      await expect(
        instance.bulkIssueRelayed(documentMerkleRoots, documentsHash, nonce, signature, {from: nonOwner})
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("revokeRelayed", () => {
    it("should allow the revocation of a valid and issued document", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      let nonce = await web3.eth.getTransactionCount(relayer);
      let signature = await signMessage(documentMerkleRoot, nonce, trustedSigner);
      await instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer});

      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      nonce = await web3.eth.getTransactionCount(relayer);
      signature = await signMessage(documentHash, nonce, trustedSigner);
      const receipt = await instance.revokeRelayed(documentHash, nonce, signature, {from: relayer});

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.logs[0].args.document).to.be.equal(documentHash);

      const isRevoked = await instance.isRevoked(documentHash);
      expect(isRevoked).to.be.true;
    });

    it("should allow the revocation of an issued root", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      let nonce = await web3.eth.getTransactionCount(relayer);
      let signature = await signMessage(documentMerkleRoot, nonce, trustedSigner);
      await instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer});

      const documentHash = documentMerkleRoot;
      nonce = await web3.eth.getTransactionCount(relayer);
      signature = await signMessage(documentHash, nonce, trustedSigner);
      const receipt = await instance.revokeRelayed(documentHash, nonce, signature, {from: relayer});

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.logs[0].args.document).to.be.equal(documentHash);

      const isRevoked = await instance.isRevoked(documentHash);
      expect(isRevoked).to.be.true;
    });

    it("should not allow repeated revocation of a valid and issued document", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      let nonce = await web3.eth.getTransactionCount(relayer);
      let signature = await signMessage(documentMerkleRoot, nonce, trustedSigner);
      await instance.issueRelayed(documentMerkleRoot, nonce, signature, {from: relayer});

      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      nonce = await web3.eth.getTransactionCount(relayer);
      signature = await signMessage(documentHash, nonce, trustedSigner);
      await instance.revokeRelayed(documentHash, nonce, signature, {from: relayer});

      await expect(instance.revokeRelayed(documentHash, nonce, signature, {from: relayer})).to.be.rejectedWith(
        /revert/
      );
    });

    it("should allow revocation of an unissued document", async () => {
      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentHash, nonce, trustedSigner);
      const receipt = await instance.revokeRelayed(documentHash, nonce, signature, {from: relayer});

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.logs[0].args.document).to.be.equal(documentHash);
    });
  });

  describe("bulkRevokeRelayed", () => {
    it("should be able to revoke one document", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);
      const receipt = await instance.bulkRevokeRelayed(documentMerkleRoots, documentsHash, nonce, signature, {
        from: relayer
      });

      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked", "Document revoked event not emitted.");

      const document1Revoked = await instance.isRevoked(documentMerkleRoots[0]);
      expect(document1Revoked, "Document 1 is not revoked").to.be.true;
    });

    it("should be able to revoke multiple documents", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6332"
      ];
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);
      const receipt = await instance.bulkRevokeRelayed(documentMerkleRoots, documentsHash, nonce, signature, {
        from: relayer
      });

      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked", "Document revoked event not emitted.");
      expect(receipt.logs[0].args.document).to.be.equal(documentMerkleRoots[0], "Event not emitted for document 1");
      expect(receipt.logs[1].args.document).to.be.equal(documentMerkleRoots[1], "Event not emitted for document 2");
      expect(receipt.logs[2].args.document).to.be.equal(documentMerkleRoots[2], "Event not emitted for document 3");

      const document1Revoked = await instance.isRevoked(documentMerkleRoots[0]);
      expect(document1Revoked, "Document 1 is not revoked").to.be.true;
      const document2Revoked = await instance.isRevoked(documentMerkleRoots[1]);
      expect(document2Revoked, "Document 2 is not revoked").to.be.true;
      const document3Revoked = await instance.isRevoked(documentMerkleRoots[2]);
      expect(document3Revoked, "Document 3 is not revoked").to.be.true;
    });

    it("should not allow duplicate revokes", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"
      ];

      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);

      // Check that revoke is rejected
      await expect(
        instance.bulkRevokeRelayed(documentMerkleRoots, documentsHash, nonce, signature, {from: relayer})
      ).to.be.rejectedWith(/revert/, "Duplicate revoke was not rejected");
    });

    it("only allows the owner to revoke", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      const documentsHash = web3.utils.soliditySha3(...documentMerkleRoots);
      const nonce = await web3.eth.getTransactionCount(relayer);
      const signature = await signMessage(documentsHash, nonce, trustedSigner);

      // Check that revoke is rejected
      await expect(
        instance.bulkRevokeRelayed(documentMerkleRoots, documentsHash, nonce, signature, {from: nonOwner})
      ).to.be.rejectedWith(/revert/);
    });
  });
});
