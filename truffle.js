const HDWalletProvider = require("truffle-hdwallet-provider");
require("dotenv").config();

const ropstenPrivateKey = process.env.ROPSTEN_KEY;
module.exports = {
  compilers: {
    solc: {
      version: "0.5.10",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 6721975,
      network_id: "*" // Match any network id
    },
    docker: {
      host: "ganache",
      port: 8545,
      gas: 6721975,
      network_id: "*" // Match any network id
    },
    ropsten: {
      network_id: 3,
      skipDryRun: true,
      provider: () =>
        new HDWalletProvider(
          ropstenPrivateKey,
          `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`
        )
    }
  }
};
