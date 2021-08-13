require("@nomiclabs/hardhat-waffle");
require("hardhat-typechain");
require("@openzeppelin/hardhat-upgrades");

var apiKey = "19339f594ee645d0b8183741df1a2c4d";
var privateKey1 = "0x416f14debf10172f04bef09f9b774480561ee3f05ee1a6f75df3c71ec0c60666";

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
