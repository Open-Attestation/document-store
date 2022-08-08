/* eslint-disable import/no-extraneous-dependencies */

require("@nomiclabs/hardhat-waffle");
require("hardhat-typechain");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: {
    version: "0.8.2",
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
};
