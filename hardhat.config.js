/* eslint-disable import/no-extraneous-dependencies */

require("@nomicfoundation/hardhat-toolbox");
require("@typechain/hardhat");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./src"
  },
  typechain: {
    outDir: "types",
    dontOverrideCompile: false
  }
};
