import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { ChildFixture, RootFixture, childFixture } from "../shared/fixtures";
import { FxERC20 } from "../../types/FxERC20";
import { FxERC20__factory } from "../../types/factories/FxERC20__factory";
import { FxERC20ChildTunnel } from "../../types/FxERC20ChildTunnel";
import { rootFixture } from "../shared/fixtures";
import { FxERC20RootTunnel } from "../../types/FxERC20RootTunnel";
import { buildPayloadForExit } from "./payload/payload";
import { MockCheckpointManager } from "../../types/MockCheckpointManager";

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

describe("FxERC20Tunnel", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC20: FxERC20;
  let fxERC20ChildTunnel: FxERC20ChildTunnel;
  let fxERC20RootTunnel: FxERC20RootTunnel;
  let checkpointManager: MockCheckpointManager;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC20 = cFixture.erc20Token;
    fxERC20ChildTunnel = cFixture.erc20;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxERC20RootTunnel = rFixture.erc20;
    checkpointManager = rFixture.checkpointManager;
    await fxERC20.mint(await wallet.getAddress(), TOTAL_SUPPLY);
  });

  it("fxRoot, mapToken", async () => {
    let childTokenMap = await fxERC20ChildTunnel.rootToChildToken(
      fxERC20.address
    );
    let rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(
      fxERC20.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(fxERC20RootTunnel.mapToken(fxERC20.address))
      .to.emit(fxERC20RootTunnel, "TokenMappedERC20")
      .to.emit(fxERC20ChildTunnel, "TokenMapped");
    // .withArgs(fxERC20.address, await other.getAddress(), TEST_AMOUNT);

    childTokenMap = await fxERC20ChildTunnel.rootToChildToken(fxERC20.address);
    rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(fxERC20.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );
  });

  it("fxRoot, deposit with mapToken", async () => {
    let childTokenMap = await fxERC20ChildTunnel.rootToChildToken(
      fxERC20.address
    );
    let rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(
      fxERC20.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const amountToDeposit = expandTo18Decimals(10);
    await fxERC20.approve(fxERC20RootTunnel.address, amountToDeposit);

    await expect(
      fxERC20RootTunnel.deposit(
        fxERC20.address,
        await wallet.getAddress(),
        amountToDeposit,
        "0x"
      )
    )
      .to.emit(fxERC20RootTunnel, "TokenMappedERC20")
      .to.emit(fxERC20ChildTunnel, "TokenMapped")
      .to.emit(fxERC20RootTunnel, "FxDepositERC20");

    childTokenMap = await fxERC20ChildTunnel.rootToChildToken(fxERC20.address);
    rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(fxERC20.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC20: FxERC20 = await new FxERC20__factory(wallet).attach(
      childTokenMap
    );
    expect(await childFxERC20.balanceOf(await wallet.getAddress())).to.eq(
      amountToDeposit
    );
  });

  it("fxRoot, deposit after mapToken", async () => {
    let childTokenMap = await fxERC20ChildTunnel.rootToChildToken(
      fxERC20.address
    );
    let rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(
      fxERC20.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const amountToDeposit = expandTo18Decimals(10);
    await fxERC20.approve(fxERC20RootTunnel.address, amountToDeposit);

    await expect(fxERC20RootTunnel.mapToken(fxERC20.address))
      .to.emit(fxERC20RootTunnel, "TokenMappedERC20")
      .to.emit(fxERC20ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC20ChildTunnel.rootToChildToken(fxERC20.address);
    rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(fxERC20.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC20: FxERC20 = await new FxERC20__factory(wallet).attach(
      childTokenMap
    );
    expect(await childFxERC20.balanceOf(await wallet.getAddress())).to.eq(0);

    await expect(
      fxERC20RootTunnel.deposit(
        fxERC20.address,
        await wallet.getAddress(),
        amountToDeposit,
        "0x"
      )
    )
      .to.emit(fxERC20RootTunnel, "FxDepositERC20")
      .withArgs(
        fxERC20.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        amountToDeposit
      )
      .to.emit(childFxERC20, "Transfer")
      .withArgs(
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        amountToDeposit
      );

    expect(await childFxERC20.balanceOf(await wallet.getAddress())).to.eq(
      amountToDeposit
    );
  });

  it("fxChild, withdraw fail: unmapped token", async () => {
    const amountToDeposit = expandTo18Decimals(10);
    const amountToWithdraw = expandTo18Decimals(5);

    await expect(
      fxERC20ChildTunnel.withdraw(fxERC20.address, amountToWithdraw)
    ).to.be.revertedWith("FxERC20ChildTunnel: NO_MAPPED_TOKEN");
  });

  it("fxChild, withdraw success", async () => {
    let childTokenMap = await fxERC20ChildTunnel.rootToChildToken(
      fxERC20.address
    );
    let rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(
      fxERC20.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const amountToDeposit = expandTo18Decimals(10);
    const balanceOfRootFxERC20 = expandTo18Decimals(9990);
    await fxERC20.approve(fxERC20RootTunnel.address, amountToDeposit);

    await expect(fxERC20RootTunnel.mapToken(fxERC20.address))
      .to.emit(fxERC20RootTunnel, "TokenMappedERC20")
      .to.emit(fxERC20ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC20ChildTunnel.rootToChildToken(fxERC20.address);
    rootTokenMap = await fxERC20RootTunnel.rootToChildTokens(fxERC20.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC20: FxERC20 = await new FxERC20__factory(wallet).attach(
      childTokenMap
    );
    expect(await childFxERC20.balanceOf(await wallet.getAddress())).to.eq(0);

    await expect(
      fxERC20RootTunnel.deposit(
        fxERC20.address,
        await wallet.getAddress(),
        amountToDeposit,
        "0x"
      )
    )
      .to.emit(fxERC20RootTunnel, "FxDepositERC20")
      .withArgs(
        fxERC20.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        amountToDeposit
      )
      .to.emit(childFxERC20, "Transfer")
      .withArgs(
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        amountToDeposit
      );

    expect(await childFxERC20.balanceOf(await wallet.getAddress())).to.eq(
      amountToDeposit
    );
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      balanceOfRootFxERC20
    );

    const amountToWithdraw = expandTo18Decimals(5);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const messageData = abiCoder.encode(
      ["address", "address", "address", "uint256"],
      [
        fxERC20.address,
        childFxERC20.address,
        await wallet.getAddress(),
        amountToWithdraw,
      ]
    );

    const withdrawTx = await fxERC20ChildTunnel.withdraw(
      childFxERC20.address,
      amountToWithdraw
    );
    await expect(withdrawTx)
      .to.emit(childFxERC20, "Transfer")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        amountToWithdraw
      )
      .to.emit(fxERC20ChildTunnel, "MessageSent")
      .withArgs(messageData);

    const { burnProof, root } = await buildPayloadForExit(withdrawTx.hash);
    await checkpointManager.submitCheckpoint(
      500,
      root,
      withdrawTx.blockNumber! - 1,
      withdrawTx.blockNumber!
    );
    await fxERC20RootTunnel.receiveMessage(burnProof);

    expect(await childFxERC20.balanceOf(await wallet.getAddress())).to.eq(
      amountToWithdraw
    );
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      balanceOfRootFxERC20.add(amountToWithdraw)
    );
  });
});
