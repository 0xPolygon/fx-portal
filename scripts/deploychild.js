require("dotenv").config();
const config = require("../config/config.json");
const hre = require("hardhat");

async function main() {
  let fxChild, erc20Token, erc721Token, erc1155Token;

  const network = await hre.ethers.provider.getNetwork();

  if (network.chainId === 137) {
    // Polygon Mainnet
    fxChild = config.mainnet.fxChild.address;
    erc20Token = config.mainnet.fxERC20.address;
    erc721Token = config.mainnet.fxERC721.address;
    erc1155Token = config.mainnet.fxERC1155.address;
  } else if (network.chainId === 80001) {
    // Mumbai Testnet
    fxChild = config.testnet.fxChild.address;
    erc20Token = config.testnet.fxERC20.address;
    erc721Token = config.testnet.fxERC721.address;
    erc1155Token = config.testnet.fxERC1155.address;
  } else {
    fxChild = process.env.FX_CHILD;
    erc20Token = process.env.FX_ERC20;
    erc721Token = process.env.FX_ERC721;
    erc1155Token = process.env.FX_ERC1155;
  }

  const ERC20 = await hre.ethers.getContractFactory("FxERC20ChildTunnel");
  const erc20 = await ERC20.deploy(fxChild, erc20Token);
  await erc20.deployTransaction.wait();
  console.log("ERC20ChildTunnel deployed to:", erc20.address);
  console.log(
    "npx hardhat verify --network mumbai",
    erc20.address,
    fxChild,
    erc20Token
  );

  const ERC721 = await hre.ethers.getContractFactory("FxERC721ChildTunnel");
  const erc721 = await ERC721.deploy(fxChild, erc721Token);
  console.log(erc721.deployTransaction);
  await erc721.deployTransaction.wait();
  console.log("ERC721ChildTunnel deployed to:", erc721.address);
  console.log(
    "npx hardhat verify --network mumbai",
    erc721.address,
    fxChild,
    erc721Token
  );

  const ERC1155 = await hre.ethers.getContractFactory("FxERC1155ChildTunnel");
  const erc1155 = await ERC1155.deploy(fxChild, erc1155Token);
  console.log(erc1155.deployTransaction);
  await erc1155.deployTransaction.wait();
  console.log("ERC1155ChildTunnel deployed to:", erc1155.address);
  console.log(
    "npx hardhat verify --network mumbai",
    erc1155.address,
    fxChild,
    erc1155Token
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
