// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function onMessageReceive(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    function onMessageReceive(uint256 stateId, address rootMessageSender, bytes calldata data) public override {
        require(msg.sender == fxChild, "Invalid sender");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root messge sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}