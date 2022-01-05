import { Contract, Signer } from 'ethers';
import { expandTo18Decimals } from './utilities';
import { FxChild } from '../../types/FxChild';
import { FxChild__factory } from '../../types/factories/FxChild__factory';
import { FxERC20 } from '../../types/FxERC20';
import { FxERC20__factory } from '../../types/factories/FxERC20__factory';
import { FxERC20ChildTunnel } from '../../types/FxERC20ChildTunnel';
import { FxERC20ChildTunnel__factory } from '../../types/factories/FxERC20ChildTunnel__factory';
import { FxERC721 } from '../../types/FxERC721';
import { FxERC721__factory } from '../../types/factories/FxERC721__factory';
import { FxERC721ChildTunnel } from '../../types/FxERC721ChildTunnel';
import { FxERC721ChildTunnel__factory } from '../../types/factories/FxERC721ChildTunnel__factory';
import { FxERC1155 } from '../../types/FxERC1155';
import { FxERC1155__factory } from '../../types/factories/FxERC1155__factory';
import { FxERC1155ChildTunnel } from '../../types/FxERC1155ChildTunnel';
import { FxERC1155ChildTunnel__factory } from '../../types/factories/FxERC1155ChildTunnel__factory';

import { FxRoot } from '../../types/FxRoot';
import { FxRoot__factory } from '../../types/factories/FxRoot__factory';
import { FxERC20RootTunnel } from '../../types/FxERC20RootTunnel';
import { FxERC20RootTunnel__factory } from '../../types/factories/FxERC20RootTunnel__factory';
import { FxERC721RootTunnel } from '../../types/FxERC721RootTunnel';
import { FxERC721RootTunnel__factory } from '../../types/factories/FxERC721RootTunnel__factory';
import { FxERC1155RootTunnel } from '../../types/FxERC1155RootTunnel';
import { FxERC1155RootTunnel__factory } from '../../types/factories/FxERC1155RootTunnel__factory';

import { StateSender } from '../../types/StateSender';
import { StateSender__factory } from '../../types/factories/StateSender__factory';
import { StateReceiver } from '../../types/StateReceiver';
import { StateReceiver__factory } from '../../types/factories/StateReceiver__factory';

const TOTAL_SUPPLY = expandTo18Decimals(10000);

interface ChildFixture {
  fxChild: FxChild;
  erc20Token: FxERC20;
  erc20: FxERC20ChildTunnel;
  erc721Token: FxERC721;
  erc721: FxERC721ChildTunnel;
  erc1155Token: FxERC1155;
  erc1155: FxERC1155ChildTunnel;
}

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

const overrides = {
  gasLimit: 9999999,
  gasPrice: 875000000,
};

export async function tunnelFixture([wallet]: Signer[]): Promise<TunnelFixture> {
  
  const fxChild = await new FxChild__factory(wallet).deploy(overrides);

  const stateReceiver = await new StateReceiver__factory(wallet).deploy(fxChild.address, overrides);

  const erc20Token = await new FxERC20__factory(wallet).deploy(overrides);
  const erc20 = await new FxERC20ChildTunnel__factory(wallet).deploy(fxChild.address, erc20Token.address, overrides);
  await erc20Token.initialize(await wallet.getAddress(), erc20.address, "FxERC20", "FE2", 18);

  const erc721Token = await new FxERC721__factory(wallet).deploy(overrides);
  const erc721 = await new FxERC721ChildTunnel__factory(wallet).deploy(fxChild.address, erc721Token.address, overrides);
  await erc721Token.initialize(await wallet.getAddress(), erc721.address, "FxERC721", "FE7");

  const erc1155Token = await new FxERC1155__factory(wallet).deploy(overrides);
  const erc1155 = await new FxERC1155ChildTunnel__factory(wallet).deploy(fxChild.address, erc1155Token.address, overrides);
  await erc1155Token.initialize(await wallet.getAddress(), erc1155.address, "https://");

  return { 
    fxChild,
    erc20Token,
    erc20,
    erc721Token,
    erc721,
    erc1155Token,
    erc1155,
    stateReceiver
  };
}

export async function childFixture([wallet]: Signer[]): Promise<ChildFixture> {
  
  const fxChild = await new FxChild__factory(wallet).deploy(overrides);

  const erc20Token = await new FxERC20__factory(wallet).deploy(overrides);
  const erc20 = await new FxERC20ChildTunnel__factory(wallet).deploy(fxChild.address, erc20Token.address, overrides);
  await erc20Token.initialize(await wallet.getAddress(), erc20.address, "FxERC20", "FE2", 18);

  const erc721Token = await new FxERC721__factory(wallet).deploy(overrides);
  const erc721 = await new FxERC721ChildTunnel__factory(wallet).deploy(fxChild.address, erc721Token.address, overrides);
  await erc721Token.initialize(await wallet.getAddress(), erc721.address, "FxERC721", "FE7");

  const erc1155Token = await new FxERC1155__factory(wallet).deploy(overrides);
  const erc1155 = await new FxERC1155ChildTunnel__factory(wallet).deploy(fxChild.address, erc1155Token.address, overrides);
  await erc1155Token.initialize(await wallet.getAddress(), erc1155.address, "https://");

  return { 
    fxChild,
    erc20Token,
    erc20,
    erc721Token,
    erc721,
    erc1155Token,
    erc1155
  };
}

export async function rootFixture([wallet]: Signer[], cFixture: ChildFixture, ): Promise<RootFixture> {
  const checkpointManager: string = "0x600e7E2B520D51a7FE5e404E73Fb0D98bF2A913E";
  const stateSender: string = "0x600e7E2B520D51a7FE5e404E73Fb0D98bF2A913E";
  // const fxERC20, fxERC721, fxERC1155;

  const { 
    fxChild,
    erc20Token: fxERC20,
    erc20: fxERC20ChildTunnel,
    erc721Token: fxERC721,
    erc721: fxERC721ChildTunnel,
    erc1155Token: fxERC1155,
    erc1155: fxERC1155ChildTunnel
  } = cFixture;

  const fxRoot = await new FxRoot__factory(wallet).deploy(stateSender, overrides);
  await fxChild.setFxRoot(fxRoot.address);
  await fxRoot.setFxChild(fxChild.address);

  const erc20 = await new FxERC20RootTunnel__factory(wallet).deploy(checkpointManager, fxRoot.address, fxERC20.address, overrides);
  const setERC20Child = await erc20.setFxChildTunnel(fxERC20ChildTunnel.address)
  // console.log(setERC20Child)
  await setERC20Child.wait()
  console.log('ERC20ChildTunnel set')

  const erc721 = await new FxERC721RootTunnel__factory(wallet).deploy(checkpointManager, fxRoot.address, fxERC721.address, overrides);
  const setERC721Child = await erc721.setFxChildTunnel(fxERC721ChildTunnel.address)
  // console.log(setERC721Child)
  await setERC721Child.wait()
  console.log('ERC721ChildTunnel set')

  const erc1155 = await new FxERC1155RootTunnel__factory(wallet).deploy(checkpointManager, fxRoot.address, fxERC1155.address, overrides);
  const setERC1155Child = await erc1155.setFxChildTunnel(fxERC1155ChildTunnel.address)
  // console.log(setERC1155Child)
  await setERC1155Child.wait()
  console.log('ERC1155ChildTunnel set')
  
  return {
    fxRoot, 
    erc20,
    erc721,
    erc1155
  };
}
