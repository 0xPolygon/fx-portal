// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IFxERC20 {
    function fxManager() external returns(address);
    function rootToken() external returns(address);
    function initialize(address _fxManager,address _rootToken, string memory _name, string memory _symbol, uint8 _decimals) external;
    function deposit(address user, uint256 amount) external;
    function withdraw(address user, uint256 amount) external;
}