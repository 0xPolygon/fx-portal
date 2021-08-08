// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0<0.7.0;

interface IFxERC721 {
    function fxManager() external returns(address);
    function connectedToken() external returns(address);
    function initialize(address _fxManager, address _connectedToken, string calldata _name, string calldata _symbol) external;
    function mint(address user, uint256 tokenId, bytes calldata _data) external;
    function burn(uint256 tokenId) external;
}
