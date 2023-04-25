// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@utils/Test.sol";
import {FxRoot} from "contracts/FxRoot.sol";
import {FxChild} from "contracts/FxChild.sol";
import {MockStateSender} from "contracts/mock/StateSender.sol";
import {MockStateReceiver} from "contracts/mock/StateReceiver.sol";

contract FxBase is Test {
    FxRoot public fxRoot;
    FxChild public fxChild;
    MockStateSender public stateSender;
    MockStateReceiver public stateReceiver;

    address public MATIC = 0x0000000000000000000000000000000000001001;

    function setUp() public virtual {
        fxChild = new FxChild();

        stateReceiver = new MockStateReceiver(address(fxChild));

        vm.etch(MATIC, address(stateReceiver).code);

        stateSender = new MockStateSender(MATIC);
        fxRoot = new FxRoot(address(stateSender));

        fxRoot.setFxChild(address(fxChild));
        fxChild.setFxRoot(address(fxRoot));
    }
}

contract MockMessageProcessor {
    event MessageProcessed(uint256 indexed stateId, address rootMessageSender, bytes data);

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public {
        emit MessageProcessed(stateId, rootMessageSender, data);
    }
}
