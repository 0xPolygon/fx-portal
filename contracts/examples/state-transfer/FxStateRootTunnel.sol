// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0<0.7.0;

import { FxBaseRootTunnel } from '../../tunnel/FxBaseRootTunnel.sol';

/** 
 * @title FxStateRootTunnel
 */
contract FxStateRootTunnel is FxBaseRootTunnel {
    bytes public latestData;

    constructor(address _checkpointManager, address _fxRoot)  FxBaseRootTunnel(_checkpointManager, _fxRoot) public {}

    function _processMessageFromChild(bytes memory data) internal override {
        latestData = data;
    }

    function sendMessageToChild(bytes memory message) public {
        _sendMessageToChild(message);
    }
}
