// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { IFxMessageProcessor } from '../FxChild.sol';

/** 
 * @title FxTestStateReceiver
 */
contract FxTestStateReceiver is IFxMessageProcessor {
    address public fxChild;

    uint256 public latestStateId;
    address public latestRootMessageSender;
    bytes public latestData;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    function onMessageReceive(uint256 stateId, address rootMessageSender, bytes calldata data) public override {
        require(msg.sender == fxChild, "Invalid sender");
        latestStateId = stateId;
        latestRootMessageSender = rootMessageSender;
        latestData = data;
    }
}
