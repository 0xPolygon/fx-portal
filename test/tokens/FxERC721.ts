import chai, { expect } from 'chai';
import { Signer, BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { expandTo18Decimals } from '../shared/utilities';
import { childFixture } from '../shared/fixtures';
import { FxERC721 } from '../../types/FxERC721';
import { FxERC721ChildTunnel } from '../../types/FxERC721ChildTunnel';

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

interface ChildFixture {
  erc721Token: FxERC721;
  erc721: FxERC721ChildTunnel;
}

describe('FxERC721', () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC721: FxERC721;
  let fxERC721ChildTunnel: FxERC721ChildTunnel;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const fixture: ChildFixture = await childFixture(signers);
    fxERC721 = fixture.erc721Token;
    fxERC721ChildTunnel = fixture.erc721;

    await fxERC721.mint(await wallet.getAddress(), 0, "0x");
  });

  it('name, symbol, decimals, totalSupply, balanceOf', async () => {
    expect(await fxERC721.name()).to.eq('FxERC721');
    expect(await fxERC721.symbol()).to.eq('FE7');
    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(1);
  });

  it('fxManager, connectedToken', async () => {
    expect(await fxERC721.fxManager()).to.eq(await wallet.getAddress());
    expect(await fxERC721.connectedToken()).to.eq(fxERC721ChildTunnel.address);
  });

  it('initialize:fail', async () => {
    await expect(fxERC721.initialize(await other.getAddress(), fxERC721ChildTunnel.address, "New Name", "New Symbol"))
      .to.be.revertedWith('Token is already initialized');
  })

  it('setmetadata:fail', async () => {
    await expect(fxERC721.connect(other).setupMetaData("New Name", "New Symbol"))
      .to.be.revertedWith('Invalid sender');
  })

  it('setmetadata', async () => {
    await fxERC721.setupMetaData("New Name", "New Symbol");
    expect(await fxERC721.name()).to.eq('New Name');
    expect(await fxERC721.symbol()).to.eq('New Symbol');
  })

  it('mint:fail', async () => {
    await expect(fxERC721.connect(other).mint(await wallet.getAddress(), 1, "0x"))
      .to.be.revertedWith('Invalid sender');
  })

  it('burn:fail', async () => {
    await expect(fxERC721.connect(other).burn(0))
      .to.be.revertedWith('Invalid sender');
  })

  it('approve', async () => {
    const tokenId = 0;
    await expect(fxERC721.approve(await other.getAddress(), tokenId))
      .to.emit(fxERC721, 'Approval')
      .withArgs(await wallet.getAddress(), await other.getAddress(), tokenId);
    expect(await fxERC721.getApproved(0)).to.eq(await other.getAddress());
  });

  it('transfer', async () => {
    await expect(fxERC721.transferFrom(await wallet.getAddress(), await other.getAddress(), 0))
      .to.emit(fxERC721, 'Transfer')
      .withArgs(await wallet.getAddress(), await other.getAddress(), 0);
    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(0);
    expect(await fxERC721.balanceOf(await other.getAddress())).to.eq(1);
  });

  it('transfer:fail', async () => {
    await expect(fxERC721["safeTransferFrom(address,address,uint256)"](await wallet.getAddress(), await other.getAddress(), 1)).to.be.reverted; // ds-math-sub-underflow
    await expect(fxERC721.connect(other)["safeTransferFrom(address,address,uint256)"](await other.getAddress(), await wallet.getAddress(), 1)).to.be.reverted; // ds-math-sub-underflow
  });

  it('safeTransferFrom', async () => {
    await fxERC721.approve(await other.getAddress(), 0);
    expect(await fxERC721.getApproved(0)).to.eq(await other.getAddress());
    await expect(fxERC721.connect(other)["safeTransferFrom(address,address,uint256)"](await wallet.getAddress(), await other.getAddress(), 0))
      .to.emit(fxERC721, 'Transfer')
      .withArgs(await wallet.getAddress(), await other.getAddress(), 0);
    
    expect(await fxERC721.getApproved(0)).to.eq('0x0000000000000000000000000000000000000000');
    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(0);
    expect(await fxERC721.balanceOf(await other.getAddress())).to.eq(1);
  });

  it('mint:success', async () => {
    await expect(fxERC721.mint(await wallet.getAddress(), 1, "0x"))
      .to.emit(fxERC721, 'Transfer')
      .withArgs('0x0000000000000000000000000000000000000000', await wallet.getAddress(), 1);
    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(2);
  })

  it('burn', async () => {
    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(1);
    
    const tokenId = 0;
    await expect(await fxERC721.burn(tokenId))
      .to.emit(fxERC721, 'Transfer')
      .withArgs(await wallet.getAddress(), '0x0000000000000000000000000000000000000000', tokenId);
    
    expect(await fxERC721.balanceOf(await wallet.getAddress())).to.eq(0);
  });
});
