const { expect, assert } = require("chai").use(require("chai-as-promised"));
const { ethers } = require("hardhat");
const { get } = require("lodash");
const config = require("../config.js");

describe("DocumentStore", async () => {
  let Accounts;
  let DocumentStore;
  let DocumentStoreInstance;

  const adminRole = ethers.constants.HashZero;
  const issuerRole = ethers.utils.id("ISSUER_ROLE");
  const revokerRole = ethers.utils.id("REVOKER_ROLE");

  const wrongVar = { name: "hello"}
  const {name } = wrongVar;


  beforeEach("", async () => {
    Accounts = await ethers.getSigners();
    DocumentStore = await ethers.getContractFactory("DocumentStore");
    DocumentStoreInstance = await DocumentStore.connect(Accounts[0]).deploy(config.INSTITUTE_NAME, Accounts[0].address);
    await DocumentStoreInstance.deployed();
  });

  describe("initializer", () => {
    it("should have correct name", async () => {
      const name = await DocumentStoreInstance.name();
      expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
    });
  });

  describe("Access Control", () => {
    describe("Initialisation", () => {
      it("should revert if owner is zero address", async () => {
        const tx = DocumentStore.connect(Accounts[0]).deploy(config.INSTITUTE_NAME, ethers.constants.AddressZero);

        await expect(tx).to.be.revertedWith("Owner is zero");
      });

      describe("Owner Default Roles", () => {
        it("should have default admin role", async () => {
          const hasRole = await DocumentStoreInstance.hasRole(adminRole, Accounts[0].address);

          expect(hasRole).to.be.true;
        });

        it("should have issuer role", async () => {
          const hasRole = await DocumentStoreInstance.hasRole(issuerRole, Accounts[0].address);

          expect(hasRole).to.be.true;
        });

        it("should have revoker role", async () => {
          const hasRole = await DocumentStoreInstance.hasRole(revokerRole, Accounts[0].address);

          expect(hasRole).to.be.true;
        });
      });
    });
  });

  describe("version", () => {
    it("should have a version field value that should be bumped on new versions of the contract", async () => {
      const versionFromSolidity = await DocumentStoreInstance.version();
      expect(versionFromSolidity).to.be.equal("2.3.0");
    });
  });

  describe("issue", () => {
    const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

    it("should be able to issue a document", async () => {
      const tx = await DocumentStoreInstance.issue(documentMerkleRoot);
      const receipt = await tx.wait();

      // FIXME: Use a utility helper to watch for event
      expect(receipt.events[0].event).to.be.equal("DocumentIssued", "Document issued event not emitted.");
      expect(receipt.events[0].args.document).to.be.equal(documentMerkleRoot, "Incorrect event arguments emitted");

      const issued = await DocumentStoreInstance.isIssued(documentMerkleRoot);
      expect(issued, "Document is not issued").to.be.true;
    });

    it("should not allow duplicate issues", async () => {
      await DocumentStoreInstance.issue(documentMerkleRoot);

      // Check that reissue is rejected
      await expect(DocumentStoreInstance.issue(documentMerkleRoot)).to.be.rejectedWith(
        /revert/,
        "Duplicate issue was not rejected"
      );
    });

    it("should revert when caller has no issuer role", async () => {
      const account = Accounts[1];
      const hasNoIssuerRole = await DocumentStoreInstance.hasRole(issuerRole, account.address);
      assert.isFalse(hasNoIssuerRole, "Non-Issuer Account has issuer role");

      await expect(DocumentStoreInstance.connect(account).issue(documentMerkleRoot)).to.be.rejectedWith(
        /AccessControl/
      );
    });

    it("should issue successfully when caller has issuer role", async () => {
      const account = Accounts[0];
      const hasIssuerRole = await DocumentStoreInstance.hasRole(issuerRole, account.address);
      assert.isTrue(hasIssuerRole, "Issuer Account has issuer role");

      await DocumentStoreInstance.connect(account).issue(documentMerkleRoot);
      const issued = await DocumentStoreInstance.isIssued(documentMerkleRoot);

      expect(issued).to.be.true;
    });
  });

  describe("bulkIssue", () => {
    it("should be able to issue one document", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      const tx = await DocumentStoreInstance.bulkIssue(documentMerkleRoots);
      const receipt = await tx.wait();
      // FIXME:
      expect(receipt.events[0].event).to.be.equal("DocumentIssued", "Document issued event not emitted.");

      const document1Issued = await DocumentStoreInstance.isIssued(documentMerkleRoots[0]);
      expect(document1Issued, "Document 1 is not issued").to.be.true;
    });

    it("should be able to issue multiple documents", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6332",
      ];
      const tx = await DocumentStoreInstance.bulkIssue(documentMerkleRoots);
      const receipt = await tx.wait();
      // FIXME:
      expect(receipt.events[0].event).to.be.equal("DocumentIssued", "Document issued event not emitted.");
      expect(receipt.events[0].args.document).to.be.equal(documentMerkleRoots[0], "Event not emitted for document 1");
      expect(receipt.events[1].args.document).to.be.equal(documentMerkleRoots[1], "Event not emitted for document 2");
      expect(receipt.events[2].args.document).to.be.equal(documentMerkleRoots[2], "Event not emitted for document 3");

      const document1Issued = await DocumentStoreInstance.isIssued(documentMerkleRoots[0]);
      expect(document1Issued, "Document 1 is not issued").to.be.true;
      const document2Issued = await DocumentStoreInstance.isIssued(documentMerkleRoots[1]);
      expect(document2Issued, "Document 2 is not issued").to.be.true;
      const document3Issued = await DocumentStoreInstance.isIssued(documentMerkleRoots[2]);
      expect(document3Issued, "Document 3 is not issued").to.be.true;
    });

    it("should not allow duplicate issues", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
      ];

      // Check that reissue is rejected
      await expect(DocumentStoreInstance.bulkIssue(documentMerkleRoots)).to.be.rejectedWith(
        /revert/,
        "Duplicate issue was not rejected"
      );
    });

    it("should revert when caller has no issuer role", async () => {
      const nonIssuerAccount = Accounts[1];
      const hasNoIssuerRole = await DocumentStoreInstance.hasRole(issuerRole, nonIssuerAccount.address);
      assert.isFalse(hasNoIssuerRole, "Non-Issuer Account has issuer role");

      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];

      // FIXME:
      await expect(DocumentStoreInstance.connect(nonIssuerAccount).bulkIssue(documentMerkleRoots)).to.be.rejectedWith(
        /AccessControl/
      );
    });

    it("should bulk issue successfully when caller has issuer role", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];

      const account = Accounts[0];
      const hasIssuerRole = await DocumentStoreInstance.hasRole(issuerRole, account.address);
      assert.isTrue(hasIssuerRole, "Issuer Account has no issuer role");

      await DocumentStoreInstance.connect(account).bulkIssue(documentMerkleRoots);
      const issued = await DocumentStoreInstance.isIssued(documentMerkleRoots[0]);

      expect(issued).to.be.true;
    });
  });

  describe("getIssuedBlock", () => {
    it("returns the block number of issued batches", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await DocumentStoreInstance.issue(documentMerkleRoot);

      const blockNumber = await DocumentStoreInstance.getIssuedBlock(documentMerkleRoot);

      // chai can't handle BigInts
      // eslint-disable-next-line chai-expect/no-inner-compare
      expect(BigInt(blockNumber) > 1).to.be.true;
    });

    it("errors on unissued batch", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      // This test may fail on ganache-ui (works for ganache-cli)
      await expect(DocumentStoreInstance.getIssuedBlock(documentMerkleRoot)).to.be.rejectedWith(/revert/);
    });
  });

  describe("isIssued", () => {
    it("should return true for issued batch", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await DocumentStoreInstance.issue(documentMerkleRoot);

      const issued = await DocumentStoreInstance.isIssued(documentMerkleRoot);
      expect(issued, "Document batch is not issued").to.be.true;
    });

    it("should return false for document batch not issued", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      const issued = await DocumentStoreInstance.isIssued(documentMerkleRoot);
      expect(issued, "Document batch is issued in error").to.be.false;
    });
  });

  describe("revoke", () => {
    const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

    it("should allow the revocation of a valid and issued document", async () => {
      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await DocumentStoreInstance.issue(documentMerkleRoot);

      const tx = await DocumentStoreInstance.revoke(documentHash);
      const receipt = await tx.wait();

      // FIXME: Use a utility helper to watch for event
      expect(receipt.events[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.events[0].args.document).to.be.equal(documentHash);
    });

    it("should allow the revocation of an issued root", async () => {
      const documentHash = documentMerkleRoot;

      await DocumentStoreInstance.issue(documentMerkleRoot);

      const tx = await DocumentStoreInstance.revoke(documentHash);
      const receipt = await tx.wait();

      // FIXME: Use a utility helper to watch for event
      expect(receipt.events[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.events[0].args.document).to.be.equal(documentHash);
    });

    it("should not allow repeated revocation of a valid and issued document", async () => {
      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await DocumentStoreInstance.issue(documentMerkleRoot);

      await DocumentStoreInstance.revoke(documentHash);

      await expect(DocumentStoreInstance.revoke(documentHash)).to.be.rejectedWith(/revert/);
    });

    it("should allow revocation of an unissued document", async () => {
      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      const tx = await DocumentStoreInstance.revoke(documentHash);
      const receipt = await tx.wait();

      // FIXME: Use a utility helper to watch for event
      expect(receipt.events[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.events[0].args.document).to.be.equal(documentHash);
    });

    it("should revert when caller has no revoker role", async () => {
      const nonRevokerAccount = Accounts[1];
      const hasNoRevokerRole = await DocumentStoreInstance.hasRole(revokerRole, nonRevokerAccount.address);
      assert.isFalse(hasNoRevokerRole, "Non-Revoker Account has revoker role");

      await expect(DocumentStoreInstance.connect(nonRevokerAccount).revoke(documentMerkleRoot)).to.be.rejectedWith(
        /AccessControl/
      );
    });

    it("should revoke successfully when caller has issuer role", async () => {
      const account = Accounts[0];
      const hasIssuerRole = await DocumentStoreInstance.hasRole(issuerRole, account.address);
      assert.isTrue(hasIssuerRole, "Revoker Account has no revoker role");

      await DocumentStoreInstance.connect(account).revoke(documentMerkleRoot);
      const issued = await DocumentStoreInstance.isRevoked(documentMerkleRoot);

      expect(issued).to.be.true;
    });
  });

  describe("bulkRevoke", () => {
    it("should be able to revoke one document", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      const tx = await DocumentStoreInstance.bulkRevoke(documentMerkleRoots);
      const receipt = await tx.wait();

      // FIXME:
      expect(receipt.events[0].event).to.be.equal("DocumentRevoked", "Document revoked event not emitted.");

      const document1Revoked = await DocumentStoreInstance.isRevoked(documentMerkleRoots[0]);
      expect(document1Revoked, "Document 1 is not revoked").to.be.true;
    });

    it("should be able to revoke multiple documents", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6332",
      ];
      const tx = await DocumentStoreInstance.bulkRevoke(documentMerkleRoots);
      const receipt = await tx.wait();

      // FIXME:
      expect(receipt.events[0].event).to.be.equal("DocumentRevoked", "Document revoked event not emitted.");
      expect(receipt.events[0].args.document).to.be.equal(documentMerkleRoots[0], "Event not emitted for document 1");
      expect(receipt.events[1].args.document).to.be.equal(documentMerkleRoots[1], "Event not emitted for document 2");
      expect(receipt.events[2].args.document).to.be.equal(documentMerkleRoots[2], "Event not emitted for document 3");

      const document1Revoked = await DocumentStoreInstance.isRevoked(documentMerkleRoots[0]);
      expect(document1Revoked, "Document 1 is not revoked").to.be.true;
      const document2Revoked = await DocumentStoreInstance.isRevoked(documentMerkleRoots[1]);
      expect(document2Revoked, "Document 2 is not revoked").to.be.true;
      const document3Revoked = await DocumentStoreInstance.isRevoked(documentMerkleRoots[2]);
      expect(document3Revoked, "Document 3 is not revoked").to.be.true;
    });

    it("should not allow duplicate revokes", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
      ];

      // Check that revoke is rejected
      await expect(DocumentStoreInstance.bulkRevoke(documentMerkleRoots)).to.be.rejectedWith(
        /revert/,
        "Duplicate revoke was not rejected"
      );
    });

    it("should revert when caller has no revoker role", async () => {
      const nonRevokerAccount = Accounts[1];
      const hasNoRevokerRole = await DocumentStoreInstance.hasRole(revokerRole, nonRevokerAccount.address);
      assert.isFalse(hasNoRevokerRole, "Non-Revoker Account has revoker role");

      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];
      await expect(DocumentStoreInstance.connect(nonRevokerAccount).bulkRevoke(documentMerkleRoots)).to.be.rejectedWith(
        /AccessControl/
      );
    });

    it("should bulk revoke successfully when caller has issuer role", async () => {
      const documentMerkleRoots = ["0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"];

      const account = Accounts[0];
      const hasIssuerRole = await DocumentStoreInstance.hasRole(issuerRole, account.address);
      assert.isTrue(hasIssuerRole, "Revoker Account has no revoker role");

      await DocumentStoreInstance.connect(account).bulkRevoke(documentMerkleRoots);
      const issued = await DocumentStoreInstance.isRevoked(documentMerkleRoots[0]);

      expect(issued).to.be.true;
    });
  });

  describe("isRevoked", () => {
    it("returns true for revoked documents", async () => {
      const documentMerkleRoot = "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await DocumentStoreInstance.issue(documentMerkleRoot);
      await DocumentStoreInstance.revoke(documentHash);

      const revoked = await DocumentStoreInstance.isRevoked(documentHash);
      expect(revoked).to.be.true;
    });

    it("returns true for non-revoked documents", async () => {
      "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      const revoked = await DocumentStoreInstance.isRevoked(documentHash);
      expect(revoked).to.be.false;
    });
  });

  describe("isRevokedBefore", () => {
    const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

    it("returns false for document revoked after the block number", async () => {
      const tx = await DocumentStoreInstance.revoke(documentHash);
      const receipt = await tx.wait();
      const revokedBlock = get(receipt, "blockNumber");
      const revoked = await DocumentStoreInstance.isRevokedBefore(documentHash, revokedBlock - 1);
      expect(revoked).to.be.false;
    });

    it("returns true for document revoked at the block number", async () => {
      const tx = await DocumentStoreInstance.revoke(documentHash);
      const receipt = await tx.wait();
      const revokedBlock = get(receipt, "blockNumber");
      const revoked = await DocumentStoreInstance.isRevokedBefore(documentHash, revokedBlock);
      expect(revoked).to.be.true;
    });

    it("returns true for document revoked before the block number", async () => {
      const tx = await DocumentStoreInstance.revoke(documentHash);
      const receipt = await tx.wait();
      const revokedBlock = get(receipt, "blockNumber");
      const revoked = await DocumentStoreInstance.isRevokedBefore(documentHash, revokedBlock + 1);
      expect(revoked).to.be.true;
    });

    it("returns false for document not revoked, for arbitary block number", async () => {
      const revoked = await DocumentStoreInstance.isRevokedBefore(documentHash, 1000);
      expect(revoked).to.be.false;
    });

    it("returns false for document not revoked, for block 0", async () => {
      const revoked = await DocumentStoreInstance.isRevokedBefore(documentHash, 0);
      expect(revoked).to.be.false;
    });
  });

  describe("isIssuedBefore", () => {
    const documentHash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

    it("returns false for document issued after the block number", async () => {
      const tx = await DocumentStoreInstance.issue(documentHash);
      const receipt = await tx.wait();
      const issuedBlock = get(receipt, "blockNumber");
      const issued = await DocumentStoreInstance.isIssuedBefore(documentHash, issuedBlock - 1);
      expect(issued).to.be.false;
    });

    it("returns true for document issued at the block number", async () => {
      const tx = await DocumentStoreInstance.issue(documentHash);
      const receipt = await tx.wait();
      const issuedBlock = get(receipt, "blockNumber");
      const issued = await DocumentStoreInstance.isIssuedBefore(documentHash, issuedBlock);
      expect(issued).to.be.true;
    });

    it("returns true for document issued before the block number", async () => {
      const tx = await DocumentStoreInstance.issue(documentHash);
      const receipt = await tx.wait();
      const issuedBlock = get(receipt, "blockNumber");
      const issued = await DocumentStoreInstance.isIssuedBefore(documentHash, issuedBlock + 1);
      expect(issued).to.be.true;
    });

    it("returns false for document not issued, for arbitary block number", async () => {
      const issued = await DocumentStoreInstance.isIssuedBefore(documentHash, 1000);
      expect(issued).to.be.false;
    });

    it("returns false for document not issued, for block 0", async () => {
      const issued = await DocumentStoreInstance.isIssuedBefore(documentHash, 0);
      expect(issued).to.be.false;
    });
  });
});
