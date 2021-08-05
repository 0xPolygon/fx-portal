// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721URIStorage } from "../lib/ERC721URIStorage.sol";
import { IFxERC721URIStorage } from "./IFxERC721URIStorage.sol";


/**
 * @title FxERC20 represents fx erc20
 */
contract FxERC721 is IFxERC721URIStorage, ERC721URIStorage {
    address internal _fxManager;
    address internal _connectedToken;

    function initialize(address fxManager_, address connectedToken_, string memory name_, string memory symbol_) public override {
        require(_fxManager == address(0x0) && _connectedToken == address(0x0), "Token is already initialized");
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;

        // setup meta data
        setupMetaData(name_, symbol_);
    }

    // fxManager returns fx manager
    function fxManager() public override view returns (address) {
      return _fxManager;
    }

    // connectedToken returns root token
    function connectedToken() public override view returns (address) {
      return _connectedToken;
    }

    // setup name, symbol and decimals
    function setupMetaData(string memory _name, string memory _symbol) public {
        require(msg.sender == _fxManager, "Invalid sender");
        _setupMetaData(_name, _symbol);
    }

    function mint(address user, uint256 tokenId, string memory _tokenURI, bytes memory _data) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _safeMint(user, tokenId, _data);
        _setTokenURI(tokenId, _tokenURI);
    }

    function burn(uint256 tokenId) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _burn(tokenId);
    }
}
