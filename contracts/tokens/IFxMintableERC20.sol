// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Metadata} from "../lib/IERC20Metadata.sol";

interface IFxMintableERC20 is IERC20Metadata {
    function fxManager() external returns (address);

    function connectedToken() external returns (address);

    function initialize(
        address _fxManager,
        address _connectedToken,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address minter
    ) external;

    function mintToken(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}
