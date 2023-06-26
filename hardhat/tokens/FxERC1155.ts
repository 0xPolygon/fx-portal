import chai, { expect } from "chai";
import { Signer, BigNumber } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { childFixture } from "../shared/fixtures";
import { FxERC1155 } from "../../types/FxERC1155";
import { FxERC1155ChildTunnel } from "../../types/FxERC1155ChildTunnel";

chai.use(solidity);

interface ChildFixture {
  erc1155Token: FxERC1155;
  erc1155: FxERC1155ChildTunnel;
}

describe("FxERC1155", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC1155: FxERC1155;
  let fxERC1155ChildTunnel: FxERC1155ChildTunnel;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const fixture: ChildFixture = await childFixture(signers);
    fxERC1155 = fixture.erc1155Token;
    fxERC1155ChildTunnel = fixture.erc1155;

    await fxERC1155.mint(await wallet.getAddress(), 0, 100, "0x");
  });

  it("uri, fxManager, connectedToken", async () => {
    expect(await fxERC1155.uri(0)).to.eq("https://");
    expect(await fxERC1155.fxManager()).to.eq(await wallet.getAddress());
    expect(await fxERC1155.connectedToken()).to.eq(
      fxERC1155ChildTunnel.address
    );
  });

  it("initialize:fail", async () => {
    await expect(
      fxERC1155.initialize(
        await other.getAddress(),
        fxERC1155ChildTunnel.address,
        "https://new"
      )
    ).to.be.revertedWith("Token is already initialized");
  });

  it("setmetadata:fail", async () => {
    await expect(
      fxERC1155.connect(other).setupMetaData("https://new")
    ).to.be.revertedWith("Invalid sender");
  });

  it("setmetadata", async () => {
    await fxERC1155.setupMetaData("https://new");
    expect(await fxERC1155.uri(0)).to.eq("https://new");
  });

  it("mint:fail", async () => {
    await expect(
      fxERC1155.connect(other).mint(await wallet.getAddress(), 0, 1, "0x")
    ).to.be.revertedWith("Invalid sender");
  });

  it("mintBatch:fail - invalid sender", async () => {
    await expect(
      fxERC1155
        .connect(other)
        .mintBatch(await wallet.getAddress(), [0, 1], [1, 1], "0x")
    ).to.be.revertedWith("Invalid sender");
  });

  it("mintBatch:fail - length mismatch", async () => {
    await expect(
      fxERC1155.mintBatch(await wallet.getAddress(), [0, 1], [1], "0x")
    ).to.be.revertedWith("ERC1155: ids and amounts length mismatch");
  });

  it("burnBatch:fail - invalid sender", async () => {
    await expect(
      fxERC1155.connect(other).burnBatch(await wallet.getAddress(), [0], [1])
    ).to.be.revertedWith("Invalid sender");
  });

  it("burnBatch:fail - length mismatch", async () => {
    await expect(
      fxERC1155.burnBatch(await wallet.getAddress(), [0], [1, 2])
    ).to.be.revertedWith("ERC1155: ids and amounts length mismatch");
  });

  it("burnBatch:fail - length mismatch", async () => {
    await expect(
      fxERC1155.burnBatch(await wallet.getAddress(), [0, 1], [1, 2])
    ).to.be.revertedWith("ERC1155: burn amount exceeds balance");
  });

  it("approve", async () => {
    await expect(fxERC1155.setApprovalForAll(await other.getAddress(), true))
      .to.emit(fxERC1155, "ApprovalForAll")
      .withArgs(await wallet.getAddress(), await other.getAddress(), true);
    expect(
      await fxERC1155.isApprovedForAll(
        await wallet.getAddress(),
        await other.getAddress()
      )
    ).to.eq(true);
  });

  it("transferFrom:fail", async () => {
    await expect(
      fxERC1155.safeTransferFrom(
        await wallet.getAddress(),
        await other.getAddress(),
        0,
        200,
        "0x"
      )
    ).to.be.revertedWith("ERC1155: insufficient balance for transfer");
    await expect(
      fxERC1155
        .connect(other)
        .safeTransferFrom(
          await wallet.getAddress(),
          await other.getAddress(),
          0,
          10,
          "0x"
        )
    ).to.be.revertedWith("ERC1155: caller is not owner nor approved");
  });

  it("transferFrom:success - from owner", async () => {
    await expect(
      fxERC1155.safeTransferFrom(
        await wallet.getAddress(),
        await other.getAddress(),
        0,
        50,
        "0x"
      )
    )
      .to.emit(fxERC1155, "TransferSingle")
      .withArgs(
        await wallet.getAddress(),
        await wallet.getAddress(),
        await other.getAddress(),
        0,
        50
      );
  });

  it("transferFrom:success - after approve", async () => {
    await expect(fxERC1155.setApprovalForAll(await other.getAddress(), true))
      .to.emit(fxERC1155, "ApprovalForAll")
      .withArgs(await wallet.getAddress(), await other.getAddress(), true);
    expect(
      await fxERC1155.isApprovedForAll(
        await wallet.getAddress(),
        await other.getAddress()
      )
    ).to.eq(true);

    await expect(
      fxERC1155
        .connect(other)
        .safeTransferFrom(
          await wallet.getAddress(),
          await other.getAddress(),
          0,
          50,
          "0x"
        )
    )
      .to.emit(fxERC1155, "TransferSingle")
      .withArgs(
        await other.getAddress(),
        await wallet.getAddress(),
        await other.getAddress(),
        0,
        50
      );
  });

  it("mint:success", async () => {
    await expect(fxERC1155.mint(await wallet.getAddress(), 0, 30, "0x"))
      .to.emit(fxERC1155, "TransferSingle")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        0,
        30
      );
  });

  it("mintBatch:success - invalid sender", async () => {
    await expect(
      fxERC1155.mintBatch(await wallet.getAddress(), [0, 1], [100, 100], "0x")
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        [0, 1],
        [100, 100]
      );
  });

  it("safeBatchTransferFrom:success - from owner", async () => {
    await expect(
      fxERC1155.mintBatch(await wallet.getAddress(), [0, 1], [100, 100], "0x")
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        [0, 1],
        [100, 100]
      );
    await expect(
      fxERC1155.safeBatchTransferFrom(
        await wallet.getAddress(),
        await other.getAddress(),
        [0, 1],
        [10, 10],
        "0x"
      )
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await wallet.getAddress(),
        await wallet.getAddress(),
        await other.getAddress(),
        [0, 1],
        [10, 10]
      );
  });

  it("safeBatchTransferFrom:success - after approve", async () => {
    await expect(
      fxERC1155.mintBatch(await wallet.getAddress(), [0, 1], [100, 100], "0x")
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        [0, 1],
        [100, 100]
      );

    await expect(fxERC1155.setApprovalForAll(await other.getAddress(), true))
      .to.emit(fxERC1155, "ApprovalForAll")
      .withArgs(await wallet.getAddress(), await other.getAddress(), true);
    expect(
      await fxERC1155.isApprovedForAll(
        await wallet.getAddress(),
        await other.getAddress()
      )
    ).to.eq(true);

    await expect(
      fxERC1155
        .connect(other)
        .safeBatchTransferFrom(
          await wallet.getAddress(),
          await other.getAddress(),
          [0, 1],
          [10, 10],
          "0x"
        )
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await other.getAddress(),
        await wallet.getAddress(),
        await other.getAddress(),
        [0, 1],
        [10, 10]
      );
  });

  it("burn:success", async () => {
    await expect(fxERC1155.burn(await wallet.getAddress(), 0, 10))
      .to.emit(fxERC1155, "TransferSingle")
      .withArgs(
        await wallet.getAddress(),
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        0,
        10
      );
    expect(await fxERC1155.balanceOf(await wallet.getAddress(), 0)).to.eq(90);
  });

  it("burnBatch:success", async () => {
    await expect(
      fxERC1155.mintBatch(await wallet.getAddress(), [0, 1], [100, 100], "0x")
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        await wallet.getAddress(),
        [0, 1],
        [100, 100]
      );

    await expect(
      fxERC1155.burnBatch(await wallet.getAddress(), [0, 1], [10, 10])
    )
      .to.emit(fxERC1155, "TransferBatch")
      .withArgs(
        await wallet.getAddress(),
        await wallet.getAddress(),
        "0x0000000000000000000000000000000000000000",
        [0, 1],
        [10, 10]
      );
    expect(await fxERC1155.balanceOf(await wallet.getAddress(), 0)).to.eq(190);
    expect(await fxERC1155.balanceOf(await wallet.getAddress(), 1)).to.eq(90);
  });
});
