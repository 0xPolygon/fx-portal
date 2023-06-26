// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFxChild {
    function onStateReceive(uint256 stateId, bytes calldata _data) external;
}

contract MockStateReceiver {
    address public immutable fxChild;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    function receiveState(uint256 stateId, bytes calldata _data) external {
        IFxChild(fxChild).onStateReceive(stateId, _data);
    }
}
