// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase, MockMessageProcessor} from "@utils/FxBase.sol";

contract FxChildTest is FxBase {
    address public alice = makeAddr("alice");

    function setUp() public override {
        super.setUp();
    }

    function testSetFxRoot() public {
        assertEq(address(fxChild.fxRoot()), address(fxRoot));

        vm.expectRevert();
        fxChild.setFxRoot(makeAddr("rand"));
    }

    function testInvalidSenderOnStateReceive() public {
        vm.startPrank(alice);
        MockMessageProcessor bob = new MockMessageProcessor();
        bytes memory data = new bytes(0);

        stateSender.updateStateReceiver(address(stateReceiver));

        vm.expectRevert("Invalid sender");
        fxRoot.sendMessageToChild(address(bob), data);
        vm.stopPrank();
    }
}
