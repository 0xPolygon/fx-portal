// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@utils/Test.sol";
import "@utils/Events.sol";
import {FxRoot} from "contracts/FxRoot.sol";
import {FxChild} from "contracts/FxChild.sol";
import {MockStateSender} from "../mock/StateSender.sol";
import {MockStateReceiver} from "../mock/StateReceiver.sol";

import {FxERC20ChildTunnel} from "contracts/examples/erc20-transfer/FxERC20ChildTunnel.sol";
import {FxERC20RootTunnel} from "contracts/examples/erc20-transfer/FxERC20RootTunnel.sol";
import {FxERC20} from "contracts/tokens/FxERC20.sol";

import {FxERC721ChildTunnel} from "contracts/examples/erc721-transfer/FxERC721ChildTunnel.sol";
import {FxERC721RootTunnel} from "contracts/examples/erc721-transfer/FxERC721RootTunnel.sol";
import {FxERC721} from "contracts/tokens/FxERC721.sol";

import {FxERC1155ChildTunnel} from "contracts/examples/erc1155-transfer/FxERC1155ChildTunnel.sol";
import {FxERC1155RootTunnel} from "contracts/examples/erc1155-transfer/FxERC1155RootTunnel.sol";
import {FxERC1155} from "contracts/tokens/FxERC1155.sol";

import {FxMintableERC20ChildTunnel} from "contracts/examples/mintable-erc20-transfer/FxMintableERC20ChildTunnel.sol";
import {FxMintableERC20RootTunnel} from "contracts/examples/mintable-erc20-transfer/FxMintableERC20RootTunnel.sol";
import {FxMintableERC20} from "contracts/tokens/FxMintableERC20.sol";

import {FxMintableERC721ChildTunnel} from "contracts/examples/mintable-erc721-transfer/FxMintableERC721ChildTunnel.sol";
import {FxMintableERC721RootTunnel} from "contracts/examples/mintable-erc721-transfer/FxMintableERC721RootTunnel.sol";
import {FxMintableERC721} from "contracts/tokens/FxMintableERC721.sol";

import {FxMintableERC1155ChildTunnel} from "contracts/examples/mintable-erc1155-transfer/FxMintableERC1155ChildTunnel.sol";
import {FxMintableERC1155RootTunnel} from "contracts/examples/mintable-erc1155-transfer/FxMintableERC1155RootTunnel.sol";
import {FxMintableERC1155} from "contracts/tokens/FxMintableERC1155.sol";

import {MockERC20RootTunnel} from "../mock/RootTunnel.sol";

contract FxBase is Test, Events {
    FxRoot public fxRoot;
    FxChild public fxChild;
    MockStateSender public stateSender;
    MockStateReceiver public stateReceiver;

    address public manager = makeAddr("manager");
    address public MATIC = 0x0000000000000000000000000000000000001001;
    address public checkpointManager = makeAddr("checkpointManager");

    struct RootContracts {
        FxERC20 erc20Token;
        FxERC20RootTunnel erc20Tunnel;
        FxMintableERC20 erc20MintableToken;
        FxMintableERC20RootTunnel erc20MintableTunnel;
        FxERC721 erc721Token;
        FxERC721RootTunnel erc721Tunnel;
        FxMintableERC721 erc721MintableToken;
        FxMintableERC721RootTunnel erc721MintableTunnel;
        FxERC1155 erc1155Token;
        FxERC1155RootTunnel erc1155Tunnel;
        FxMintableERC1155 erc1155MintableToken;
        FxMintableERC1155RootTunnel erc1155MintableTunnel;
    }

    struct ChildContracts {
        FxERC20 erc20Token;
        FxERC20ChildTunnel erc20Tunnel;
        FxMintableERC20 erc20MintableToken;
        FxMintableERC20ChildTunnel erc20MintableTunnel;
        FxERC721 erc721Token;
        FxERC721ChildTunnel erc721Tunnel;
        FxMintableERC721 erc721MintableToken;
        FxMintableERC721ChildTunnel erc721MintableTunnel;
        FxERC1155 erc1155Token;
        FxERC1155ChildTunnel erc1155Tunnel;
        FxMintableERC1155 erc1155MintableToken;
        FxMintableERC1155ChildTunnel erc1155MintableTunnel;
    }

    RootContracts public root;
    ChildContracts public child;

    function setUp() public virtual {
        fxChild = new FxChild();

        stateReceiver = new MockStateReceiver(address(fxChild));

        vm.etch(MATIC, address(stateReceiver).code);

        stateSender = new MockStateSender(MATIC);
        fxRoot = new FxRoot(address(stateSender));

        fxRoot.setFxChild(address(fxChild));
        fxChild.setFxRoot(address(fxRoot));

        vm.startPrank(manager);

        root.erc20Token = new FxERC20();
        child.erc20Tunnel = new FxERC20ChildTunnel(address(fxChild), address(root.erc20Token));
        root.erc20Token.initialize(manager, address(child.erc20Tunnel), "FxERC20", "FE2", 18);

        root.erc20Tunnel = new MockERC20RootTunnel(checkpointManager, address(fxRoot), address(root.erc20Token));
        root.erc20Tunnel.setFxChildTunnel(address(child.erc20Tunnel));
        child.erc20Tunnel.setFxRootTunnel(address(root.erc20Tunnel));

        vm.stopPrank();
    }
}

contract MockMessageProcessor {
    event MessageProcessed(uint256 indexed stateId, address rootMessageSender, bytes data);

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public {
        emit MessageProcessed(stateId, rootMessageSender, data);
    }
}
