const DocumentStore = artifacts.require("./DocumentStore.sol");

module.exports = deployer => {
  return deployer
    .then(() => {
      return DocumentStore.new(
        "Government Technology Agency of Singapore (GovTech)"
      );
    })
    .then(console.log);
};
