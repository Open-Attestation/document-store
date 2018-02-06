const CertificateStore = artifacts.require("./CertificateStore.sol");
const config = require("../config.js");
const BigNumber = require("bignumber.js");

// FIXME: Remove assert usage
const { expect } = require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bignumber")(BigNumber));

contract("CertificateStore", accounts => {
  let instance = null;

  // Related: https://github.com/trufflesuite/truffle-core/pull/98#issuecomment-360619561
  beforeEach(async () => {
    instance = await CertificateStore.new(
      config.VERIFICATION_URL,
      config.INSTITUTE_NAME
    );
  });

  const issueBatch = batchMerkleRoot => instance.issueBatch(batchMerkleRoot);

  describe("constructor", () => {
    it("should have correct name", async () => {
      const name = await instance.name();
      expect(name).to.be.equal(
        config.INSTITUTE_NAME,
        "Name of institute does not match"
      );
    });

    it("should have correct verification url", async () => {
      const url = await instance.verificationUrl();
      expect(url).to.be.equal(
        config.VERIFICATION_URL,
        "Verification url of institute does not match"
      );
    });

    it("sets the owner properly", async () => {
      const owner = await instance.owner();
      expect(owner).to.be.equal(accounts[0]);
    });
  });

  describe("issueBatch", () => {
    it("should be able to issue a certificate batch", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const receipt = await issueBatch(batchMerkleRoot);

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal(
        "BatchIssued",
        "Batch issued event not emitted."
      );
      expect(receipt.logs[0].args.batchRoot).to.be.equal(
        batchMerkleRoot,
        "Incorrect event arguments emitted"
      );

      const issued = await instance.isBatchIssued(batchMerkleRoot);
      expect(issued, "Certificate batch is not issued").to.be.true;
    });

    it("should not allow duplicate issues", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await issueBatch(batchMerkleRoot);

      // Check that reissue is rejected
      expect(instance.issueBatch(batchMerkleRoot)).to.be.rejectedWith(
        /revert/,
        "Duplicate issue was not rejected"
      );
    });

    it("only allows the owner to issue", async () => {
      const nonOwner = accounts[1];
      const owner = await instance.owner();
      expect(nonOwner).to.not.be.equal(owner);

      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      expect(
        instance.issueBatch(batchMerkleRoot, { from: nonOwner })
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("getIssuedBlock", () => {
    it("returns the block number of issued batches", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await issueBatch(batchMerkleRoot);

      const blockNumber = await instance.getIssuedBlock(batchMerkleRoot);
      expect(blockNumber).to.be.bignumber.greaterThan(0);
    });

    it("errors on unissued batch", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      expect(instance.getIssuedBlock(batchMerkleRoot)).to.be.rejectedWith(
        /revert/
      );
    });
  });

  describe("isBatchIssued", () => {
    it("should return true for issued batch", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      await issueBatch(batchMerkleRoot);

      const issued = await instance.isBatchIssued(batchMerkleRoot);
      expect(issued, "Certificate batch is not issued").to.be.true;
    });

    it("should return false for certificate batch not issued", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      const issued = await instance.isBatchIssued(batchMerkleRoot);
      expect(issued, "Certificate batch is issued in error").to.be.false;
    });
  });

  describe("revokeClaim", () => {
    it("should allow the revocation of a valid and issued claim (leaf)", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await issueBatch(batchMerkleRoot);

      const receipt = await instance.revokeClaim(
        batchMerkleRoot,
        certificateHash,
        1337
      );

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("ClaimRevoked");
      expect(receipt.logs[0].args.claim).to.be.equal(certificateHash);
      expect(receipt.logs[0].args.batchRoot).to.be.equal(batchMerkleRoot);
      expect(receipt.logs[0].args.revocationReason).bignumber.to.be.equal(1337);
    });

    it("should allow the revocation of an issued root", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash = batchMerkleRoot;

      await issueBatch(batchMerkleRoot);

      const receipt = await instance.revokeClaim(
        batchMerkleRoot,
        certificateHash,
        1337
      );

      // FIXME: Use a utility helper to watch for event
      expect(receipt.logs[0].event).to.be.equal("ClaimRevoked");
      expect(receipt.logs[0].args.claim).to.be.equal(certificateHash);
      expect(receipt.logs[0].args.batchRoot).to.be.equal(batchMerkleRoot);
      expect(receipt.logs[0].args.revocationReason).bignumber.to.be.equal(1337);
    });

    it("should not allow repeated revocation of a valid and issued claim", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await issueBatch(batchMerkleRoot);

      await instance.revokeClaim(batchMerkleRoot, certificateHash, 1337);

      expect(
        instance.revokeClaim(batchMerkleRoot, certificateHash, 1337)
      ).to.be.rejectedWith(/revert/);
    });

    it("should not allow revocation of an unissued claim", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      expect(
        instance.revokeClaim(batchMerkleRoot, certificateHash, 1337)
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("isRevoked", () => {
    it("returns true for revoked claims", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      await issueBatch(batchMerkleRoot);
      await instance.revokeClaim(batchMerkleRoot, certificateHash, 1337);

      const revoked = await instance.isRevoked(certificateHash);
      expect(revoked).to.be.true;
    });

    it("returns true for non-revoked claims", async () => {
      "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";

      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";

      const revoked = await instance.isRevoked(certificateHash);
      expect(revoked).to.be.false;
    });
  });
});
