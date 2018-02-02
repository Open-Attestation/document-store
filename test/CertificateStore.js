const CertificateStore = artifacts.require("./CertificateStore.sol");
const config = require("../config.js");
const web3 = require("web3");
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
      expect(
        receipt.logs[0].args.batchRoot).to.be.equal(
        batchMerkleRoot,
        "Incorrect event arguments emitted"
      );

      const issued = await instance.isBatchIssued(batchMerkleRoot);
      expect(issued, true, "Certificate batch is not issued");
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
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);

      const receipt = await instance.revokeClaim(
        batchMerkleRoot,
        certificateHash,
        proof,
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
      const proof = [];

      await issueBatch(batchMerkleRoot);

      const receipt = await instance.revokeClaim(
        batchMerkleRoot,
        certificateHash,
        proof,
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
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);

      await instance.revokeClaim(batchMerkleRoot, certificateHash, proof, 1337);

      expect(
        instance.revokeClaim(batchMerkleRoot, certificateHash, proof, 1337)
      ).to.be.rejectedWith(/revert/);
    });

    it("should not allow revocation of an invalid claim", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      // First proof is wrong
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec0",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);

      expect(
        instance.revokeClaim(batchMerkleRoot, certificateHash, proof, 1337)
      ).to.be.rejectedWith(/revert/);
    });

    it("should not allow revocation of an unissued claim", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      expect(
        instance.revokeClaim(batchMerkleRoot, certificateHash, proof, 1337)
      ).to.be.rejectedWith(/revert/);
    });
  });

  describe("isRevoked", () => {
    it("returns true for revoked claims", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);
      await instance.revokeClaim(batchMerkleRoot, certificateHash, proof, 1337);

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

  describe("verifyClaim", () => {
    it("should return true for issued certificate with valid claim", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const certificateHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];
      await issueBatch(batchMerkleRoot);

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        certificateHash,
        proof
      );
      expect(valid, true);
    });

    it("should return false for unissued certificate with valid claim", async () => {
      const batchMerkleRoot =
        "0x458a80232eda8a816972be8ac731feb50727149aff6287d70142821ae160caf7";
      const certificateHash =
        "0xe7919f28927ec109fc76e6c23b9d765636dc5c394330defc1da4ceef3d092802";
      const proof = [
        "0xde85e4611e82b19345a9b8c97fd9956df8c21b6c2111b29ab5b79ee4e72db2b5",
        "0x316f8b7894f51f48add5929ff6b05ee141de763ca4f579799c6c2bf46e190ed1",
        "0x61dad5f5e72ab727a4c2f150e6a3eec8dba8693626e8a71285f78a797c79f682",
        "0xc31d781d0dafd0498177b173dda215f599a12cee58b33ff548f04c46c3106cf1",
        "0x58a3f9b304ead7f11b202760a327cc7d81d233a0535207cbcde43684765255b6",
        "0xa4571199578e394188ea9f40f22cb3f63b2c3bcdf225e6f7389f8b0e6c926253"
      ];

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        certificateHash,
        proof
      );
      expect(valid, false);
    });

    it("should return false for proof with invalid claim", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const claimHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510"
      ];
      await issueBatch(batchMerkleRoot);

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        claimHash,
        proof
      );
      expect(valid, false);
    });

    it("should return false for revoked leaf", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const claimHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);

      await instance.revokeClaim(batchMerkleRoot, claimHash, proof, 1337);

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        claimHash,
        proof
      );

      expect(valid).to.be.false;
    });

    it("should return false for revoked root", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const claimHash = batchMerkleRoot;
      const proof = [];

      await issueBatch(batchMerkleRoot);

      // Revoke the root
      await instance.revokeClaim(batchMerkleRoot, claimHash, proof, 1337);

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        claimHash,
        proof
      );
      expect(valid).to.be.false;
    });

    it("should return false for revoked proof", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const claimHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);

      // We revoke proof[0]
      await instance.revokeClaim(
        batchMerkleRoot,
        proof[0],
        [claimHash, ...proof.slice(1)],
        1337
      );

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        claimHash,
        proof
      );
      expect(valid).to.be.false;
    });

    it("should return false for revoked computed hash", async () => {
      const batchMerkleRoot =
        "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330";
      const claimHash =
        "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
      const proof = [
        "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
        "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
        "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
        "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
        "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
      ];

      await issueBatch(batchMerkleRoot);

      // We want to revoke the combined hash of claimHash and proof[0]
      // Value should be
      // 0xaf6e73229ae8dcb4d2313d7e6c9e0802481e0c65fd2e1d525dd74be6c64256ce
      const combinedHash = web3.utils.sha3([
        ...web3.utils.hexToBytes(proof[0]),
        ...web3.utils.hexToBytes(claimHash)
      ]);

      await instance.revokeClaim(
        batchMerkleRoot,
        combinedHash,
        proof.slice(1),
        1337
      );

      const valid = await instance.verifyClaim(
        batchMerkleRoot,
        claimHash,
        proof
      );
      expect(valid).to.be.false;
    });
  });
});
