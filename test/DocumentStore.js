const DocumentStore = artifacts.require("./DocumentStore.sol");
DocumentStore.numberFormat = "String";
const {get} = require("lodash");

const {expect} = require("chai").use(require("chai-as-promised"));
const config = require("../config.js");
const {version: versionFromPackageJson} = require("../package.json");

contract("DocumentStore", accounts => {
  let instance = null;

  // Related: https://github.com/trufflesuite/truffle-core/pull/98#issuecomment-360619561
  beforeEach(async () => {
    instance = await DocumentStore.new(config.INSTITUTE_NAME);
  });

  const issue = documentMerkleRoot => instance.issue(documentMerkleRoot);

  describe("constructor", () => {
    it("should have correct name", async () => {
      const name = await instance.name();
      expect(name).to.be.equal(
        config.INSTITUTE_NAME,
        "Name of institute does not match"
      );
    });

    it("sets the owner properly", async () => {
      const owner = await instance.owner();
      expect(owner).to.be.equal(accounts[0]);
    });
  });

  describe("version", () => {
    it("should have a version field value that is the same as in package.json", async () => {
      const versionFromSolidity = await instance.version();
      expect(versionFromSolidity).to.be.equal(versionFromPackageJson);
    });
  });

  describe("issue", () => {
    it("should be able to issue a document", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const receipt = await issue(documentMerkleRoot);

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal(
        "DocumentIssued",
        "Document issued event not emitted."
      );
      expect(receipt.logs[0].args.document).to.be.equal(
        documentMerkleRoot,
        "Incorrect event arguments emitted"
      );

      const issued = await instance.isIssued(documentMerkleRoot);
      expect(issued, "Document is not issued").to.be.true;
    });

    it("should not allow duplicate issues", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await issue(documentMerkleRoot);

      // Check that reissue is rejected
      await expect(instance.issue(documentMerkleRoot)).to.be.rejectedWith(
        /revert/,
        "Duplicate issue was not rejected"
      );
    });

    it("only allows the owner to issue", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      await expect(
        instance.issue(documentMerkleRoot, {from: nonOwner})
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("bulkIssue", () => {
    it("should be able to issue one document", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"
      ];
      const receipt = await instance.bulkIssue(documentMerkleRoots);

      expect(receipt.logs[0].event).to.be.equal(
        "DocumentIssued",
        "Document issued event not emitted."
      );

      const document1Issued = await instance.isIssued(documentMerkleRoots[0]);
      expect(document1Issued, "Document 1 is not issued").to.be.true;
    });

    it("should be able to issue multiple documents", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6332"
      ];
      const receipt = await instance.bulkIssue(documentMerkleRoots);

      expect(receipt.logs[0].event).to.be.equal(
        "DocumentIssued",
        "Document issued event not emitted."
      );
      expect(receipt.logs[0].args.document).to.be.equal(
        documentMerkleRoots[0],
        "Event not emitted for document 1"
      );
      expect(receipt.logs[1].args.document).to.be.equal(
        documentMerkleRoots[1],
        "Event not emitted for document 2"
      );
      expect(receipt.logs[2].args.document).to.be.equal(
        documentMerkleRoots[2],
        "Event not emitted for document 3"
      );

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

      // Check that reissue is rejected
      await expect(instance.bulkIssue(documentMerkleRoots)).to.be.rejectedWith(
        /revert/,
        "Duplicate issue was not rejected"
      );
    });

    it("only allows the owner to issue", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"
      ];

      await expect(
        instance.bulkIssue(documentMerkleRoots, {from: nonOwner})
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("getIssuedBlock", () => {
    it("returns the block number of issued batches", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await issue(documentMerkleRoot);

      const blockNumber = await instance.getIssuedBlock(documentMerkleRoot);

      // chai can't handle BigInts
      // eslint-disable-next-line chai-expect/no-inner-compare
      expect(BigInt(blockNumber) > 1).to.be.true;
    });

    it("errors on unissued batch", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      // This test may fail on ganache-ui (works for ganache-cli)
      await expect(
        instance.getIssuedBlock(documentMerkleRoot)
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("isIssued", () => {
    it("should return true for issued batch", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await issue(documentMerkleRoot);

      const issued = await instance.isIssued(documentMerkleRoot);
      expect(issued, "Document batch is not issued").to.be.true;
    });

    it("should return false for document batch not issued", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      const issued = await instance.isIssued(documentMerkleRoot);
      expect(issued, "Document batch is issued in error").to.be.false;
    });
  });

  describe("revoke", () => {
    it("should allow the revocation of a valid and issued document", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const documentHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await issue(documentMerkleRoot);

      const receipt = await instance.revoke(documentHash);

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.logs[0].args.document).to.be.equal(documentHash);
    });

    it("should allow the revocation of an issued root", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const documentHash = documentMerkleRoot;

      await issue(documentMerkleRoot);

      const receipt = await instance.revoke(documentHash);

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.logs[0].args.document).to.be.equal(documentHash);
    });

    it("should not allow repeated revocation of a valid and issued document", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const documentHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await issue(documentMerkleRoot);

      await instance.revoke(documentHash);

      await expect(instance.revoke(documentHash)).to.be.rejectedWith(/revert/);
    });

    it("should allow revocation of an unissued document", async () => {
      const documentHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      const receipt = await instance.revoke(documentHash);

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("DocumentRevoked");
      expect(receipt.logs[0].args.document).to.be.equal(documentHash);
    });
  });

  describe("bulkRevoke", () => {
    it("should be able to revoke one document", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"
      ];
      const receipt = await instance.bulkRevoke(documentMerkleRoots);

      expect(receipt.logs[0].event).to.be.equal(
        "DocumentRevoked",
        "Document revoked event not emitted."
      );

      const document1Revoked = await instance.isRevoked(documentMerkleRoots[0]);
      expect(document1Revoked, "Document 1 is not revoked").to.be.true;
    });

    it("should be able to revoke multiple documents", async () => {
      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331",
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6332"
      ];
      const receipt = await instance.bulkRevoke(documentMerkleRoots);

      expect(receipt.logs[0].event).to.be.equal(
        "DocumentRevoked",
        "Document revoked event not emitted."
      );
      expect(receipt.logs[0].args.document).to.be.equal(
        documentMerkleRoots[0],
        "Event not emitted for document 1"
      );
      expect(receipt.logs[1].args.document).to.be.equal(
        documentMerkleRoots[1],
        "Event not emitted for document 2"
      );
      expect(receipt.logs[2].args.document).to.be.equal(
        documentMerkleRoots[2],
        "Event not emitted for document 3"
      );

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

      // Check that rerevoke is rejected
      await expect(instance.bulkRevoke(documentMerkleRoots)).to.be.rejectedWith(
        /revert/,
        "Duplicate revoke was not rejected"
      );
    });

    it("only allows the owner to revoke", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const documentMerkleRoots = [
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330"
      ];

      await expect(
        instance.bulkRevoke(documentMerkleRoots, {from: nonOwner})
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("isRevoked", () => {
    it("returns true for revoked documents", async () => {
      const documentMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const documentHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await issue(documentMerkleRoot);
      await instance.revoke(documentHash);

      const revoked = await instance.isRevoked(documentHash);
      expect(revoked).to.be.true;
    });

    it("returns true for non-revoked documents", async () => {
      "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      const documentHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      const revoked = await instance.isRevoked(documentHash);
      expect(revoked).to.be.false;
    });
  });

  describe("isRevokedBefore", () => {
    const documentHash =
      "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

    it("returns false for document revoked after the block number", async () => {
      const revokeReceipt = await instance.revoke(documentHash);
      const revokedBlock = get(revokeReceipt, "receipt.blockNumber");
      const revoked = await instance.isRevokedBefore(
        documentHash,
        revokedBlock - 1
      );
      expect(revoked).to.be.false;
    });

    it("returns true for document revoked at the block number", async () => {
      const revokeReceipt = await instance.revoke(documentHash);
      const revokedBlock = get(revokeReceipt, "receipt.blockNumber");
      const revoked = await instance.isRevokedBefore(
        documentHash,
        revokedBlock
      );
      expect(revoked).to.be.true;
    });

    it("returns true for document revoked before the block number", async () => {
      const revokeReceipt = await instance.revoke(documentHash);
      const revokedBlock = get(revokeReceipt, "receipt.blockNumber");
      const revoked = await instance.isRevokedBefore(
        documentHash,
        revokedBlock + 1
      );
      expect(revoked).to.be.true;
    });

    it("returns false for document not revoked, for arbitary block number", async () => {
      const revoked = await instance.isRevokedBefore(documentHash, 1000);
      expect(revoked).to.be.false;
    });

    it("returns false for document not revoked, for block 0", async () => {
      const revoked = await instance.isRevokedBefore(documentHash, 0);
      expect(revoked).to.be.false;
    });
  });

  describe("isIssuedBefore", () => {
    const documentHash =
      "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

    it("returns false for document issued after the block number", async () => {
      const issueReceipt = await instance.issue(documentHash);
      const issuedBlock = get(issueReceipt, "receipt.blockNumber");
      const issued = await instance.isIssuedBefore(
        documentHash,
        issuedBlock - 1
      );
      expect(issued).to.be.false;
    });

    it("returns true for document issued at the block number", async () => {
      const issueReceipt = await instance.issue(documentHash);
      const issuedBlock = get(issueReceipt, "receipt.blockNumber");
      const issued = await instance.isIssuedBefore(documentHash, issuedBlock);
      expect(issued).to.be.true;
    });

    it("returns true for document issued before the block number", async () => {
      const issueReceipt = await instance.issue(documentHash);
      const issuedBlock = get(issueReceipt, "receipt.blockNumber");
      const issued = await instance.isIssuedBefore(
        documentHash,
        issuedBlock + 1
      );
      expect(issued).to.be.true;
    });

    it("returns false for document not issued, for arbitary block number", async () => {
      const issued = await instance.isIssuedBefore(documentHash, 1000);
      expect(issued).to.be.false;
    });

    it("returns false for document not issued, for block 0", async () => {
      const issued = await instance.isIssuedBefore(documentHash, 0);
      expect(issued).to.be.false;
    });
  });
});
