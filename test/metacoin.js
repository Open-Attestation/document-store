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

  it('can issue a certificate', (done) => {
    const certMerkleRoot = '0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330';
    instance.issueCertificate(certMerkleRoot)
    .then(receipt => {
      return instance.certificates.call(0);
    })
    .then(cert => {
      assert.equal(certMerkleRoot, cert, 'Certificate is not issued');
      done();
    });
  });

  it('can retrieve a certificate index', (done) => {
    const certMerkleRoot = '0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6330';
    instance.certificateIndex(certMerkleRoot)
    .then(index => {
      assert.equal(index, 0);
      done();
    })
  });

  it('can proof a valid claim', (done) => {
    const hash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
    const proof = [
      "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
      "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
      "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
      "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe54330",
      "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
    ];

    instance.checkProof(0, hash, proof)
    .then(valid => {
      assert.equal(valid, true);
      done();
    })
  });

  it('can proof an invalid claim', (done) => {
    const hash = "0x10327d7f904ee3ee0e69d592937be37a33692a78550bd100d635cdea2344e6c7";
    const proof = [
      "0x04d147f4920441b9f92da6a1bf0dc5331663b6d823eea8316a3ac8c97206bec9",
      "0xcd9b445f1db7f12b66a272c35848fea1a4e74b77cd8fbe98c55326dcfa92d748",
      "0x92928abcc6add620b8c513027ab880213977d216ae3a35c3519849bab3276660",
      "0xafd499678500bf4be85d0ad9270988027a9c7ebc13679b4cce2d9b230fe53330",
      "0xf85f3f3f370cf06bbf27dfec0999c038f04f4003687f7b165992b0bb03f3510b"
    ];

    instance.checkProof(0, hash, proof)
    .then(valid => {
      assert.equal(valid, false);
      done();
    })
  });
});
