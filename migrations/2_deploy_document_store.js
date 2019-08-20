const DocumentStore = artifacts.require("./DocumentStore.sol");
const {INSTITUTE_NAME} = require("../config");

module.exports = deployer => {
  deployer.deploy(DocumentStore, INSTITUTE_NAME);
};
