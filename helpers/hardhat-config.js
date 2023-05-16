const networkConfig = {
  localhost: {},
  hardhat: {},
  // Price Feed Address, values can be obtained at https://docs.chain.link/docs/reference-contracts
  goerli: {
    blockConfirmations: 3,
  },
  mainnet: {
    blockConfirmations: 6
  },
  mumbai: {
    blockConfirmations: 3
  }
}

const developmentChains = ['hardhat', 'localhost']

module.exports = {developmentChains, networkConfig}
