import chai, { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { expandTo18Decimals } from '../../shared/utilities';
import { childFixture } from '../../shared/fixtures';
import { FxERC20 } from '../../../types/FxERC20';
import { FxERC721 } from '../../../types/FxERC721';
import { FxERC1155 } from '../../../types/FxERC1155';
import { FxERC20ChildTunnel } from '../../../types/FxERC20ChildTunnel';
import { FxERC721ChildTunnel } from '../../../types/FxERC721ChildTunnel';
import { FxERC1155ChildTunnel } from '../../../types/FxERC1155ChildTunnel';
import { rootFixture } from '../../shared/fixtures';
import { FxChild } from '../../../types/FxChild';
import { FxRoot } from '../../../types/FxRoot';
import { FxERC20RootTunnel } from '../../../types/FxERC20RootTunnel';
import { FxERC721RootTunnel } from '../../../types/FxERC721RootTunnel';
import { FxERC1155RootTunnel } from '../../../types/FxERC1155RootTunnel';

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

interface ChildFixture {
  fxChild: FxChild;
  erc20Token: FxERC20;
  erc20: FxERC20ChildTunnel;
  erc721Token: FxERC721;
  erc721: FxERC721ChildTunnel;
  erc1155Token: FxERC1155;
  erc1155: FxERC1155ChildTunnel;
}

interface RootFixture {
  fxRoot: FxRoot;
  erc20: FxERC20RootTunnel;
  erc721: FxERC721RootTunnel;
  erc1155: FxERC1155RootTunnel;
}

describe('FxERC20', () => {
  let wallet: Signer;
  let other: Signer;
  let fxERC20: FxERC20;
  let fxERC20ChildTunnel: FxERC20ChildTunnel;
  let fxChild: FxChild;
  let fxRoot: FxRoot;
  let fxERC20RootTunnel: FxERC20RootTunnel;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const cFixture: ChildFixture = await childFixture(signers);
    fxChild = cFixture.fxChild;
    fxERC20 = cFixture.erc20Token;
    fxERC20ChildTunnel = cFixture.erc20;
    const rFixture: RootFixture = await rootFixture(signers, cFixture);
    fxRoot = rFixture.fxRoot;
    fxERC20RootTunnel = rFixture.erc20;

    await fxERC20.mint(await wallet.getAddress(), TOTAL_SUPPLY);
  });

  it('fxRoot, template', async () => {
    
  });
});
