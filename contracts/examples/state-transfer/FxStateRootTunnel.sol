// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { FxBaseRootTunnel } from '../../tunnel/FxBaseRootTunnel.sol';

/** 
 * @title FxStateRootTunnel
 */
contract FxStateRootTunnel is FxBaseRootTunnel {
    bytes public latestData;

    constructor(address _checkpointManager, address _fxRoot, address _fxChildTunnel)  FxBaseRootTunnel(_checkpointManager, _fxRoot, _fxChildTunnel) {

    }

    function _processMessageFromChild(bytes memory data) internal override {
        latestData = data;
    }

    function sendMessageToChild(bytes memory message) public {
        _sendMessageToChild(message);
    }
}
