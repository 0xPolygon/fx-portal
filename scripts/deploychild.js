const hre = require('hardhat')
require('dotenv').config()

async function main () {
  let fxChild

  const network = await hre.ethers.provider.getNetwork()

  if (network.chainId === 137) { // Polygon Mainnet
    fxChild = '0x8397259c983751DAf40400790063935a11afa28a'
  } else if (network.chainId === 80001) { // Mumbai Testnet
    fxChild = '0xCf73231F28B7331BBe3124B907840A94851f9f11'
  } else {
    fxChild = process.env.FX_CHILD
  }

  const ERC20Token = await hre.ethers.getContractFactory('FxERC20')
  const erc20Token = await ERC20Token.deploy()
  console.log(erc20Token.deployTransaction)
  await erc20Token.deployTransaction.wait()
  console.log('FxERC20 deployed to:', erc20Token.address)

  const ERC20 = await hre.ethers.getContractFactory('FxERC20ChildTunnel')
  const erc20 = await ERC20.deploy(fxChild, erc20Token.address)
  await erc20.deployTransaction.wait()
  console.log('ERC20ChildTunnel deployed to:', erc20.address)

  const ERC721Token = await hre.ethers.getContractFactory('FxERC721')
  const erc721Token = await ERC721Token.deploy()
  console.log(erc721Token.deployTransaction)
  await erc721Token.deployTransaction.wait()
  console.log('FxERC721 deployed to:', erc721Token.address)

  const ERC721 = await hre.ethers.getContractFactory('FxERC721ChildTunnel')
  const erc721 = await ERC721.deploy(fxChild, erc721Token.address)
  console.log(erc721.deployTransaction)
  await erc721.deployTransaction.wait()
  console.log('ERC721ChildTunnel deployed to:', erc721.address)

  const ERC1155Token = await hre.ethers.getContractFactory('FxERC1155')
  const erc1155Token = await ERC1155Token.deploy()
  console.log(erc1155Token.deployTransaction)
  await erc1155Token.deployTransaction.wait()
  console.log('FxERC1155 deployed to:', erc1155Token.address)

  const ERC1155 = await hre.ethers.getContractFactory('FxERC1155ChildTunnel')
  const erc1155 = await ERC1155.deploy(fxChild, erc1155Token.address)
  console.log(erc1155.deployTransaction)
  await erc1155.deployTransaction.wait()
  console.log('ERC1155ChildTunnel deployed to:', erc1155.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
