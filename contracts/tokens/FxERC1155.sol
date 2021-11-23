// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC1155} from "../lib/ERC1155.sol";
import {IFxERC1155} from "./IFxERC1155.sol";

contract FxERC1155 is ERC1155, IFxERC1155 {
    address internal _fxManager;
    address internal _connectedToken;

    function initialize(
        address fxManager_,
        address connectedToken_,
        string memory uri_
    ) public override {
        require(_fxManager == address(0x0) && _connectedToken == address(0x0), "Token is already initialized");
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;

        setupMetaData(uri_);
    }

    function fxManager() public view override returns (address) {
        return _fxManager;
    }

    function connectedToken() public view override returns (address) {
        return _connectedToken;
    }

    function setupMetaData(string memory _uri) public {
        require(msg.sender == _fxManager, "Invalid sender");
        _setupMetaData(_uri);
    }

    function mint(
        address user,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _mint(user, id, amount, data);
    }

    function mintBatch(
        address user,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _mintBatch(user, ids, amounts, data);
    }

    function burn(
        address user,
        uint256 id,
        uint256 amount
    ) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _burn(user, id, amount);
    }

    function burnBatch(
        address user,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _burnBatch(user, ids, amounts);
    }
}
