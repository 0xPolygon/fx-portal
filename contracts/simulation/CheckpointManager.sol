// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockCheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    mapping(uint256 => HeaderBlock) public headerBlocks;

    function submitCheckpoint(uint256 headerNumber, bytes32 root, uint256 start, uint256 end) public {
        headerBlocks[headerNumber] = HeaderBlock({
            root: root,
            start: start,
            end: end,
            createdAt: 0,
            proposer: address(0)
        });
    }
}
