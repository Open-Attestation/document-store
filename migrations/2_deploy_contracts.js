const CertificateStore = artifacts.require("./CertificateStore.sol");

module.exports = deployer => {
  deployer.deploy(
    CertificateStore,
    "www.tech.gov.sg",
    "Government Technology Agency of Singapore (GovTech)"
  );
};
