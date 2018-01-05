const Merkle = artifacts.require("./Merkle.sol");

module.exports = function(deployer) {
  deployer.deploy(Merkle);
};
