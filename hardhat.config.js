require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0"
      }
    ]
  }
};

if(process.env.PRIVATE_KEY) {
  module.exports.networks = {
    goerli: {
      url: process.env.GOERLI_RPC || "https://rpc.slock.it/goerli",
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    mumbai: {
      url: process.env.MUMBAI_RPC || "https://rpc-mumbai.maticvigil.com",
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  };
}

if(process.env.ETHERSCAN_APIKEY) {
  module.exports.etherscan = {
    apiKey: process.env.ETHERSCAN_APIKEY
  }
}
