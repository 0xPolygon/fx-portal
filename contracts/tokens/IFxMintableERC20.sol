// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../lib/IERC20.sol";

interface IFxMintableERC20 is IERC20 {
    function fxManager() external returns (address);

    function connectedToken() external returns (address);

    function initialize(
        address fxManager,
        address connectedToken,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address minter
    ) external;

    function mintToken(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}
