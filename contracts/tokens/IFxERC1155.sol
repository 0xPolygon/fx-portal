// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "../lib/IERC1155.sol";

interface IFxERC1155 is IERC1155 {
    function fxManager() external returns (address);

    function initialize(
        address fxManager_,
        address connectedToken_,
        string memory uri_
    ) external;

    function connectedToken() external returns (address);

    function mint(
        address user,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address user,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address user,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address user,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}
