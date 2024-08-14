require("@nomicfoundation/hardhat-verify");
require("dotenv").config({ path: `.${process.env.NODE_ENV}.env` });
require("@nomicfoundation/hardhat-chai-matchers");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("@nomiclabs/hardhat-solhint");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20", // Default compiler version
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.5.16", // Compiler version for specific contracts
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      // Add more compiler versions for other contracts if needed
    ],
  },

  networks: {
    mainnet: {
      url: "https://rpc.pulsechain.com",
      accounts: [process.env.PRIVATE_KEY],
    },
    testnet: {
      url: "https://rpc.v4.testnet.pulsechain.com",
      accounts: [process.env.PRIVATE_KEY],
    },
    hardhat: {
      accounts: {
        mnemonic: "test test test test test test test test test test test test",
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 20,
      }
    },
  },

  etherscan: {
    apiKey: {
      pulsechain: "pulsechain",
      testnetv4: "testnetv4",
    },
    customChains: [
      {
        network: "pulsechain",
        chainId: 369,
        urls: {
          apiURL: "https://api.scan.pulsechain.com/api/",
          browserURL: "https://api.scan.pulsechain.com/api/",
        },
      },
      {
        network: "testnetv4",
        chainId: 943,
        urls: {
          apiURL: "https://api.scan.v4.testnet.pulsechain.com/api/",
          browserURL: "https://api.scan.v4.testnet.pulsechain.com/api/",
        },
      },
    ],
  },

  sourcify: {
    enabled: true
  },

  gasReporter: {
    currency: "USD",
  },
};
