// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase, MockMessageProcessor} from "@utils/FxBase.sol";

contract FxRootTest is FxBase {
    address public alice = makeAddr("alice");

    event MessageProcessed(uint256 indexed stateId, address rootMessageSender, bytes data);
    event StateSynced(uint256 indexed id, address indexed contractAddress, bytes data);

    function setUp() public override {
        super.setUp();
    }

    function test_SetFxChildAndStateSender() public {
        assertEq(address(fxRoot.fxChild()), address(fxChild));
        assertEq(address(fxRoot.stateSender()), address(stateSender));
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
