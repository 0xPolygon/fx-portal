// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../lib/ERC20.sol";
import {IFxMintableERC20} from "./IFxMintableERC20.sol";

/**
 * @title FxERC20 represents fx erc20
 */
contract FxMintableERC20 is IFxMintableERC20, ERC20 {
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
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address minter_
    ) public override {
        require(_fxManager == address(0x0) && _connectedToken == address(0x0), "Token is already initialized");
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;

        // setup meta data
        setupMetaData(name_, symbol_, decimals_);

        minter = minter_;
    }

    // fxManager returns fx manager
    function fxManager() public view override returns (address) {
        return _fxManager;
    }

    // connectedToken returns root token
    function connectedToken() public view override returns (address) {
        return _connectedToken;
    }

    // setup name, symbol and decimals
    function setupMetaData(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        require(msg.sender == _fxManager, "Invalid sender");
        _setupMetaData(name_, symbol_, decimals_);
    }

    function updateMinter(address who) external onlyMinterOrFxManager {
        minter = who;
    }

    function mintToken(address user, uint256 amount) external override onlyMinterOrFxManager {
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        _burn(user, amount);
    }
}
