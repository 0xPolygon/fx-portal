// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "../lib/IERC1155.sol";

interface IFxMintableERC1155 is IERC1155 {
    function fxManager() external returns (address);

    function initialize(
        address fxManager,
        address connectedToken,
        string calldata uri,
        address minter
    ) external;

    function connectedToken() external returns (address);

    function mintToken(
        address user,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintTokenBatch(
        address user,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address user,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address user,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}
