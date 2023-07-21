import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "solidity-coverage";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";

import { HardhatUserConfig } from "hardhat/types";
import { task } from "hardhat/config";

const importToml = require("import-toml");
const foundryConfig = importToml.sync("foundry.toml");

const accounts = process.env.PRIVATE_KEY
  ? [`0x${process.env.PRIVATE_KEY}`]
  : [];

task("exit-proof", "Generates exit proof for the given burn transaction hash")
  .addParam("tx", "burn transaction hash")
  .addOptionalParam(
    "sig",
    "log event hex signature (defaults to 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036 for `MessageSent(bytes)`)"
  )
  .setAction(async (args, hre) => {
    const { buildPayloadForExit } = require("./hardhat/tunnel/payload/payload");
    console.log(
      (await buildPayloadForExit(args.tx, hre.ethers.provider, args.sig))
        .burnProof
    );
  });

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
    version: foundryConfig.profile.default.solc_version,
    settings: {
      viaIR: foundryConfig.profile.default.via_ir,
      optimizer: {
        enabled: true,
        runs: foundryConfig.profile.default.optimizer_runs,
      },
      metadata: {
        bytecodeHash: "none",
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
