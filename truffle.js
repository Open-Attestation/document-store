const HDWalletProvider = require("truffle-hdwallet-provider-privkey");
const privateKeys = [
  "22D451659A9749E2233BF1E7E0ADD8AA93D97141CAC9AC2B871F49DF434FED1E"
];
module.exports = {
  solc: {
    optimizer: {
      enabled: true,
      runs: 1000000
    }
  },
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 4712388,
      network_id: "*" // Match any network id
    },
    ropsten: {
      network_id: 3,
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          "https://ropsten.infura.io/v3/1f1ff2b3fca04f8d99f67d465c59e4ef"
        )
    }
  }
};
