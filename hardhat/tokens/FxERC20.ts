import chai, { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { expandTo18Decimals } from "../shared/utilities";
import { childFixture } from "../shared/fixtures";
import { FxERC20 } from "../../types/FxERC20";
import { FxERC20ChildTunnel } from "../../types/FxERC20ChildTunnel";

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

interface ChildFixture {
  erc20Token: FxERC20;
  erc20: FxERC20ChildTunnel;
}

describe("FxERC20", () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC20: FxERC20;
  let fxERC20ChildTunnel: FxERC20ChildTunnel;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const fixture: ChildFixture = await childFixture(signers);
    fxERC20 = fixture.erc20Token;
    fxERC20ChildTunnel = fixture.erc20;

    await fxERC20.mint(await wallet.getAddress(), TOTAL_SUPPLY);
  });

  it("name, symbol, decimals, totalSupply, balanceOf", async () => {
    expect(await fxERC20.name()).to.eq("FxERC20");
    expect(await fxERC20.symbol()).to.eq("FE2");
    expect(await fxERC20.decimals()).to.eq(18);
    expect(await fxERC20.totalSupply()).to.eq(TOTAL_SUPPLY);
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      TOTAL_SUPPLY
    );
  });

  it("fxManager, connectedToken", async () => {
    expect(await fxERC20.fxManager()).to.eq(await wallet.getAddress());
    expect(await fxERC20.connectedToken()).to.eq(fxERC20ChildTunnel.address);
  });

  it("initialize:fail", async () => {
    await expect(
      fxERC20.initialize(
        await other.getAddress(),
        fxERC20ChildTunnel.address,
        "New Name",
        "New Symbol",
        18
      )
    ).to.be.revertedWith("Token is already initialized");
  });

  it("setmetadata:fail", async () => {
    await expect(
      fxERC20.connect(other).setupMetaData("New Name", "New Symbol", 18)
    ).to.be.revertedWith("Invalid sender");
  });

  it("setmetadata", async () => {
    await fxERC20.setupMetaData("New Name", "New Symbol", 18);
    expect(await fxERC20.name()).to.eq("New Name");
    expect(await fxERC20.symbol()).to.eq("New Symbol");
    expect(await fxERC20.decimals()).to.eq(18);
  });

  it("mint:fail", async () => {
    await expect(
      fxERC20.connect(other).mint(await wallet.getAddress(), TOTAL_SUPPLY)
    ).to.be.revertedWith("Invalid sender");
  });

  it("burn:fail", async () => {
    await expect(
      fxERC20.connect(other).burn(await other.getAddress(), TOTAL_SUPPLY)
    ).to.be.revertedWith("Invalid sender");
  });

  it("approve", async () => {
    await expect(fxERC20.approve(await other.getAddress(), TEST_AMOUNT))
      .to.emit(fxERC20, "Approval")
      .withArgs(
        await wallet.getAddress(),
        await other.getAddress(),
        TEST_AMOUNT
      );
    expect(
      await fxERC20.allowance(
        await wallet.getAddress(),
        await other.getAddress()
      )
    ).to.eq(TEST_AMOUNT);
  });

  it("transfer", async () => {
    await expect(fxERC20.transfer(await other.getAddress(), TEST_AMOUNT))
      .to.emit(fxERC20, "Transfer")
      .withArgs(
        await wallet.getAddress(),
        await other.getAddress(),
        TEST_AMOUNT
      );
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      TOTAL_SUPPLY.sub(TEST_AMOUNT)
    );
    expect(await fxERC20.balanceOf(await other.getAddress())).to.eq(
      TEST_AMOUNT
    );
  });

  it("transfer:fail", async () => {
    await expect(
      fxERC20.transfer(await other.getAddress(), TOTAL_SUPPLY.add(1))
    ).to.be.reverted; // ds-math-sub-underflow
    await expect(fxERC20.connect(other).transfer(await wallet.getAddress(), 1))
      .to.be.reverted; // ds-math-sub-underflow
  });

  it("transferFrom", async () => {
    await fxERC20.approve(await other.getAddress(), TEST_AMOUNT);
    await expect(
      fxERC20
        .connect(other)
        .transferFrom(
          await wallet.getAddress(),
          await other.getAddress(),
          TEST_AMOUNT
        )
    )
      .to.emit(fxERC20, "Transfer")
      .withArgs(
        await wallet.getAddress(),
        await other.getAddress(),
        TEST_AMOUNT
      );
    expect(
      await fxERC20.allowance(
        await wallet.getAddress(),
        await other.getAddress()
      )
    ).to.eq(0);
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      TOTAL_SUPPLY.sub(TEST_AMOUNT)
    );
    expect(await fxERC20.balanceOf(await other.getAddress())).to.eq(
      TEST_AMOUNT
    );
  });

  it("transferFrom:max", async () => {
    await fxERC20.approve(
      await other.getAddress(),
      ethers.constants.MaxUint256
    );
    await expect(
      fxERC20
        .connect(other)
        .transferFrom(
          await wallet.getAddress(),
          await other.getAddress(),
          TEST_AMOUNT
        )
    )
      .to.emit(fxERC20, "Transfer")
      .withArgs(
        await wallet.getAddress(),
        await other.getAddress(),
        TEST_AMOUNT
      );
    expect(
      await fxERC20.allowance(
        await wallet.getAddress(),
        await other.getAddress()
      )
    ).to.eq(ethers.constants.MaxUint256.sub(TEST_AMOUNT));
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      TOTAL_SUPPLY.sub(TEST_AMOUNT)
    );
    expect(await fxERC20.balanceOf(await other.getAddress())).to.eq(
      TEST_AMOUNT
    );
  });

  it("burn", async () => {
    await fxERC20.burn(await wallet.getAddress(), TEST_AMOUNT);
    expect(await fxERC20.balanceOf(await wallet.getAddress())).to.eq(
      TOTAL_SUPPLY.sub(TEST_AMOUNT)
    );
  });
});
