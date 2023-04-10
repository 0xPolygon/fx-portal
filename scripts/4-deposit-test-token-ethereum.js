require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const overrides = { gasPrice: hre.ethers.utils.parseUnits("100", "gwei") };

  const network = await hre.ethers.provider.getNetwork();
  if (network.chainId !== 1 && network.chainId !== 5) {
    throw Error("invalid network");
  }

  const childTunnelAddress = process.env.FX_ERC20_CHILD_TUNNEL;
  if (!childTunnelAddress) throw Error("FX_ERC20_CHILD_TUNNEL not found");
  const rootTunnelAddress = process.env.FX_ERC20_ROOT_TUNNEL;
  if (!rootTunnelAddress) throw Error("FX_ERC20_ROOT_TUNNEL not found");
  const tokenAddress = process.env.ERC20_ROOT_TOKEN;
  if (!tokenAddress) throw Error("ERC20_ROOT_TOKEN not found");

  // get contract
  const [signer] = await hre.ethers.getSigners();
  const rootTunnel = await hre.ethers.getContractAt(
    "FxERC20RootTunnel",
    rootTunnelAddress,
    signer
  );
  console.log("ERC20RootTunnel CA:", rootTunnel.address);
  const token = await hre.ethers.getContractAt("TEST", tokenAddress, signer);
  console.log("Token CA:", token.address);

  // setFxChildTunnel
  const txSetFxChildTunnel = await rootTunnel.setFxChildTunnel(
    childTunnelAddress,
    overrides
  );
  console.log("setFxChildTunnel tx:", txSetFxChildTunnel.hash);
  await txSetFxChildTunnel.wait();

  // approve
  const amount = "400000000" + "0".repeat(18);
  const txApprove = await token.approve(rootTunnelAddress, amount, overrides);
  console.log("approve tx:", txApprove.hash);
  await txApprove.wait();

  // deposit
  const txDeposit = await rootTunnel.deposit(
    tokenAddress,
    signer.address,
    amount,
    "0x",
    overrides
  );
  console.log("deposit tx:", txDeposit.hash);
  await txDeposit.wait();

  console.log("done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
