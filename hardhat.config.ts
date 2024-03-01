/* eslint-disable import/no-extraneous-dependencies */

import "@nomicfoundation/hardhat-toolbox";
import type { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.23"
  },
  paths: {
    sources: "./src"
  }
};

export default config;
