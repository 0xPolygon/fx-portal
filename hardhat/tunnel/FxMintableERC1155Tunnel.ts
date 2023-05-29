import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { ChildFixture, RootFixture, childFixture } from "../shared/fixtures";
import { FxERC1155 } from "../../types/FxERC1155";
import { FxMintableERC1155ChildTunnel } from "../../types/FxMintableERC1155ChildTunnel";
import { FxMintableERC1155RootTunnel } from "../../types/FxMintableERC1155RootTunnel";
import { rootFixture } from "../shared/fixtures";
import { MockCheckpointManager } from "../../types/MockCheckpointManager";
import { FxMintableERC1155 } from "../../types/FxMintableERC1155";
import { buildPayloadForExit } from "./payload/payload";

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const tokenId = ethers.BigNumber.from("0x1337");

describe("FxMintableERC1155Tunnel", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC1155: FxERC1155;
  let fxMintableERC1155ChildTunnel: FxMintableERC1155ChildTunnel;
  let fxMintableERC1155RootTunnel: FxMintableERC1155RootTunnel;
  let checkpointManager: MockCheckpointManager;
  let fxMintableERC1155: FxMintableERC1155;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC1155 = cFixture.erc1155Token;
    fxMintableERC1155ChildTunnel = cFixture.mintableErc1155;
    fxMintableERC1155 = cFixture.mintableERC1155Token;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxMintableERC1155RootTunnel = rFixture.mintableErc1155;
    checkpointManager = rFixture.checkpointManager;
  });

  it("fxChild, deployToken success", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    let childTokenMap = await fxMintableERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
    let rootTokenMap = await fxMintableERC1155RootTunnel.rootToChildTokens(
      fxERC1155.address
    );

    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(
      fxMintableERC1155ChildTunnel.deployChildToken(
        uniqueId,
        await fxERC1155.uri(0)
      )
    ).to.emit(fxMintableERC1155ChildTunnel, "TokenMapped");

    childTokenMap = await fxMintableERC1155ChildTunnel.rootToChildToken(
      fxERC1155.address
    );
  });

  it("fxChild, deployToken fail - id is already used", async () => {
    const uniqueId = ethers.utils.randomBytes(32);
    await fxMintableERC1155ChildTunnel.deployChildToken(uniqueId, "ipfs://");
    await expect(
      fxMintableERC1155ChildTunnel.deployChildToken(uniqueId, "ipfs://")
    ).revertedWith("Create2: Failed on minimal deploy");
  });

  it("fxChild, withdraw success", async () => {
    const amount = expandTo18Decimals(10);

    const uniqueId = ethers.utils.randomBytes(32);
    const deployChildToken = await (
      await fxMintableERC1155ChildTunnel.deployChildToken(uniqueId, "ipfs://")
    ).wait();

    const rootTokenAddress = deployChildToken.events?.at(0)?.args?.at(0);
    const childTokenAddress = deployChildToken.events?.at(0)?.args?.at(1);

    const childToken = fxMintableERC1155.attach(childTokenAddress);
    const rootToken = fxERC1155.attach(rootTokenAddress);

    await childToken.mintToken(
      await wallet.getAddress(),
      tokenId,
      amount,
      "0x"
    );
    expect(
      (await childToken.balanceOf(await wallet.getAddress(), tokenId)).eq(
        amount
      )
    );

    const withdrawTx = await fxMintableERC1155ChildTunnel.withdraw(
      childTokenAddress,
      tokenId,
      amount,
      "0x"
    ); // burn
    expect(
      (await childToken.balanceOf(await wallet.getAddress(), tokenId)).eq(0)
    );

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
    await expect(fxMintableERC1155RootTunnel.receiveMessage(burnProof))
      .to.emit(fxMintableERC1155RootTunnel, "FxWithdrawMintableERC1155")
      .withArgs(
        rootTokenAddress,
        childTokenAddress,
        await wallet.getAddress(),
        tokenId,
        amount
      );

    expect(
      (await rootToken.balanceOf(await wallet.getAddress(), tokenId)).eq(amount)
    ); // root token deployed
    expect(
      (await childToken.balanceOf(await wallet.getAddress(), tokenId)).eq(0)
    );
  });
});
