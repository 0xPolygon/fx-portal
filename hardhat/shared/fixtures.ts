import { Signer } from "ethers";
import { expandTo18Decimals } from "./utilities";
import { FxChildTest } from "../../types/FxChildTest";
import { FxChildTest__factory } from "../../types/factories/FxChildTest__factory";
import { FxERC20 } from "../../types/FxERC20";
import { FxERC20__factory } from "../../types/factories/FxERC20__factory";
import { FxERC20ChildTunnel } from "../../types/FxERC20ChildTunnel";
import { FxERC20ChildTunnel__factory } from "../../types/factories/FxERC20ChildTunnel__factory";
import { FxERC721 } from "../../types/FxERC721";
import { FxERC721__factory } from "../../types/factories/FxERC721__factory";
import { FxERC721ChildTunnel } from "../../types/FxERC721ChildTunnel";
import { FxERC721ChildTunnel__factory } from "../../types/factories/FxERC721ChildTunnel__factory";
import { FxERC1155 } from "../../types/FxERC1155";
import { FxERC1155__factory } from "../../types/factories/FxERC1155__factory";
import { FxERC1155ChildTunnel } from "../../types/FxERC1155ChildTunnel";
import { FxERC1155ChildTunnel__factory } from "../../types/factories/FxERC1155ChildTunnel__factory";
import { FxMintableERC20ChildTunnel } from "../../types/FxMintableERC20ChildTunnel";
import { FxMintableERC20ChildTunnel__factory } from "../../types/factories/FxMintableERC20ChildTunnel__factory";
import { FxMintableERC20RootTunnel } from "../../types/FxMintableERC20RootTunnel";
import { FxMintableERC20RootTunnel__factory } from "../../types/factories/FxMintableERC20RootTunnel__factory";
import { FxMintableERC721ChildTunnel } from "../../types/FxMintableERC721ChildTunnel";
import { FxMintableERC721ChildTunnel__factory } from "../../types/factories/FxMintableERC721ChildTunnel__factory";
import { FxMintableERC721RootTunnel } from "../../types/FxMintableERC721RootTunnel";
import { FxMintableERC721RootTunnel__factory } from "../../types/factories/FxMintableERC721RootTunnel__factory";
import { FxMintableERC1155ChildTunnel } from "../../types/FxMintableERC1155ChildTunnel";
import { FxMintableERC1155ChildTunnel__factory } from "../../types/factories/FxMintableERC1155ChildTunnel__factory";
import { FxMintableERC1155RootTunnel } from "../../types/FxMintableERC1155RootTunnel";
import { FxMintableERC1155RootTunnel__factory } from "../../types/factories/FxMintableERC1155RootTunnel__factory";

import { FxMintableERC20 } from "../../types/FxMintableERC20";
import { FxMintableERC20__factory } from "../../types/factories/FxMintableERC20__factory";
import { FxMintableERC721 } from "../../types/FxMintableERC721";
import { FxMintableERC721__factory } from "../../types/factories/FxMintableERC721__factory";
import { FxMintableERC1155 } from "../../types/FxMintableERC1155";
import { FxMintableERC1155__factory } from "../../types/factories/FxMintableERC1155__factory";

import { FxRoot } from "../../types/FxRoot";
import { FxRoot__factory } from "../../types/factories/FxRoot__factory";
import { FxERC20RootTunnel } from "../../types/FxERC20RootTunnel";
import { FxERC20RootTunnel__factory } from "../../types/factories/FxERC20RootTunnel__factory";
import { FxERC721RootTunnel } from "../../types/FxERC721RootTunnel";
import { FxERC721RootTunnel__factory } from "../../types/factories/FxERC721RootTunnel__factory";
import { FxERC1155RootTunnel } from "../../types/FxERC1155RootTunnel";
import { FxERC1155RootTunnel__factory } from "../../types/factories/FxERC1155RootTunnel__factory";

import { StateSender } from "../../types/StateSender";
import { StateSender__factory } from "../../types/factories/StateSender__factory";
import { StateReceiver } from "../../types/StateReceiver";
import { StateReceiver__factory } from "../../types/factories/StateReceiver__factory";

import { MockCheckpointManager } from "../../types/MockCheckpointManager";
import { MockCheckpointManager__factory } from "../../types/factories/MockCheckpointManager__factory";
const TOTAL_SUPPLY = expandTo18Decimals(10000);

export interface ChildFixture {
  fxChild: FxChildTest;
  erc20Token: FxERC20;
  erc20: FxERC20ChildTunnel;
  erc721Token: FxERC721;
  erc721: FxERC721ChildTunnel;
  erc1155Token: FxERC1155;
  erc1155: FxERC1155ChildTunnel;
  mintableERC20Token: FxMintableERC20;
  mintableErc20: FxMintableERC20ChildTunnel;
  mintableERC721Token: FxMintableERC721;
  mintableErc721: FxMintableERC721ChildTunnel;
  mintableERC1155Token: FxMintableERC1155;
  mintableErc1155: FxMintableERC1155ChildTunnel;
  stateReceiver: StateReceiver;
}

export interface RootFixture {
  fxRoot: FxRoot;
  erc20: FxERC20RootTunnel;
  erc721: FxERC721RootTunnel;
  erc1155: FxERC1155RootTunnel;
  mintableErc20: FxMintableERC20RootTunnel;
  mintableErc721: FxMintableERC721RootTunnel;
  mintableErc1155: FxMintableERC1155RootTunnel;
  stateSender: StateSender;
  checkpointManager: MockCheckpointManager;
}

const overrides = {
  gasLimit: 9999999,
  gasPrice: 875000000,
};

export async function childFixture([wallet]: Signer[]): Promise<ChildFixture> {
  const fxChild = await new FxChildTest__factory(wallet).deploy(overrides);

  const stateReceiver = await new StateReceiver__factory(wallet).deploy(
    fxChild.address,
    overrides
  );

  const erc20Token = await new FxERC20__factory(wallet).deploy(overrides);
  const erc20 = await new FxERC20ChildTunnel__factory(wallet).deploy(
    fxChild.address,
    erc20Token.address,
    overrides
  );
  await erc20Token.initialize(
    await wallet.getAddress(),
    erc20.address,
    "FxERC20",
    "FE2",
    18
  );

  const erc721Token = await new FxERC721__factory(wallet).deploy(overrides);
  const erc721 = await new FxERC721ChildTunnel__factory(wallet).deploy(
    fxChild.address,
    erc721Token.address,
    overrides
  );
  await erc721Token.initialize(
    await wallet.getAddress(),
    erc721.address,
    "FxERC721",
    "FE7"
  );

  const erc1155Token = await new FxERC1155__factory(wallet).deploy(overrides);
  const erc1155 = await new FxERC1155ChildTunnel__factory(wallet).deploy(
    fxChild.address,
    erc1155Token.address,
    overrides
  );
  await erc1155Token.initialize(
    await wallet.getAddress(),
    erc1155.address,
    "https://"
  );

  const mintableERC20Token = await new FxMintableERC20__factory(wallet).deploy(
    overrides
  );

  const mintableErc20 = await new FxMintableERC20ChildTunnel__factory(
    wallet
  ).deploy(
    fxChild.address,
    mintableERC20Token.address,
    erc20Token.address,
    overrides
  );
  await mintableERC20Token.initialize(
    await wallet.getAddress(),
    mintableErc20.address,
    "FxMintableERC20",
    "FM2",
    18,
    await wallet.getAddress() // minter
  );

  const mintableERC721Token = await new FxMintableERC721__factory(
    wallet
  ).deploy(overrides);

  const mintableErc721 = await new FxMintableERC721ChildTunnel__factory(
    wallet
  ).deploy(
    fxChild.address,
    mintableERC721Token.address,
    erc721Token.address,
    overrides
  );
  await mintableERC721Token.initialize(
    await wallet.getAddress(),
    mintableErc721.address,
    "FxMintableERC721",
    "FM2",
    await wallet.getAddress() // minter
  );

  const mintableERC1155Token = await new FxMintableERC1155__factory(
    wallet
  ).deploy(overrides);

  const mintableErc1155 = await new FxMintableERC1155ChildTunnel__factory(
    wallet
  ).deploy(
    fxChild.address,
    mintableERC1155Token.address,
    erc1155Token.address,
    overrides
  );
  await mintableERC1155Token.initialize(
    await wallet.getAddress(),
    mintableErc1155.address,
    "ipfs://",
    await wallet.getAddress() // minter
  );

  return {
    fxChild,
    erc20Token,
    erc20,
    erc721Token,
    erc721,
    erc1155Token,
    erc1155,
    mintableERC20Token,
    mintableErc20,
    stateReceiver,
    mintableErc1155,
    mintableERC1155Token,
    mintableErc721,
    mintableERC721Token,
  };
}

export async function rootFixture(
  [wallet]: Signer[],
  cFixture: ChildFixture
): Promise<RootFixture> {
  const checkpointManager = await new MockCheckpointManager__factory(
    wallet
  ).deploy(overrides);

  const {
    fxChild,
    erc20Token: fxERC20,
    erc20: fxERC20ChildTunnel,
    erc721Token: fxERC721,
    erc721: fxERC721ChildTunnel,
    erc1155Token: fxERC1155,
    erc1155: fxERC1155ChildTunnel,
    mintableErc20: fxMintableERC20ChildTunnel,
    mintableErc721: fxMintableERC721ChildTunnel,
    mintableErc1155: fxMintableERC1155ChildTunnel,
    stateReceiver,
  } = cFixture;

  const stateSender = await new StateSender__factory(wallet).deploy(
    stateReceiver.address,
    overrides
  );

  const fxRoot = await new FxRoot__factory(wallet).deploy(
    stateSender.address,
    overrides
  );
  await fxChild.setFxRoot(fxRoot.address);
  await fxRoot.setFxChild(fxChild.address);

  const erc20 = await new FxERC20RootTunnel__factory(wallet).deploy(
    checkpointManager.address,
    fxRoot.address,
    fxERC20.address,
    overrides
  );
  const setERC20Child = await erc20.setFxChildTunnel(
    fxERC20ChildTunnel.address
  );
  await setERC20Child.wait();

  const setERC20Root = await fxERC20ChildTunnel.setFxRootTunnel(erc20.address);
  await setERC20Root.wait();

  const erc721 = await new FxERC721RootTunnel__factory(wallet).deploy(
    checkpointManager.address,
    fxRoot.address,
    fxERC721.address,
    overrides
  );
  const setERC721Child = await erc721.setFxChildTunnel(
    fxERC721ChildTunnel.address
  );
  await setERC721Child.wait();

  const setERC721Root = await fxERC721ChildTunnel.setFxRootTunnel(
    erc721.address
  );
  await setERC721Root.wait();

  const erc1155 = await new FxERC1155RootTunnel__factory(wallet).deploy(
    checkpointManager.address,
    fxRoot.address,
    fxERC1155.address,
    overrides
  );
  const setERC1155Child = await erc1155.setFxChildTunnel(
    fxERC1155ChildTunnel.address
  );
  await setERC1155Child.wait();

  const setERC1155Root = await fxERC1155ChildTunnel.setFxRootTunnel(
    erc1155.address
  );
  await setERC1155Root.wait();

  const mintableErc20 = await new FxMintableERC20RootTunnel__factory(
    wallet
  ).deploy(
    checkpointManager.address,
    fxRoot.address,
    fxERC20.address,
    overrides
  );
  const setMintableERC20Child = await mintableErc20.setFxChildTunnel(
    fxMintableERC20ChildTunnel.address
  );
  await setMintableERC20Child.wait();

  const setMintableERC20Root = await fxMintableERC20ChildTunnel.setFxRootTunnel(
    mintableErc20.address
  );
  await setMintableERC20Root.wait();

  const mintableErc721 = await new FxMintableERC721RootTunnel__factory(
    wallet
  ).deploy(
    checkpointManager.address,
    fxRoot.address,
    fxERC721.address,
    overrides
  );
  const setMintableERC721Child = await mintableErc721.setFxChildTunnel(
    fxMintableERC721ChildTunnel.address
  );
  await setMintableERC721Child.wait();

  const setMintableERC721Root =
    await fxMintableERC721ChildTunnel.setFxRootTunnel(mintableErc721.address);
  await setMintableERC721Root.wait();

  const mintableErc1155 = await new FxMintableERC1155RootTunnel__factory(
    wallet
  ).deploy(
    checkpointManager.address,
    fxRoot.address,
    fxERC1155.address,
    overrides
  );
  const setMintableERC1155Child = await mintableErc1155.setFxChildTunnel(
    fxMintableERC1155ChildTunnel.address
  );
  await setMintableERC1155Child.wait();

  const setMintableERC1155Root =
    await fxMintableERC1155ChildTunnel.setFxRootTunnel(mintableErc1155.address);
  await setMintableERC1155Root.wait();

  return {
    fxRoot,
    erc20,
    erc721,
    erc1155,
    mintableErc20,
    stateSender,
    checkpointManager,
    mintableErc1155,
    mintableErc721,
  };
}
