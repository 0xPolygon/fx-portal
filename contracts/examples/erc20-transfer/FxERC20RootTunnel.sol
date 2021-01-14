// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FxBaseRootTunnel } from "../../tunnel/FxBaseRootTunnel.sol";

/** 
 * @title FxERC20RootTunnel
 */
contract FxERC20RootTunnel is FxBaseRootTunnel {
    constructor(address _checkpointManager, address _fxRoot, address _fxChildTunnel)  FxBaseRootTunnel(_checkpointManager, _fxRoot, _fxChildTunnel) {

    }

    function deposit(address rootToken, address user, uint256 amount, bytes memory data) public {
        // transfer from depositor to this contract
        IERC20(rootToken).transferFrom(
            msg.sender,    // depositor
            address(this), // manager contract
            amount
        );

        // rootToken, depositor, user, amount, extra data
        bytes memory message = abi.encode(rootToken, msg.sender, user, amount, data);
        _sendMessageToChild(message);
    }

    function _processMessageFromChild(bytes memory data) internal override {
        // TODO process data for exit
    }
}
