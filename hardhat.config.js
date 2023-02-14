require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

let accounts = [];

if (process.env.ACCOUNT_KEY_PRIV_MAINNET) {
  accounts = [`0x${process.env.ACCOUNT_KEY_PRIV_MAINNET}`, ...accounts];
}

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 9999,
      },
    },
  },
  networks: {
    mainnet: {
      url: `${process.env.NETWORK_MAINNET}`,
      accounts: [`0x${process.env.ACCOUNT_KEY_PRIV_MAINNET}`],
    },
    goerli: {
      url: `${process.env.NETWORK_GOERLI}`,
      accounts: [`0x${process.env.ACCOUNT_KEY_PRIV_GOERLI}`],
    },
    polygon: {
      url: `${process.env.NETWORK_POLYGON}`,
      accounts: [`0x${process.env.ACCOUNT_KEY_PRIV_POLYGON}`],
    },
    mumbai: {
      url: `${process.env.NETWORK_POLYGON_MUMBAI}`,
      accounts: [`0x${process.env.ACCOUNT_KEY_PRIV_MUMBAI}`],
    },
  },
  etherscan: {
    apiKey: {
      //ethereum
      mainnet: `${process.env.ETHERSCAN}`,
      ropsten: `${process.env.ETHERSCAN}`,
      rinkeby: `${process.env.ETHERSCAN}`,
      goerli: `${process.env.ETHERSCAN}`,
      kovan: `${process.env.ETHERSCAN}`,

      //polygon
      polygon: `${process.env.POLYGONSCAN}`,
      polygonMumbai: `${process.env.POLYGONSCAN}`,
    },
  },
};
