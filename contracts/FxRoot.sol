// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;


interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

/** 
 * @title FxRoot root contract for fx-portal
 */
contract FxRoot {
    IStateSender public stateSender;
    address public fxChild;

    constructor(address _stateSender, address _fxChild) {
        stateSender = IStateSender(_stateSender);
        fxChild = _fxChild;
    }

    function sendMessageToChild(address _receiver, bytes calldata _data) external {
        bytes memory data = abi.encode(msg.sender, _receiver, _data);
        stateSender.syncState(fxChild, data);
    }
}
