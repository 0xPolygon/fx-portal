import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { ChildFixture, RootFixture, childFixture } from "../shared/fixtures";
import { FxERC1155__factory } from "../../types/factories/FxERC1155__factory";
import { FxERC1155 } from "../../types/FxERC1155";
import { FxERC1155ChildTunnel } from "../../types/FxERC1155ChildTunnel";
import { rootFixture } from "../shared/fixtures";
import { FxERC1155RootTunnel } from "../../types/FxERC1155RootTunnel";
import { buildPayloadForExit } from "./payload/payload";
import { MockCheckpointManager } from "../../types/MockCheckpointManager";

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

describe("FxERC1155Tunnel", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC1155: FxERC1155;
  let fxERC1155ChildTunnel: FxERC1155ChildTunnel;
  let fxERC1155RootTunnel: FxERC1155RootTunnel;
  let checkpointManager: MockCheckpointManager;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC1155 = cFixture.erc1155Token;
    fxERC1155ChildTunnel = cFixture.erc1155;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxERC1155RootTunnel = rFixture.erc1155;
    checkpointManager = rFixture.checkpointManager;

    const tokenId = 0;
    const tokenAmount = 100;
    await fxERC1155.mint(await wallet.getAddress(), tokenId, tokenAmount, "0x");
  });

  it("fxRoot, mapToken", async () => {
    let childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    let rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(fxERC1155RootTunnel.mapToken(fxERC1155.address))
      .to.emit(fxERC1155RootTunnel, "TokenMappedERC1155")
      .to.emit(fxERC1155ChildTunnel, "TokenMapped");
    // .withArgs(fxERC1155.address, await other.getAddress(), TEST_AMOUNT);

    childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );
  });

  it("fxRoot, deposit with mapToken", async () => {
    let childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    let rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    const tokenAmount = 50;
    await fxERC1155.setApprovalForAll(fxERC1155RootTunnel.address, true);

    await expect(
      fxERC1155RootTunnel.deposit(
        fxERC1155.address,
        await wallet.getAddress(),
        tokenId,
        tokenAmount,
        "0x"
      )
    )
      .to.emit(fxERC1155RootTunnel, "TokenMappedERC1155")
      .to.emit(fxERC1155ChildTunnel, "TokenMapped")
      .to.emit(fxERC1155RootTunnel, "FxDepositERC1155");

    childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC1155: FxERC1155 = await new FxERC1155__factory(
      wallet
    ).attach(childTokenMap);
    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(tokenAmount);
  });

  it("fxRoot, deposit after mapToken", async () => {
    let childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    let rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    const tokenAmount = 50;
    await fxERC1155.setApprovalForAll(fxERC1155RootTunnel.address, true);

    await expect(fxERC1155RootTunnel.mapToken(fxERC1155.address))
      .to.emit(fxERC1155RootTunnel, "TokenMappedERC1155")
      .to.emit(fxERC1155ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC1155: FxERC1155 = await new FxERC1155__factory(
      wallet
    ).attach(childTokenMap);
    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(0);

    await expect(
      fxERC1155RootTunnel.deposit(
        fxERC1155.address,
        await wallet.getAddress(),
        tokenId,
        tokenAmount,
        "0x"
      )
    )
      .to.emit(fxERC1155RootTunnel, "FxDepositERC1155")
      .withArgs(
        fxERC1155.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        tokenId,
        tokenAmount
      )
      .to.emit(childFxERC1155, "TransferSingle")
      .withArgs(
        fxERC1155ChildTunnel.address,
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        tokenId,
        tokenAmount
      );

    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(tokenAmount);
  });

  it("fxChild, withdraw fail: unmapped token", async () => {
    const tokenId = 0;
    const tokenAmount = 50;

    await expect(
      fxERC1155ChildTunnel.withdraw(
        fxERC1155.address,
        tokenId,
        tokenAmount,
        "0x"
      )
    ).to.be.revertedWith("FxERC1155ChildTunnel: NO_MAPPED_TOKEN");
  });

  it("fxChild, withdraw success on child chain", async () => {
    let childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    let rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    const tokenAmount = 50;
    await fxERC1155.setApprovalForAll(fxERC1155RootTunnel.address, true);

    await expect(fxERC1155RootTunnel.mapToken(fxERC1155.address))
      .to.emit(fxERC1155RootTunnel, "TokenMappedERC1155")
      .to.emit(fxERC1155ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC1155: FxERC1155 = await new FxERC1155__factory(
      wallet
    ).attach(childTokenMap);
    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(0);

    await expect(
      fxERC1155RootTunnel.deposit(
        fxERC1155.address,
        await wallet.getAddress(),
        tokenId,
        tokenAmount,
        "0x"
      )
    )
      .to.emit(fxERC1155RootTunnel, "FxDepositERC1155")
      .withArgs(
        fxERC1155.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        tokenId,
        tokenAmount
      )
      .to.emit(childFxERC1155, "TransferSingle")
      .withArgs(
        fxERC1155ChildTunnel.address,
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        tokenId,
        tokenAmount
      );

    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(tokenAmount);

    const WITHDRAW = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("WITHDRAW")
    );

    const abiCoder = ethers.utils.defaultAbiCoder;
    const messageData = abiCoder.encode(
      ["address", "address", "address", "uint256", "uint256", "bytes"],
      [
        fxERC1155.address,
        childFxERC1155.address,
        await wallet.getAddress(),
        tokenId,
        tokenAmount,
        "0x",
      ]
    );
    const withdrawMessageData = abiCoder.encode(
      ["bytes32", "bytes"],
      [WITHDRAW, messageData]
    );

    await expect(
      fxERC1155ChildTunnel.withdraw(
        childFxERC1155.address,
        tokenId,
        tokenAmount,
        "0x"
      )
    )
      .to.emit(childFxERC1155, "TransferSingle")
      .withArgs(
        fxERC1155ChildTunnel.address,
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        tokenId,
        tokenAmount
      )
      .to.emit(fxERC1155ChildTunnel, "MessageSent")
      .withArgs(withdrawMessageData);

    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(0);
  });

  it("fxChild, withdraw success syncing with root chain", async () => {
    let childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    let rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    const tokenId = 0;
    const tokenAmount = 50;
    await fxERC1155.setApprovalForAll(fxERC1155RootTunnel.address, true);

    await expect(fxERC1155RootTunnel.mapToken(fxERC1155.address))
      .to.emit(fxERC1155RootTunnel, "TokenMappedERC1155")
      .to.emit(fxERC1155ChildTunnel, "TokenMapped");

    childTokenMap = await fxERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    rootTokenMap = await fxERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );
    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    const childFxERC1155: FxERC1155 = await new FxERC1155__factory(
      wallet
    ).attach(childTokenMap);
    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(0);

    await expect(
      fxERC1155RootTunnel.deposit(
        fxERC1155.address,
        await wallet.getAddress(),
        tokenId,
        tokenAmount,
        "0x"
      )
    )
      .to.emit(fxERC1155RootTunnel, "FxDepositERC1155")
      .withArgs(
        fxERC1155.address,
        await wallet.getAddress(),
        await wallet.getAddress(),
        tokenId,
        tokenAmount
      )
      .to.emit(childFxERC1155, "TransferSingle")
      .withArgs(
        fxERC1155ChildTunnel.address,
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        tokenId,
        tokenAmount
      );

    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(tokenAmount);

    const WITHDRAW = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("WITHDRAW")
    );

    const abiCoder = ethers.utils.defaultAbiCoder;
    const messageData = abiCoder.encode(
      ["address", "address", "address", "uint256", "uint256", "bytes"],
      [
        fxERC1155.address,
        childFxERC1155.address,
        await wallet.getAddress(),
        tokenId,
        tokenAmount,
        "0x",
      ]
    );

    expect(await fxERC1155.balanceOf(await wallet.getAddress(), tokenId)).to.eq(
      tokenAmount
    );
    const withdrawTx = await fxERC1155ChildTunnel.withdraw(
      childFxERC1155.address,
      tokenId,
      tokenAmount,
      "0x"
    );
    expect(await fxERC1155.balanceOf(await wallet.getAddress(), tokenId)).to.eq(
      tokenAmount
    );
    expect(
      await childFxERC1155.balanceOf(await wallet.getAddress(), tokenId)
    ).to.eq(0);

    const { burnProof, root } = await buildPayloadForExit(withdrawTx.hash);
    await checkpointManager.submitCheckpoint(
      500,
      root,
      withdrawTx.blockNumber! - 1,
      withdrawTx.blockNumber!
    ); // mock block root

    await fxERC1155RootTunnel.receiveMessage(burnProof);
    expect(await fxERC1155.balanceOf(await wallet.getAddress(), tokenId)).to.eq(
      2 * tokenAmount
    );
  });
});
