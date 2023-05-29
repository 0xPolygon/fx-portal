import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { ChildFixture, RootFixture, childFixture } from "../shared/fixtures";
import { FxERC721 } from "../../types/FxERC721";
import { FxMintableERC721ChildTunnel } from "../../types/FxMintableERC721ChildTunnel";
import { FxMintableERC721RootTunnel } from "../../types/FxMintableERC721RootTunnel";
import { rootFixture } from "../shared/fixtures";
import { MockCheckpointManager } from "../../types/MockCheckpointManager";
import { FxMintableERC721 } from "../../types/FxMintableERC721";
import { buildPayloadForExit } from "./payload/payload";

chai.use(solidity);

const tokenId = ethers.BigNumber.from("0x1337");

describe("FxMintableERC721Tunnel", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC721: FxERC721;
  let fxMintableERC721ChildTunnel: FxMintableERC721ChildTunnel;
  let fxMintableERC721RootTunnel: FxMintableERC721RootTunnel;
  let checkpointManager: MockCheckpointManager;
  let fxMintableERC721: FxMintableERC721;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC721 = cFixture.erc721Token;
    fxMintableERC721ChildTunnel = cFixture.mintableErc721;
    fxMintableERC721 = cFixture.mintableERC721Token;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxMintableERC721RootTunnel = rFixture.mintableErc721;
    checkpointManager = rFixture.checkpointManager;
  });

  it("fxChild, deployToken success", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    let childTokenMap = await fxMintableERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
    let rootTokenMap = await fxMintableERC721RootTunnel.rootToChildTokens(
      fxERC721.address
    );

    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(
      fxMintableERC721ChildTunnel.deployChildToken(
        uniqueId,
        await fxERC721.name(),
        await fxERC721.symbol()
      )
    ).to.emit(fxMintableERC721ChildTunnel, "TokenMapped");

    childTokenMap = await fxMintableERC721ChildTunnel.rootToChildToken(
      fxERC721.address
    );
  });

  it("fxChild, deployToken fail - id is already used", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    await fxMintableERC721ChildTunnel.deployChildToken(
      uniqueId,
      "FxMintable721 Child Token",
      "FMCT"
    );
    await expect(
      fxMintableERC721ChildTunnel.deployChildToken(
        uniqueId,
        "FxMintable721 Child Token",
        "FMCT"
      )
    ).revertedWith("Create2: Failed on minimal deploy");
  });

  it("fxChild, withdraw success", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    const deployChildToken = await (
      await fxMintableERC721ChildTunnel.deployChildToken(
        uniqueId,
        "FxMintableERC721",
        "FM1"
      )
    ).wait();

    const rootTokenAddress = deployChildToken.events?.at(0)?.args?.at(0);
    const childTokenAddress = deployChildToken.events?.at(0)?.args?.at(1);

    const childToken = fxMintableERC721.attach(childTokenAddress);
    const rootToken = fxERC721.attach(rootTokenAddress);

    await childToken.mintToken(await wallet.getAddress(), tokenId, "0x");
    expect(await childToken.ownerOf(tokenId)).to.eq(await wallet.getAddress());

    const withdrawTx = await fxMintableERC721ChildTunnel.withdraw(
      childTokenAddress,
      tokenId,
      "0x"
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
    await expect(fxMintableERC721RootTunnel.receiveMessage(burnProof))
      .to.emit(fxMintableERC721RootTunnel, "FxWithdrawMintableERC721")
      .withArgs(
        rootTokenAddress,
        childTokenAddress,
        await wallet.getAddress(),
        tokenId
      );

    expect(await rootToken.ownerOf(tokenId)).to.eq(await wallet.getAddress()); // root token deployed
    expect((await childToken.balanceOf(await wallet.getAddress())).eq(0));
  });
});
