const CertificateStore = artifacts.require("./CertificateStore.sol");
const config = require('../config.js');

contract('CertificateStore', function(accounts) {
  let instance = null;

  before((done) => {
    CertificateStore.deployed().then(deployed => {
      instance = deployed;
      done();
    });
  })

  it('should have correct name', (done) => {
    instance.name.call()
    .then(name => {
      assert.equal(name, config.INSTITUTE_NAME, 'Name of institute does not match');
      done();
    });
  });

  it('should have correct verification url', (done) => {
    instance.verificationUrl.call()
    .then(url => {
      assert.equal(url, config.VERIFICATION_URL, 'Verification url of institute does not match');
      done();
    });
  });

  it('should be able to issue a certificate and check that it is issued', (done) => {
    const certMerkleRoot = '0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330';
    instance.issueCertificate(certMerkleRoot)
    .then(receipt => {
      return instance.isIssued.call(certMerkleRoot);
    })
    .then(issued => {
      assert.equal(issued, true, 'Certificate is not issued');
      done();
    });
  });

  it('should return false for certificate not issued', (done) => {
    const certMerkleRoot = '0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6331';
    instance.isIssued.call(certMerkleRoot)
    .then(issued => {
      assert.equal(issued, false, 'Certificate is issued in error');
      done();
    });
  });

  it('should return true for issued certificate with valid claim', (done) => {
    const certificateRoot = '0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330';
    const hash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
    const proof = 
      "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9"
      + "cd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748"
      + "92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660"
      + "afd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330"
      + "f85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
    ;

    instance.checkProof(certificateRoot, hash, proof)
    .then(valid => {
      assert.equal(valid, true);
      done();
    })
  });

  it('should return false for unissued certificate with valid claim', (done) => {
    const certificateRoot = '0x458a80232eda8a816972be8ac731feb50727149aff6287d70142821ae160caf7';
    const hash = "0xe7919f28927ec109fc76e6c23b9d765636dc5c394330defc1da4ceef3d092802";
    const proof = 
      "0xde85e4611e82b19345a9b8c97fd9956df8c21b6c2111b29ab5b79ee4e72db2b5"
      + "316f8b7894f51f48add5929ff6b05ee141de763ca4f579799c6c2bf46e190ed1"
      + "61dad5f5e72ab727a4c2f150e6a3eec8dba8693626e8a71285f78a797c79f682"
      + "c31d781d0dafd0498177b173dda215f599a12cee58b33ff548f04c46c3106cf1"
      + "58a3f9b304ead7f11b202760a327cc7d81d233a0535207cbcde43684765255b6"
      + "a4571199578e394188ea9f40f22cb3f63b2c3bcdf225e6f7389f8b0e6c926253"
    ;

    instance.checkProof(certificateRoot, hash, proof)
    .then(valid => {
      assert.equal(valid, false);
      done();
    })
  });

  it('should return false for proof with invalid claim', (done) => {
    const certificateRoot = '0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330';
    const hash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
    const proof = 
      "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9"
      + "cd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748"
      + "92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660"
      + "afd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330"
      + "f85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510"
    ;

    instance.checkProof(certificateRoot, hash, proof)
    .then(valid => {
      assert.equal(valid, false);
      done();
    })
  });
});
