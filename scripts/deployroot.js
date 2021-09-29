const hre = require('hardhat')
require('dotenv').config()

async function main () {
  let fxRoot, checkpointManager

  const network = await hre.ethers.provider.getNetwork()

  if (network.chainId === 1) { // Ethereum Mainnet
    fxRoot = '0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2'
    checkpointManager = '0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287'
  } else if (network.chainId === 5) { // Goerli Testnet
    fxRoot = '0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA'
    checkpointManager = '0x2890bA17EfE978480615e330ecB65333b880928e'
  } else {
    fxRoot = process.env.FX_ROOT
    checkpointManager = process.env.CHECKPOINT_MANAGER
  }

  // You will want to use your own tunnel addresses here instead!
  const ERC20 = await hre.ethers.getContractFactory('FxERC20RootTunnel')
  const erc20 = await ERC20.deploy(checkpointManager, fxRoot, '0xAd87e3b217c66B0D45dEaFBC540330d300811b94')
  console.log(erc20.deployTransaction)
  await erc20.deployTransaction.wait()
  console.log('ERC20RootTunnel deployed to:', erc20.address)

  const setERC20Child = await erc20.setFxChildTunnel('0x918cc10cf2393bb9803f9d9D3219539a1e736dd9')
  console.log(setERC20Child)
  await setERC20Child.wait()
  console.log('ERC20ChildTunnel set')

  const ERC721 = await hre.ethers.getContractFactory('FxERC721RootTunnel')
  const erc721 = await ERC721.deploy(checkpointManager, fxRoot, '0x467c9BA5DAB81C8975F7d8237ECe61918AA6e8fF')
  console.log(erc721.deployTransaction)
  await erc721.deployTransaction.wait()
  console.log('ERC721RootTunnel deployed to:', erc721.address)

  const setERC721Child = await erc721.setFxChildTunnel('0xdC335C19868d49aCa554AA64d5ae8524A093De5b')
  console.log(setERC721Child)
  await setERC721Child.wait()
  console.log('ERC721ChildTunnel set')

  const ERC1155 = await hre.ethers.getContractFactory('FxERC1155RootTunnel')
  const erc1155 = await ERC1155.deploy(checkpointManager, fxRoot, '0x4443c9877aB1767e1080fa70Ac038758e526c609')
  console.log(erc1155.deployTransaction)
  await erc1155.deployTransaction.wait()
  console.log('ERC1155RootTunnel deployed to:', erc1155.address)

  const setERC1155Child = await erc1155.setFxChildTunnel('0x46d40260e48A6164bbF24206D3AB9426a41D8664')
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
