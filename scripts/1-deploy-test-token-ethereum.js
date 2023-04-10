const hre = require("hardhat");

async function main() {
  const network = await hre.ethers.provider.getNetwork();
  if (network.chainId !== 1 && network.chainId !== 5) {
    throw Error("invalid network");
  }

  const factory = await hre.ethers.getContractFactory("TEST");
  const token = await factory.deploy();
  console.log("deploy tx:", token.deployTransaction.hash);
  await token.deployTransaction.wait();
  console.log("TEST deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
