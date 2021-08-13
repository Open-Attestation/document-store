require("@nomiclabs/hardhat-waffle");
require("hardhat-typechain");
require("@openzeppelin/hardhat-upgrades");

const apiKey = "";
const privateKey1 = "";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "src/contracts",
  },
  networks: {
    ropsten: {
      url: `https://ropsten.infura.io/v3/${apiKey}`,
      accounts: [privateKey1],
    },
  },
};
