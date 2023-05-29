import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { ChildFixture, RootFixture, childFixture } from "../shared/fixtures";
import { FxERC20 } from "../../types/FxERC20";
import { FxMintableERC20ChildTunnel } from "../../types/FxMintableERC20ChildTunnel";
import { FxMintableERC20RootTunnel } from "../../types/FxMintableERC20RootTunnel";
import { rootFixture } from "../shared/fixtures";
import { MockCheckpointManager } from "../../types/MockCheckpointManager";
import { FxMintableERC20 } from "../../types/FxMintableERC20";
import { buildPayloadForExit } from "./payload/payload";

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);

describe("FxMintableERC20Tunnel", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC20: FxERC20;
  let fxMintableERC20ChildTunnel: FxMintableERC20ChildTunnel;
  let fxMintableERC20RootTunnel: FxMintableERC20RootTunnel;
  let checkpointManager: MockCheckpointManager;
  let fxMintableERC20: FxMintableERC20;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC20 = cFixture.erc20Token;
    fxMintableERC20ChildTunnel = cFixture.mintableErc20;
    fxMintableERC20 = cFixture.mintableERC20Token;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxMintableERC20RootTunnel = rFixture.mintableErc20;
    checkpointManager = rFixture.checkpointManager;

    await fxERC20.mint(await wallet.getAddress(), TOTAL_SUPPLY);
  });

  it("fxChild, deployToken success", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    let childTokenMap = await fxMintableERC20ChildTunnel.rootToChildToken(
      fxERC20.address
    );
    let rootTokenMap = await fxMintableERC20RootTunnel.rootToChildTokens(
      fxERC20.address
    );

    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(
      fxMintableERC20ChildTunnel.deployChildToken(
        uniqueId,
        await fxERC20.name(),
        await fxERC20.symbol(),
        await fxERC20.decimals()
      )
    ).to.emit(fxMintableERC20ChildTunnel, "TokenMapped");

    childTokenMap = await fxMintableERC20ChildTunnel.rootToChildToken(
      fxERC20.address
    );
  });

  it("fxChild, deployToken fail - id is already used", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    await fxMintableERC20ChildTunnel.deployChildToken(
      uniqueId,
      "FxMintableRC20 Child Token",
      "FMCT",
      18
    );
    await expect(
      fxMintableERC20ChildTunnel.deployChildToken(
        uniqueId,
        "FxMintableRC20 Child Token",
        "FMCT",
        18
      )
    ).revertedWith("Create2: Failed on minimal deploy");
  });

  it("fxChild, withdraw success", async () => {
    const amount = expandTo18Decimals(10);

    const uniqueId = ethers.utils.randomBytes(32);
    const deployChildToken = await (
      await fxMintableERC20ChildTunnel.deployChildToken(
        uniqueId,
        "FxMintableERC20",
        "FM1",
        18
      )
    ).wait();
    // const childTokenAddress =
    //   await fxMintableERC20ChildTunnel.computedCreate2Address(
    //     ethers.utils.keccak256(uniqueId),
    //     ethers.utils.keccak256(FxMintableERC20__factory.bytecode),
    //     fxMintableERC20ChildTunnel.address
    //   );
    // const rootTokenAddress =
    // await fxMintableERC20ChildTunnel.computedCreate2Address(
    //   ethers.utils.keccak256(uniqueId),
    //   ethers.utils.keccak256(
    //     await fxMintableERC20ChildTunnel.rootTokenTemplateCodeHash()
    //   ),
    //   fxMintableERC20RootTunnel.address
    // );
    const rootTokenAddress = deployChildToken.events?.at(0)?.args?.at(0);
    const childTokenAddress = deployChildToken.events?.at(0)?.args?.at(1);

    const childToken = fxMintableERC20.attach(childTokenAddress);
    const rootToken = fxERC20.attach(rootTokenAddress);

    await childToken.mintToken(await wallet.getAddress(), amount);
    expect((await childToken.balanceOf(await wallet.getAddress())).eq(amount));

    const withdrawTx = await fxMintableERC20ChildTunnel.withdraw(
      childTokenAddress,
      amount
    ); // burn
    expect((await childToken.balanceOf(await wallet.getAddress())).eq(0));

    const { root, burnProof } = await buildPayloadForExit(withdrawTx.hash);
    expect(
      await ethers.provider.send("eth_getCode", [rootTokenAddress])
    ).to.equal("0x"); // root token not deployed yet

    await checkpointManager.submitCheckpoint(
      500,
      root,
      withdrawTx.blockNumber! - 1,
      withdrawTx.blockNumber!
    );
    await expect(fxMintableERC20RootTunnel.receiveMessage(burnProof))
      .to.emit(fxMintableERC20RootTunnel, "FxWithdrawMintableERC20")
      .withArgs(
        rootTokenAddress,
        childTokenAddress,
        await wallet.getAddress(),
        amount
      );

    expect((await rootToken.balanceOf(await wallet.getAddress())).eq(amount)); // root token deployed
    expect((await childToken.balanceOf(await wallet.getAddress())).eq(0));
  });
});
