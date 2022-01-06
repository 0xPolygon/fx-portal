import chai, { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { expandTo18Decimals } from '../../shared/utilities';
import { tunnelFixture } from '../../shared/fixtures';
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
import { StateReceiver } from '../../../types/StateReceiver';

chai.use(solidity);

const TOTAL_SUPPLY = expandTo18Decimals(10000);
const TEST_AMOUNT = expandTo18Decimals(10);

interface TunnelFixture {
  fxChild: FxChild;
  erc20Token: FxERC20;
  erc20: FxERC20ChildTunnel;
  erc721Token: FxERC721;
  erc721: FxERC721ChildTunnel;
  erc1155Token: FxERC1155;
  erc1155: FxERC1155ChildTunnel;
  stateReceiver: StateReceiver;
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
  let stateReceiver: StateReceiver;

  beforeEach(async () => {
    const signers = await ethers.getSigners();
    wallet = signers[0];
    other = signers[1];
    const tFixture: TunnelFixture = await tunnelFixture(signers);
    fxChild = tFixture.fxChild;
    fxERC20 = tFixture.erc20Token;
    fxERC20ChildTunnel = tFixture.erc20;
    stateReceiver = tFixture.stateReceiver;
    
    const rFixture: RootFixture = await rootFixture(signers, tFixture);
    fxRoot = rFixture.fxRoot;
    fxERC20RootTunnel = rFixture.erc20;
  
    await fxERC20.mint(await wallet.getAddress(), TOTAL_SUPPLY);
  });

  it('fxChild, template', async () => {
    expect(await fxERC20ChildTunnel.fxChild()).to.eq(fxChild.address);
    expect(await fxERC20ChildTunnel.tokenTemplate()).to.eq(fxERC20.address);
    expect(await fxERC20ChildTunnel.fxRootTunnel()).to.eq(fxERC20RootTunnel.address);
  });

  it('onStateRecieve map token: success', async () => {
    const receiver = fxERC20ChildTunnel.address;
    const rootMessageSender = fxERC20RootTunnel.address;
    const syncType = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("DEPOSIT"));
    const rootToken = fxERC20.address;
    const name = 'FxERC20';
    const symbol = 'FE2';
    const decimals = 18;
    const abiCoder = ethers.utils.defaultAbiCoder;
    const syncData = abiCoder.encode(['address', 'string', 'string', 'uint8'], [rootToken, name.toString(), symbol.toString(), decimals]);
    const message = abiCoder.encode(['bytes32', 'bytes'], [syncType, syncData])
    // console.log(syncData);
    // console.log(message);
    const stateData = abiCoder.encode(['address', 'address', 'bytes'], [rootMessageSender, receiver, message]);
    // console.log(stateData);
    // await fxERC20ChildTunnel.processMessageFromRoot(0, rootMessageSender, message);
    // await fxChild.onStateReceive(0, stateData);
    console.log("========================================")
    console.log(fxERC20ChildTunnel.address);
    console.log(fxERC20RootTunnel.address);
    console.log(message);
    console.log("========================================")
    await stateReceiver.receiveState(0, stateData);
    // (address rootToken, string memory name, string memory symbol, uint8 decimals) = abi.decode(syncData, (address, string, string, uint8));
    // (address rootMessageSender, address receiver, bytes memory data) = abi.decode(_data, (address, address, bytes));
    // syncState = abi.encode(['bytes32', 'bytes'], [syncType, syncData])
  })
});
