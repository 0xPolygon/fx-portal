// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { IERC20 } from "../../lib/IERC20.sol";
import { ERC20 } from "../../lib/ERC20.sol";

interface IFxERC20 {
    function initialize(address _fxManager,address _rootToken, string memory _name, string memory _symbol, uint8 _decimals) external;
    function deposit(address user, uint256 amount) external;
    function withdraw(address user, uint256 amount) external;
}

/** 
 * @title FxERC20
 */
contract FxERC20 is IFxERC20, ERC20 {
    address public fxManager;
    address public rootToken;

    function initialize(address _fxManager, address _rootToken, string memory _name, string memory _symbol, uint8 _decimals) public override {
        require(fxManager == address(0x0) && _rootToken == address(0x0), "Token is already initialized");
        fxManager = _fxManager;
        rootToken = _rootToken;

        // setup meta data
        setupMetaData(_name, _symbol, _decimals);
    }

    // setup name, symbol and decimals
    function setupMetaData(string memory _name, string memory _symbol, uint8 _decimals) public {
        require(msg.sender == fxManager, "Invalid sender");
        _setupMetaData(_name, _symbol, _decimals);
    }

    function deposit(address user, uint256 amount) public override {
        require(msg.sender == fxManager, "Invalid sender");
        _mint(user, amount);
    }

    function withdraw(address user, uint256 amount) public override {
        require(msg.sender == fxManager, "Invalid sender");
        _burn(user, amount);
    }
}
