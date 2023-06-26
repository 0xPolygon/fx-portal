import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "solidity-coverage";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";

import { HardhatUserConfig } from "hardhat/types";

let accounts: any = [];

if (process.env.PRIVATE_KEY) {
  accounts = [`0x${process.env.PRIVATE_KEY}`, ...accounts];
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // accounts: [secret],
      allowUnlimitedContractSize: true,
      gas: 120000000000000,
      blockGasLimit: 0x1fffffffffffff,
    },
    mainnet: {
      url: process.env.MAINNET_RPC || "https://main-light.eth.linkpool.io",
      accounts,
    },
    goerli: {
      url: process.env.GOERLI_RPC || "https://goerli-light.eth.linkpool.io",
      accounts,
    },
    polygon: {
      url: process.env.POLYGON_RPC || "https://polygon-rpc.com",
      accounts,
    },
    mumbai: {
      url: process.env.MUMBAI_RPC || "https://rpc-mumbai.maticvigil.com",
      accounts,
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  paths: {
    tests: "hardhat",
  },
  typechain: {
    outDir: "types/",
    target: "ethers-v5",
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 5,
  },
  namedAccounts: {
    deployer: 0,
  },
} as HardhatUserConfig;
