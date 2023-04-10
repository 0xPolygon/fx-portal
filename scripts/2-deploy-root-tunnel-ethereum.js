const config = require("../config/config.json");
const hre = require("hardhat");

async function main() {
  let fxRoot, checkpointManager, fxERC20;

  const network = await hre.ethers.provider.getNetwork();
  if (network.chainId === 1) {
    // Ethereum Mainnet
    fxRoot = config.mainnet.fxRoot.address;
    checkpointManager = config.mainnet.checkpointManager.address;
    fxERC20 = config.mainnet.fxERC20.address;
  } else if (network.chainId === 5) {
    // Goerli Testnet
    fxRoot = config.testnet.fxRoot.address;
    checkpointManager = config.testnet.checkpointManager.address;
    fxERC20 = config.testnet.fxERC20.address;
  } else {
    throw Error("invalid network");
  }

  const factory = await hre.ethers.getContractFactory("FxERC20RootTunnel");
  const rootTunnel = await factory.deploy(checkpointManager, fxRoot, fxERC20);
  console.log("deploy tx:", rootTunnel.deployTransaction.hash);
  await rootTunnel.deployTransaction.wait();
  console.log("ERC20RootTunnel deployed to:", rootTunnel.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
