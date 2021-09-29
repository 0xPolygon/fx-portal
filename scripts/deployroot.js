require('dotenv').config()
const config = require('../config/config.json')
const hre = require('hardhat')

// Use your own deployed child tunnel addresses here instead!
const fxERC20ChildTunnel = '0x918cc10cf2393bb9803f9d9D3219539a1e736dd9'
const fxERC721ChildTunnel = '0xdC335C19868d49aCa554AA64d5ae8524A093De5b'
const fxERC1155ChildTunnel = '0x46d40260e48A6164bbF24206D3AB9426a41D8664'

async function main () {
  let fxRoot, checkpointManager, fxERC20, fxERC721, fxERC1155

  const network = await hre.ethers.provider.getNetwork()

  if (network.chainId === 1) { // Ethereum Mainnet
    fxRoot = config.mainnet.fxRoot.address
    checkpointManager = config.mainnet.checkpointManager.address
    fxERC20 = config.mainnet.fxERC20.address
    fxERC721 = config.mainnet.fxERC721.address
    fxERC1155 = config.mainnet.fxERC1155.address
  } else if (network.chainId === 5) { // Goerli Testnet
    fxRoot = config.testnet.fxRoot.address
    checkpointManager = config.testnet.checkpointManager.address
    fxERC20 = config.testnet.fxERC20.address
    fxERC721 = config.testnet.fxERC721.address
    fxERC1155 = config.testnet.fxERC1155.address
  } else {
    fxRoot = process.env.FX_ROOT
    checkpointManager = process.env.CHECKPOINT_MANAGER
    fxERC20 = process.env.FX_ERC20
    fxERC721 = process.env.FX_ERC721
    fxERC1155 = process.env.FX_ERC1155
  }

  // You will want to use your own tunnel addresses here instead!
  const ERC20 = await hre.ethers.getContractFactory('FxERC20RootTunnel')
  const erc20 = await ERC20.deploy(checkpointManager, fxRoot, fxERC20)
  console.log(erc20.deployTransaction)
  await erc20.deployTransaction.wait()
  console.log('ERC20RootTunnel deployed to:', erc20.address)

  const setERC20Child = await erc20.setFxChildTunnel(fxERC20ChildTunnel)
  console.log(setERC20Child)
  await setERC20Child.wait()
  console.log('ERC20ChildTunnel set')

  const ERC721 = await hre.ethers.getContractFactory('FxERC721RootTunnel')
  const erc721 = await ERC721.deploy(checkpointManager, fxRoot, fxERC721)
  console.log(erc721.deployTransaction)
  await erc721.deployTransaction.wait()
  console.log('ERC721RootTunnel deployed to:', erc721.address)

  const setERC721Child = await erc721.setFxChildTunnel(fxERC721ChildTunnel)
  console.log(setERC721Child)
  await setERC721Child.wait()
  console.log('ERC721ChildTunnel set')

  const ERC1155 = await hre.ethers.getContractFactory('FxERC1155RootTunnel')
  const erc1155 = await ERC1155.deploy(checkpointManager, fxRoot, fxERC1155)
  console.log(erc1155.deployTransaction)
  await erc1155.deployTransaction.wait()
  console.log('ERC1155RootTunnel deployed to:', erc1155.address)

  const setERC1155Child = await erc1155.setFxChildTunnel(fxERC1155ChildTunnel)
  console.log(setERC1155Child)
  await setERC1155Child.wait()
  console.log('ERC1155ChildTunnel set')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
