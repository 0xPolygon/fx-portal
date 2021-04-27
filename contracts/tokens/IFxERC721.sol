// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IFxERC721 {
    function fxManager() external returns(address);
    function connectedToken() external returns(address);
    function initialize(address _fxManager, address _connectedToken, string memory _name, string memory _symbol) external;
    function transfer(address from, address to, uint256 tokenId) external;
    function mint(address user, uint256 tokenId) external;
    function mint(address user, uint256 tokenId, bytes memory _data) external;
    function burn(uint256 tokenId) external;
}
