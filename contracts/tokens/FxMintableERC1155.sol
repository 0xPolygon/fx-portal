// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC1155} from "../lib/ERC1155.sol";
import {IFxMintableERC1155} from "./IFxMintableERC1155.sol";

contract FxMintableERC1155 is ERC1155, IFxMintableERC1155 {
    address internal _fxManager;
    address internal _connectedToken;

    address public minter;

    modifier onlyMinterOrFxManager() {
        require(msg.sender == minter || msg.sender == _fxManager, "Invalid sender");
        _;
    }

    function initialize(
        address fxManager_,
        address connectedToken_,
        string calldata uri_,
        address minter_
    ) public override {
        require(_fxManager == address(0x0) && _connectedToken == address(0x0), "Token is already initialized");
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;

        setupMetaData(uri_);
        minter = minter_;
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

    function updateMinter(address who) external onlyMinterOrFxManager {
        minter = who;
    }

    function mintToken(
        address user,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override onlyMinterOrFxManager {
        _mint(user, id, amount, data);
    }

    function mintTokenBatch(
        address user,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override onlyMinterOrFxManager {
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
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _burnBatch(user, ids, amounts);
    }
}
