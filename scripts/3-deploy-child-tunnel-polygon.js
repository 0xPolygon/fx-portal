require("dotenv").config();
const config = require("../config/config.json");
const hre = require("hardhat");

async function main() {
  const rootTunnelAddress = process.env.FX_ERC20_ROOT_TUNNEL;
  if (!rootTunnelAddress) throw Error("FX_ERC20_ROOT_TUNNEL not found");

  let fxChild, erc20Token;

  const network = await hre.ethers.provider.getNetwork();
  if (network.chainId === 137) {
    // Polygon Mainnet
    fxChild = config.mainnet.fxChild.address;
    erc20Token = config.mainnet.fxERC20.address;
  } else if (network.chainId === 80001) {
    // Mumbai Testnet
    fxChild = config.testnet.fxChild.address;
    erc20Token = config.testnet.fxERC20.address;
  } else {
    throw Error("invalid network");
  }

  // deploy
  const factory = await hre.ethers.getContractFactory("FxERC20ChildTunnel");
  const childTunnel = await factory.deploy(fxChild, erc20Token);
  console.log("deploy tx:", childTunnel.deployTransaction.hash);
  await childTunnel.deployTransaction.wait();
  console.log("ERC20ChildTunnel deployed to:", childTunnel.address);

  // setFxRootTunnel
  const tx = await childTunnel.setFxRootTunnel(rootTunnelAddress);
  console.log("setFxRootTunnel tx:", tx.hash);
  await tx.wait();

  console.log("done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
