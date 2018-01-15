const MerkleProof = artifacts.require("zeppelin-solidity/contracts/MerkleProof.sol");
const CertificateStore = artifacts.require("./CertificateStore.sol");

module.exports = function(deployer) {
  deployer.deploy(MerkleProof);
  deployer.link(MerkleProof, CertificateStore);
  deployer.deploy(CertificateStore, "www.tech.gov.sg", "Government Technology Agency of Singapore (GovTech)");
};
