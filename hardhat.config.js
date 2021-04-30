require("@nomiclabs/hardhat-waffle");
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
        version: "0.7.3"
      }
    ]
  }
};

const PRIVATE_KEY=process.env.PRIVATE_KEY;
const RPC_APIKEY=process.env.RPC_APIKEY;

if(PRIVATE_KEY !== undefined && RPC_APIKEY !== undefined) {
  module.exports.networks = {
    goerli: {
        url: `https://rpc.slock.it/goerli`,
        accounts: [`0x${PRIVATE_KEY}`]
    },
    mumbai: {
      url: `https://rpc-mumbai.maticvigil.com/v1/${RPC_APIKEY}`,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  };
}
