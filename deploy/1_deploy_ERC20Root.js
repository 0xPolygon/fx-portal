const verify = require('../helpers/verify')
const { ethers } = require("hardhat");
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

  const fxChildAddress = process.env.CHILD_ADDRESS

  const rootTunnel = await deploy('FxERC20RootTunnel', {
    from: deployer,
    args: [checkpointManager, fxRoot, erc20Template],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })

  const rootTunnelContract = await ethers.getContractAt(
    "FxERC20RootTunnel",
    rootTunnel.address
  );

  log('Setting child tunnel...')

  await rootTunnelContract.setFxChildTunnel(fxChildAddress)

  log('Set')

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(rootTunnel.address, [checkpointManager, fxRoot, erc20Template])
  }
}

module.exports = deployRoot
deployRoot.tags = ['root']
