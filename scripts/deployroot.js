require("dotenv").config();
const config = require("../config/config.json");
const hre = require("hardhat");

// Use your own deployed child tunnel addresses here instead!
const fxERC20ChildTunnel = "0x587C9FF1c528C7aeE2804Bf5301Dc2ec057A75a8";
const fxMintableERC20ChildTunnel = "0xE633A3eeADF030Edf6ABB6Ebbf792679a475C042";
const fxERC721ChildTunnel = "0x96d26FCA4cB14e14CABc28eF8bc8Aba0E03702A8";
const fxMintableERC721ChildTunnel =
  "0x48e3794678063E2a0188c9008023F32F79c521EE";
const fxERC1155ChildTunnel = "0x24a16Db524d342968A11b9E1aD75b6D5eD002db7";
const fxMintableERC1155ChildTunnel =
  "0x1Cb7A30cF8639AC301Be898CA49F340291C75A83";

async function main() {
  let fxRoot,
    checkpointManager,
    fxERC20,
    rootFxERC20,
    fxERC721,
    rootFxERC721,
    fxERC1155,
    rootFxERC1155;

  const network = await hre.ethers.provider.getNetwork();

  if (network.chainId === 1) {
    // Ethereum Mainnet
    fxRoot = config.mainnet.fxRoot.address;
    checkpointManager = config.mainnet.checkpointManager.address;
    fxERC20 = config.mainnet.fxERC20.address;
    rootFxERC20 = config.mainnet.rootFxERC20.address;
    fxERC721 = config.mainnet.fxERC721.address;
    rootFxERC721 = config.mainnet.rootFxERC721.address;
    fxERC1155 = config.mainnet.fxERC1155.address;
    rootFxERC1155 = config.mainnet.rootFxERC1155.address;
  } else if (network.chainId === 5) {
    // Goerli Testnet
    fxRoot = config.testnet.fxRoot.address;
    checkpointManager = config.testnet.checkpointManager.address;
    fxERC20 = config.testnet.fxERC20.address;
    rootFxERC20 = config.testnet.rootFxERC20.address;
    fxERC721 = config.testnet.fxERC721.address;
    rootFxERC721 = config.testnet.rootFxERC721.address;
    fxERC1155 = config.testnet.fxERC1155.address;
    rootFxERC1155 = config.testnet.rootFxERC1155.address;
  } else {
    fxRoot = process.env.FX_ROOT;
    checkpointManager = process.env.CHECKPOINT_MANAGER;
    fxERC20 = process.env.FX_ERC20;
    rootFxERC20 = process.env.FX_ERC20_MINTABLE;
    fxERC721 = process.env.FX_ERC721;
    rootFxERC721 = process.env.FX_ROOT_ERC721;
    fxERC1155 = process.env.FX_ERC1155;
    rootFxERC1155 = process.env.FX_ERC1155_MINTABLE;
  }

  const ERC20 = await hre.ethers.getContractFactory("FxERC20RootTunnel");
  const erc20 = await ERC20.deploy(checkpointManager, fxRoot, fxERC20);
  console.log(erc20.deployTransaction);
  await erc20.deployTransaction.wait();
  console.log("ERC20RootTunnel deployed to:", erc20.address);
  console.log(
    "npx hardhat verify --network goerli",
    erc20.address,
    checkpointManager,
    fxRoot,
    fxERC20
  );

  const setERC20Child = await erc20.setFxChildTunnel(fxERC20ChildTunnel);
  console.log(setERC20Child);
  await setERC20Child.wait();
  console.log("ERC20ChildTunnel set");

  const ERC20Mintable = await hre.ethers.getContractFactory(
    "FxMintableERC20RootTunnel"
  );
  const erc20Mintable = await ERC20Mintable.deploy(
    checkpointManager,
    fxRoot,
    rootFxERC20
  );
  console.log(erc20Mintable.deployTransaction);
  await erc20Mintable.deployTransaction.wait();
  console.log("ERC20MintableRootTunnel deployed to:", erc20Mintable.address);
  console.log(
    "npx hardhat verify --network goerli",
    erc20Mintable.address,
    checkpointManager,
    fxRoot,
    rootFxERC20
  );

  const setERC20MintableChild = await erc20Mintable.setFxChildTunnel(
    fxMintableERC20ChildTunnel
  );
  console.log(setERC20MintableChild);
  await setERC20MintableChild.wait();
  console.log("ERC20MintableChildTunnel set");

  const ERC721 = await hre.ethers.getContractFactory("FxERC721RootTunnel");
  const erc721 = await ERC721.deploy(checkpointManager, fxRoot, fxERC721);
  console.log(erc721.deployTransaction);
  await erc721.deployTransaction.wait();
  console.log("ERC721RootTunnel deployed to:", erc721.address);
  console.log(
    "npx hardhat verify --network goerli",
    erc721.address,
    checkpointManager,
    fxRoot,
    fxERC721
  );

  const setERC721Child = await erc721.setFxChildTunnel(fxERC721ChildTunnel);
  console.log(setERC721Child);
  await setERC721Child.wait();
  console.log("ERC721ChildTunnel set");

  const ERC721Mintable = await hre.ethers.getContractFactory(
    "FxMintableERC721RootTunnel"
  );
  const erc721Mintable = await ERC721Mintable.deploy(
    checkpointManager,
    fxRoot,
    rootFxERC721
  );
  console.log(erc721Mintable.deployTransaction);
  await erc721Mintable.deployTransaction.wait();
  console.log("ERC721MintableRootTunnel deployed to:", erc721Mintable.address);
  console.log(
    "npx hardhat verify --network goerli",
    erc721Mintable.address,
    checkpointManager,
    fxRoot,
    rootFxERC721
  );

  const setERC721MintableChild = await erc721Mintable.setFxChildTunnel(
    fxMintableERC721ChildTunnel
  );
  console.log(setERC721MintableChild);
  await setERC721MintableChild.wait();
  console.log("ERC721MintableChildTunnel set");

  const ERC1155 = await hre.ethers.getContractFactory("FxERC1155RootTunnel");
  const erc1155 = await ERC1155.deploy(checkpointManager, fxRoot, fxERC1155);
  console.log(erc1155.deployTransaction);
  await erc1155.deployTransaction.wait();
  console.log("ERC1155RootTunnel deployed to:", erc1155.address);
  console.log(
    "npx hardhat verify --network goerli",
    erc1155.address,
    checkpointManager,
    fxRoot,
    fxERC1155
  );

  const setERC1155Child = await erc1155.setFxChildTunnel(fxERC1155ChildTunnel);
  console.log(setERC1155Child);
  await setERC1155Child.wait();
  console.log("ERC1155ChildTunnel set");

  const ERC1155Mintable = await hre.ethers.getContractFactory(
    "FxMintableERC1155RootTunnel"
  );
  const erc1155Mintable = await ERC1155Mintable.deploy(
    checkpointManager,
    fxRoot,
    rootFxERC1155
  );
  console.log(erc1155Mintable.deployTransaction);
  await erc1155Mintable.deployTransaction.wait();
  console.log(
    "ERC1155MintableRootTunnel deployed to:",
    erc1155Mintable.address
  );
  console.log(
    "npx hardhat verify --network goerli",
    erc1155Mintable.address,
    checkpointManager,
    fxRoot,
    rootFxERC1155
  );

  const setERC1155MintableChild = await erc1155Mintable.setFxChildTunnel(
    fxMintableERC1155ChildTunnel
  );
  console.log(setERC1155MintableChild);
  await setERC1155MintableChild.wait();
  console.log("ERC1155MintableChildTunnel set");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
