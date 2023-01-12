require("dotenv").config();
const config = require("../config/config.json");
const hre = require("hardhat");

async function main() {
  let fxChild,
    erc20Token,
    erc20MintableToken,
    rootERC20Token,
    erc721Token,
    erc721MintableToken,
    rootERC721Token,
    erc1155Token,
    erc1155MintableToken,
    rootERC1155Token;

  const network = await hre.ethers.provider.getNetwork();

  if (network.chainId === 137) {
    // Polygon Mainnet
    fxChild = config.mainnet.fxChild.address;
    erc20Token = config.mainnet.fxERC20.address;
    erc20MintableToken = config.mainnet.fxMintableERC20.address;
    rootERC20Token = config.mainnet.rootFxERC20.address;
    erc721Token = config.mainnet.fxERC721.address;
    erc721MintableToken = config.mainnet.fxMintableERC721.address;
    rootERC721Token = config.mainnet.rootFxERC721.address;
    erc1155Token = config.mainnet.fxERC1155.address;
    erc1155MintableToken = config.mainnet.fxMintableERC1155.address;
    rootERC1155Token = config.mainnet.rootFxERC1155.address;
  } else if (network.chainId === 80001) {
    // Mumbai Testnet
    fxChild = config.testnet.fxChild.address;
    erc20MintableToken = config.testnet.fxMintableERC20.address;
    rootERC20Token = config.testnet.rootFxERC20.address;
    erc721Token = config.testnet.fxERC721.address;
    erc721MintableToken = config.testnet.fxMintableERC721.address;
    rootERC721Token = config.testnet.rootFxERC721.address;
    erc1155Token = config.testnet.fxERC1155.address;
    erc1155MintableToken = config.testnet.fxMintableERC1155.address;
    rootERC1155Token = config.testnet.rootFxERC1155.address;
  } else {
    fxChild = process.env.FX_CHILD;
    erc20Token = process.env.FX_ERC20;
    erc20MintableToken = process.env.FX_ERC20_MINTABLE;
    erc721Token = process.env.FX_ERC721;
    erc721MintableToken = process.env.FX_ERC721_MINTABLE;
    erc1155Token = process.env.FX_ERC1155;
    erc1155MintableToken = process.env.FX_ERC1155_MINTABLE;
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

  const ERC20Mintable = await hre.ethers.getContractFactory(
    "FxMintableERC20ChildTunnel"
  );
  const erc20Mintable = await ERC20Mintable.deploy(
    fxChild,
    erc20MintableToken,
    rootERC20Token
  );
  console.log(erc20Mintable.deployTransaction);
  await erc20Mintable.deployTransaction.wait();
  console.log("ERC20MintableChildTunnel deployed to:", erc20Mintable.address);
  console.log(
    "npx hardhat verify --network mumbai",
    erc20Mintable.address,
    fxChild,
    erc20MintableToken,
    rootERC20Token
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

  const ERC721Mintable = await hre.ethers.getContractFactory(
    "FxMintableERC721ChildTunnel"
  );
  const erc721Mintable = await ERC721Mintable.deploy(
    fxChild,
    erc721MintableToken,
    rootERC721Token
  );
  console.log(erc721Mintable.deployTransaction);
  await erc721Mintable.deployTransaction.wait();
  console.log("ERC721MintableChildTunnel deployed to:", erc721Mintable.address);
  console.log(
    "npx hardhat verify --network mumbai",
    erc721Mintable.address,
    fxChild,
    erc721MintableToken,
    rootERC721Token
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

  const ERC1155Mintable = await hre.ethers.getContractFactory(
    "FxMintableERC1155ChildTunnel"
  );
  const erc1155Mintable = await ERC1155Mintable.deploy(
    fxChild,
    erc1155MintableToken,
    rootERC1155Token
  );
  console.log(erc1155Mintable.deployTransaction);
  await erc1155Mintable.deployTransaction.wait();
  console.log(
    "ERC1155MintableChildTunnel deployed to:",
    erc1155Mintable.address
  );
  console.log(
    "npx hardhat verify --network mumbai",
    erc1155Mintable.address,
    fxChild,
    erc1155MintableToken,
    rootERC1155Token
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
