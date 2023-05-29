// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IStateSender} from "../FxRoot.sol";

interface IStateReceiver {
    function receiveState(uint256 stateId, bytes calldata data) external;
}

/**
 * @title StastateteSender
 */
contract StateSender is IStateSender {
    address public stateReceiver;

    constructor(address _stateReceiver) {
        stateReceiver = _stateReceiver;
    }

    function syncState(address receiver, bytes calldata data) external {
        uint256 stateId = 0;
        IStateReceiver(stateReceiver).receiveState(stateId, data);
    }
}
