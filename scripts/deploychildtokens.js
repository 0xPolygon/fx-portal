const hre = require("hardhat");

async function main() {
  const ERC20 = await hre.ethers.getContractFactory("FxERC20");
  const erc20 = await ERC20.deploy();
  await erc20.deployTransaction.wait();
  console.log("ERC20 deployed to:", erc20.address);
  console.log("npx hardhat verify --network goerli", erc20.address);

  const ERC20Mintable = await hre.ethers.getContractFactory("FxERC20");
  const erc20Mintable = await ERC20Mintable.deploy();
  console.log(erc20Mintable.deployTransaction);
  await erc20Mintable.deployTransaction.wait();
  console.log("ERC20Mintable deployed to:", erc20Mintable.address);
  console.log("npx hardhat verify --network mumbai", erc20Mintable.address);

  const ERC721 = await hre.ethers.getContractFactory("FxERC721");
  const erc721 = await ERC721.deploy();
  console.log(erc721.deployTransaction);
  await erc721.deployTransaction.wait();
  console.log("ERC721 deployed to:", erc721.address);
  console.log("npx hardhat verify --network goerli", erc721.address);

  const ERC721Mintable = await hre.ethers.getContractFactory("FxERC721");
  const erc721Mintable = await ERC721Mintable.deploy();
  console.log(erc721Mintable.deployTransaction);
  await erc721Mintable.deployTransaction.wait();
  console.log("ERC721Mintable deployed to:", erc721Mintable.address);
  console.log("npx hardhat verify --network mumbai", erc721Mintable.address);

  const ERC1155 = await hre.ethers.getContractFactory("FxERC1155");
  const erc1155 = await ERC1155.deploy();
  console.log(erc1155.deployTransaction);
  await erc1155.deployTransaction.wait();
  console.log("ERC1155 deployed to:", erc1155.address);
  console.log("npx hardhat verify --network goerli", erc1155.address);

  const ERC1155Mintable = await hre.ethers.getContractFactory("FxERC1155");
  const erc1155Mintable = await ERC1155Mintable.deploy();
  console.log(erc1155Mintable.deployTransaction);
  await erc1155Mintable.deployTransaction.wait();
  console.log("ERC1155Mintable deployed to:", erc1155Mintable.address);
  console.log("npx hardhat verify --network mumbai", erc1155Mintable.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
