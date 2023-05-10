// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@utils/Test.sol";
import {FxRoot} from "contracts/FxRoot.sol";
import {FxChild} from "contracts/FxChild.sol";
import {MockStateSender} from "@mock/StateSender.sol";
import {MockStateReceiver} from "@mock/StateReceiver.sol";

import {FxERC20ChildTunnel} from "contracts/examples/erc20-transfer/FxERC20ChildTunnel.sol";
import {FxERC20RootTunnel} from "contracts/examples/erc20-transfer/FxERC20RootTunnel.sol";
import {FxERC20} from "contracts/tokens/FxERC20.sol";

contract FxBase is Test, Events {
    FxRoot public fxRoot;
    FxChild public fxChild;
    MockStateSender public stateSender;
    MockStateReceiver public stateReceiver;
    address public manager = makeAddr("manager");

    address public MATIC = 0x0000000000000000000000000000000000001001;

    address public checkpointManager = 0x600e7E2B520D51a7FE5e404E73Fb0D98bF2A913E; // @TODO
    address public erc20RootToken;
    address public erc20ChildToken;
    FxERC20ChildTunnel public erc20ChildTunnel;
    FxERC20RootTunnel public erc20RootTunnel;

    function setUp() public virtual {
        fxChild = new FxChild();

        stateReceiver = new MockStateReceiver(address(fxChild));

        vm.etch(MATIC, address(stateReceiver).code);

        stateSender = new MockStateSender(MATIC);
        fxRoot = new FxRoot(address(stateSender));

        fxRoot.setFxChild(address(fxChild));
        fxChild.setFxRoot(address(fxRoot));

        vm.startPrank(manager);

        FxERC20 fxERC20 = new FxERC20();
        erc20RootToken = address(fxERC20);
        erc20ChildTunnel = new FxERC20ChildTunnel(address(fxChild), erc20RootToken);
        fxERC20.initialize(manager, address(erc20ChildTunnel), "FxERC20", "FE2", 18);

        erc20RootTunnel = new MockERC20RootTunnel(checkpointManager, address(fxRoot), erc20RootToken);
        erc20RootTunnel.setFxChildTunnel(address(erc20ChildTunnel));
        erc20ChildTunnel.setFxRootTunnel(address(erc20RootTunnel));
        vm.stopPrank();
    }
}

contract MockMessageProcessor {
    event MessageProcessed(uint256 indexed stateId, address rootMessageSender, bytes data);

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public {
        emit MessageProcessed(stateId, rootMessageSender, data);
    }
}

contract MockERC20RootTunnel is FxERC20RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC20Token
    ) FxERC20RootTunnel(_checkpointManager, _fxRoot, _fxERC20Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}
