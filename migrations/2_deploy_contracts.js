const Merkle = artifacts.require("./Merkle.sol");
const CertificateStore = artifacts.require("./CertificateStore.sol");

module.exports = function(deployer) {
  deployer.deploy(Merkle);
  deployer.link(Merkle, CertificateStore);
  deployer.deploy(CertificateStore, "www.tech.gov.sg", "Government Technology Agency of Singapore (GovTech)");
};
