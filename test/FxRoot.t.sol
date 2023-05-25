// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase, MockMessageProcessor} from "@utils/FxBase.sol";
import {FxRoot} from "contracts/FxRoot.sol";
import {FxChild} from "contracts/FxChild.sol";

contract FxRootTest is FxBase {
    address public alice = makeAddr("alice");

    event MessageProcessed(uint256 indexed stateId, address rootMessageSender, bytes data);
    event StateSynced(uint256 indexed id, address indexed contractAddress, bytes data);

    function setUp() public override {
        super.setUp();
    }

    function test_SetFxChildAndStateSender() public {
        FxChild fxChild2 = new FxChild();
        FxRoot fxRoot2 = new FxRoot(address(stateSender));

        fxRoot2.setFxChild(address(fxChild2));
        fxChild2.setFxRoot(address(fxRoot2));

        assertEq(address(fxRoot2.fxChild()), address(fxChild2));
        assertEq(address(fxRoot2.stateSender()), address(stateSender));
    }

    function test_CannotSetFxChild() public {
        vm.expectRevert();
        fxRoot.setFxChild(makeAddr("rand"));
    }

    function test_SendMessageToChild() public {
        vm.startPrank(alice);
        MockMessageProcessor mockTunnel = new MockMessageProcessor();
        bytes memory data = new bytes(0);
        vm.expectEmit(address(mockTunnel));
        emit MessageProcessed(1, alice, data);
        fxRoot.sendMessageToChild(address(mockTunnel), data);
        vm.stopPrank();
    }
}
