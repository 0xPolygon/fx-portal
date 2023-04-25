// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase, MockMessageProcessor} from "@utils/FxBase.sol";

contract FxRootTest is FxBase {
    address public alice = makeAddr("alice");

    event MessageProcessed(uint256 stateId, address rootMessageSender, bytes data);

    function setUp() public override {
        super.setUp();
    }

    function testSetFxChildAndStateSender() public {
        assertEq(address(fxRoot.fxChild()), address(fxChild));
        assertEq(address(fxRoot.stateSender()), address(stateSender));
    }

    function testCannotSetFxChild() public {
        vm.expectRevert();
        fxRoot.setFxChild(makeAddr("rand"));
    }

    function testSendMessageToChild() public {
        vm.startPrank(alice);
        MockMessageProcessor bob = new MockMessageProcessor();
        bytes memory data = new bytes(0);

        // vm.expectEmit(false, false, false, false);
        // emit MessageProcessed(1, alice, data);
        // emit StateSynced(stateId, stateReceiver.fxChild(), data);
        fxRoot.sendMessageToChild(address(bob), data);
        vm.stopPrank();
    }
}
