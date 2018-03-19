const CertificateStore = artifacts.require("./CertificateStore.sol");

module.exports = deployer => {
  deployer.deploy(
    CertificateStore,
    "Government Technology Agency of Singapore (GovTech)"
  );
};
