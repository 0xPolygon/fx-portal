import chai, { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { expandTo18Decimals } from '../shared/utilities';
import { getCreate2Address } from '../shared/utilities';
import { childFixture } from '../shared/fixtures';
import { FxERC20 } from '../../types/FxERC20';
import { FxERC20__factory } from '../../types/factories/FxERC20__factory';
import { FxERC721 } from '../../types/FxERC721';
import { FxERC1155 } from '../../types/FxERC1155';
import { FxERC20ChildTunnel } from '../../types/FxERC20ChildTunnel';
import { FxERC721ChildTunnel } from '../../types/FxERC721ChildTunnel';
import { FxERC1155ChildTunnel } from '../../types/FxERC1155ChildTunnel';
import { FxMintableERC20ChildTunnel } from '../../types/FxMintableERC20ChildTunnel';
import { FxMintableERC20RootTunnel } from '../../types/FxMintableERC20RootTunnel';
import { rootFixture } from '../shared/fixtures';
import { FxChildTest } from '../../types/FxChildTest';
import { FxRoot } from '../../types/FxRoot';
import { FxERC20RootTunnel } from '../../types/FxERC20RootTunnel';
import { FxERC721RootTunnel } from '../../types/FxERC721RootTunnel';
import { FxERC1155RootTunnel } from '../../types/FxERC1155RootTunnel';
import { StateReceiver } from '../../types/StateReceiver';
import { StateSender } from '../../types/StateSender';

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

interface ChildFixture {
  fxChild: FxChildTest;
  erc20Token: FxERC20;
  erc20: FxERC20ChildTunnel;
  erc721Token: FxERC721;
  mintableERC20Token: FxERC20;
  erc721: FxERC721ChildTunnel;
  erc1155Token: FxERC1155;
  erc1155: FxERC1155ChildTunnel;
  mintableErc20: FxMintableERC20ChildTunnel;
  stateReceiver: StateReceiver;
}

interface RootFixture {
  fxRoot: FxRoot;
  erc20: FxERC20RootTunnel;
  erc721: FxERC721RootTunnel;
  erc1155: FxERC1155RootTunnel;
  mintableErc20: FxMintableERC20RootTunnel;
  stateSender: StateSender;
}

describe('FxERC20Tunnel', () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC20: FxERC20;
  let fxMintableERC20ChildTunnel: FxMintableERC20ChildTunnel;
  let fxMintableERC20RootTunnel: FxMintableERC20RootTunnel;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxERC20 = cFixture.erc20Token;
    fxMintableERC20ChildTunnel = cFixture.mintableErc20;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxMintableERC20RootTunnel = rFixture.mintableErc20;

    await fxERC20.mint(await wallet.getAddress(), TOTAL_SUPPLY);
  });

  it('fxChild, deployToken success', async () => {
    const uniqueId = 0;
    let childTokenMap = await fxMintableERC20ChildTunnel.rootToChildToken(fxERC20.address);
    let rootTokenMap = await fxMintableERC20RootTunnel.rootToChildTokens(fxERC20.address);

    expect(childTokenMap).to.eq(rootTokenMap);
    expect(childTokenMap).to.eq("0x0000000000000000000000000000000000000000");

    await expect(fxMintableERC20ChildTunnel.deployChildToken(uniqueId, await fxERC20.name(), await fxERC20.symbol(), await fxERC20.decimals()))
      .to.emit(fxMintableERC20ChildTunnel, 'TokenMapped');

    childTokenMap = await fxMintableERC20ChildTunnel.rootToChildToken(fxERC20.address);
    console.log(childTokenMap);  
  });

  it('fxChild, deployToken fail - id is already used', async () => {
    const uniqueId = 0;
    await fxMintableERC20ChildTunnel.deployChildToken(uniqueId, "FxMintableRC20 Child Token", "FMCT", 18);
    await expect(fxMintableERC20ChildTunnel.deployChildToken(uniqueId, "FxMintableRC20 Child Token", "FMCT", 18))
      .revertedWith('Create2: Failed on minimal deploy');
  });

  it('fxChild, mintToken fail - not mapped', async () => {
    const amountToMint = expandTo18Decimals(10);
    await expect(fxMintableERC20ChildTunnel.mintToken(fxERC20.address, amountToMint)).to.be.revertedWith(
      "FxMintableERC20ChildTunnel: NO_MAPPED_TOKEN"
    )
  });
});
