const verify = require('../helpers/verify')
const { networkConfig, developmentChains } = require('../helpers/hardhat-config')

const deployRoot = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()

  log('----------------------------------------------------')
  log('Deploying RootTunnel and waiting for confirmations...')

  const checkpointManager = process.env.CHECKPOINT_MANAGER
  const fxRoot = process.env.FX_ROOT
  const erc20Template = process.env.ERC20_TEMPLATE

  const rootTunnel = await deploy('FxERC20RootTunnel', {
    from: deployer,
    args: [checkpointManager, fxRoot, erc20Template],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(rootTunnel.address, [checkpointManager, fxRoot, erc20Template])
  }
}

module.exports = deployRoot
deployRoot.tags = ['root']
