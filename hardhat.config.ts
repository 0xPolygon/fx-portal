import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "solidity-coverage";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";

import { HardhatUserConfig } from "hardhat/types";
import { task } from "hardhat/config";

// import * as dotenv from 'dotenv';

// dotenv.config();

// const secret: string = process.env.PRIVATE_KEY as string;
// const infraKey = process.env.INFURA_API_KEY
// const etherscanKey: string = process.env.ETHERSCAN_API_KEY as string;

let accounts: any = []

if (process.env.PRIVATE_KEY) {
  accounts = [`0x${process.env.PRIVATE_KEY}`, ...accounts]
}

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // accounts: [secret],
    },
    mainnet: {
      url: process.env.MAINNET_RPC || 'https://main-light.eth.linkpool.io',
      accounts
    },
    goerli: {
      url: process.env.GOERLI_RPC || 'https://goerli-light.eth.linkpool.io',
      accounts
    },
    polygon: {
      url: process.env.POLYGON_RPC || 'https://polygon-rpc.com',
      accounts
    },
    mumbai: {
      url: process.env.MUMBAI_RPC || 'https://rpc-mumbai.maticvigil.com',
      accounts
    }
  },
  solidity: {
    version: '0.8.0',
    settings: {
      optimizer: {
        enabled: true,
        runs: 9999
      }
    }
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
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 5,
  },
  namedAccounts: {
    deployer: 0,
  },
} as HardhatUserConfig;
