import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { ChildFixture, RootFixture, childFixture } from "../shared/fixtures";
import { FxERC721 } from "../../types/FxERC721";
import { FxERC721__factory } from "../../types/factories/FxERC721__factory";
import { FxERC721ChildTunnel } from "../../types/FxERC721ChildTunnel";
import { rootFixture } from "../shared/fixtures";
import { FxERC721RootTunnel } from "../../types/FxERC721RootTunnel";
import { MockCheckpointManager } from "../../types/MockCheckpointManager";
import { buildPayloadForExit } from "./payload/payload";

chai.use(solidity);

describe("FxERC721Tunnel", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC721: FxERC721;
  let fxERC721ChildTunnel: FxERC721ChildTunnel;
  let fxERC721RootTunnel: FxERC721RootTunnel;
  let checkpointManager: MockCheckpointManager;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC721 = cFixture.erc721Token;
    fxERC721ChildTunnel = cFixture.erc721;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxERC721RootTunnel = rFixture.erc721;
    checkpointManager = rFixture.checkpointManager;

    await fxERC721.mint(await wallet.getAddress(), 0, "0x");
  });

  it("fxRoot, mapToken", async () => {
    let childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    let rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(
      fxERC721.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(fxERC721RootTunnel.mapToken(fxERC721.address))
      .to.emit(fxERC721RootTunnel, "TokenMappedERC721")
      .to.emit(fxERC721ChildTunnel, "TokenMapped");
    // .withArgs(fxERC721.address, await other.getAddress(), TEST_AMOUNT);

    childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(fxERC721.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );
  });

  it("fxRoot, deposit with mapToken", async () => {
    let childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    let rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(
      fxERC721.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    await fxERC721.approve(fxERC721RootTunnel.address, tokenId);

    await expect(
      fxERC721RootTunnel.deposit(
        fxERC721.address,
        await wallet.getAddress(),
        tokenId,
        "0x"
      )
    )
      .to.emit(fxERC721RootTunnel, "TokenMappedERC721")
      .to.emit(fxERC721ChildTunnel, "TokenMapped")
      .to.emit(fxERC721RootTunnel, "FxDepositERC721");

    childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(fxERC721.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC721: FxERC721 = await new FxERC721__factory(wallet).attach(
      childTokenMap
    );
    expect(await childFxERC721.balanceOf(await wallet.getAddress())).to.eq(1);
    expect(await childFxERC721.ownerOf(tokenId)).to.eq(
      await wallet.getAddress()
    );
  });

  it("fxRoot, deposit after mapToken", async () => {
    let childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    let rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(
      fxERC721.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    await fxERC721.approve(fxERC721RootTunnel.address, tokenId);

    await expect(fxERC721RootTunnel.mapToken(fxERC721.address))
      .to.emit(fxERC721RootTunnel, "TokenMappedERC721")
      .to.emit(fxERC721ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(fxERC721.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC721: FxERC721 = await new FxERC721__factory(wallet).attach(
      childTokenMap
    );
    expect(await childFxERC721.balanceOf(await wallet.getAddress())).to.eq(0);

    await expect(
      fxERC721RootTunnel.deposit(
        fxERC721.address,
        await wallet.getAddress(),
        tokenId,
        "0x"
      )
    )
      .to.emit(fxERC721RootTunnel, "FxDepositERC721")
      .withArgs(
        fxERC721.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        tokenId
      )
      .to.emit(childFxERC721, "Transfer")
      .withArgs(
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        tokenId
      );

    expect(await childFxERC721.balanceOf(await wallet.getAddress())).to.eq(1);
    expect(await childFxERC721.ownerOf(tokenId)).to.eq(
      await wallet.getAddress()
    );
  });

  it("fxChild, withdraw fail: unmapped token", async () => {
    const tokenId = 0;

    await expect(
      fxERC721ChildTunnel.withdraw(fxERC721.address, tokenId, "0x")
    ).to.be.revertedWith("FxERC721ChildTunnel: NO_MAPPED_TOKEN");
  });

  it("fxChild, withdraw success", async () => {
    let childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    let rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(
      fxERC721.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    await fxERC721.approve(fxERC721RootTunnel.address, tokenId);

    await expect(fxERC721RootTunnel.mapToken(fxERC721.address))
      .to.emit(fxERC721RootTunnel, "TokenMappedERC721")
      .to.emit(fxERC721ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    rootTokenMap = await fxERC721RootTunnel.rootToChildTokens(fxERC721.address);
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC721: FxERC721 = await new FxERC721__factory(wallet).attach(
      childTokenMap
    );
    expect(await childFxERC721.balanceOf(await wallet.getAddress())).to.eq(0);

    await expect(
      fxERC721RootTunnel.deposit(
        fxERC721.address,
        await wallet.getAddress(),
        tokenId,
        "0x"
      )
    )
      .to.emit(fxERC721RootTunnel, "FxDepositERC721")
      .withArgs(
        fxERC721.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        tokenId
      )
      .to.emit(childFxERC721, "Transfer")
      .withArgs(
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        tokenId
      );

    expect(await childFxERC721.balanceOf(await wallet.getAddress())).to.eq(1);

    const abiCoder = ethers.utils.defaultAbiCoder;
    const messageData = abiCoder.encode(
      ["address", "address", "address", "uint256", "bytes"],
      [
        fxERC721.address,
        childFxERC721.address,
        await wallet.getAddress(),
        tokenId,
        "0x",
      ]
    );

    const withdrawTx = await fxERC721ChildTunnel.withdraw(
      childFxERC721.address,
      tokenId,
      "0x"
    );
    await expect(withdrawTx)
      .to.emit(childFxERC721, "Transfer")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        tokenId
      )
      .to.emit(fxERC721ChildTunnel, "MessageSent")
      .withArgs(messageData);

    expect(await childFxERC721.balanceOf(await wallet.getAddress())).to.eq(0);

    const { burnProof, root } = await buildPayloadForExit(withdrawTx.hash);
    await checkpointManager.submitCheckpoint(
      500,
      root,
      withdrawTx.blockNumber! - 1,
      withdrawTx.blockNumber!
    );
    await fxERC721RootTunnel.receiveMessage(burnProof); //claim

    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(1);
  });
});
