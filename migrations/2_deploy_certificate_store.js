const DocumentStore = artifacts.require("./DocumentStore.sol");

module.exports = deployer => {
  deployer.deploy(
    DocumentStore,
    "Government Technology Agency of Singapore (GovTech)"
  );
};
