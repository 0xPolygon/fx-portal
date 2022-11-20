// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "../lib/IERC721.sol";

interface IFxMintableERC721 is IERC721 {
    function fxManager() external returns (address);

    function connectedToken() external returns (address);

    function initialize(
        address fxManager,
        address connectedToken,
        string calldata name,
        string calldata symbol,
        address minter
    ) external;

    function mintToken(
        address user,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function burn(uint256 tokenId) external;
}
