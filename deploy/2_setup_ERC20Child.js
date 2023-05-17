const verify = require('../helpers/verify')
const { ethers } = require("hardhat");

const setupChild = async function (hre) {
  const { deployments } = hre
  const { log } = deployments

  log('----------------------------------------------------')
  log('Setting root tunnel on matic child contract...')

  const fxRootAddress = process.env.ROOT_ADDRESS
  const fxChildAddress = process.env.CHILD_ADDRESS

  const childTunnelContract = await ethers.getContractAt(
    "FxERC20ChildTunnel",
    fxChildAddress
  );

  await childTunnelContract.setFxRootTunnel(fxRootAddress)

  log('Set')
}

module.exports = setupChild
setupChild.tags = ['setupChild']
