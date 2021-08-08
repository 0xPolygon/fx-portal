// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0<0.7.0;

interface IFxERC20 {
    function fxManager() external returns(address);
    function connectedToken() external returns(address);
    function initialize(address _fxManager,address _connectedToken, string calldata _name, string calldata _symbol, uint8 _decimals) external;
    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;
}