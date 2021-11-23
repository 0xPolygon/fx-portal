// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "../lib/IERC721.sol";

interface IFxERC721 is IERC721 {
    function fxManager() external returns (address);

    function connectedToken() external returns (address);

    function initialize(
        address _fxManager,
        address _connectedToken,
        string memory _name,
        string memory _symbol
    ) external;

    function mint(
        address user,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function burn(uint256 tokenId) external;
}
