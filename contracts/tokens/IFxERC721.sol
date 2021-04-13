// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFxERC721 {
    function fxManager() external returns(address);
    function connectedToken() external returns(address);
    function initialize(address _fxManager, address _connectedToken, string memory _name, string memory _symbol) external;
    function safeMint(address user, uint256 tokenId) external;
    function safeMint(address user, uint256 tokenId, bytes memory _data) external;
    function mint(address user, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}
