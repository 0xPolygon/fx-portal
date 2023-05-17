const verify = require('../helpers/verify')
const { networkConfig, developmentChains } = require('../helpers/hardhat-config')

const deployChild = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()

  log('----------------------------------------------------')
  log('Deploying ChildTunnel and waiting for confirmations...')

  const fxChild = process.env.FX_CHILD
  const erc20Template = process.env.ERC20_TEMPLATE

  const childTunnel = await deploy('FxERC20ChildTunnel', {
    from: deployer,
    args: [fxChild, erc20Template],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(childTunnel.address, [fxChild, erc20Template])
  }

  log('Please save child address to env...')
  log(childTunnel.address)
  log('----------------------------------------------------')
}

module.exports = deployChild
deployChild.tags = ['child']
