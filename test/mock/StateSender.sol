// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStateReceiver {
    function receiveState(uint256 stateId, bytes calldata data) external;

    function fxChild() external returns (address);
}

contract MockStateSender {
    event StateSynced(uint256 indexed id, address indexed contractAddress, bytes data);
    IStateReceiver public stateReceiver;

    constructor(address _stateReceiver) {
        stateReceiver = IStateReceiver(_stateReceiver);
    }

    function updateStateReceiver(address _where) public {
        stateReceiver = IStateReceiver(_where);
    }

    function syncState(address /*receiver*/, bytes calldata data) external {
        uint256 stateId = 1;
        stateReceiver.receiveState(stateId, data);
        emit StateSynced(stateId, stateReceiver.fxChild(), data);
    }
}
