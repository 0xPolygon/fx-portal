// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFxERC20 {
    function initialize(address _fxManager,address _rootToken, uint8 _decimals) external;
    function deposit(address user, uint256 amount) external;
    function withdraw(uint256 amount) external;
}

/** 
 * @title FxERC20
 */
contract FxERC20 is IFxERC20, ERC20 {
    address public fxManager;
    address public rootToken;

    constructor() ERC20("", "") {
    }

    function initialize(address _fxManager, address _rootToken, uint8 _decimals) public override {
        require(fxManager == address(0x0) && _rootToken == address(0x0), "Token is already initialized");
        fxManager = _fxManager;
        rootToken = _rootToken;
        _setupDecimals(_decimals);
    }

    function deposit(address user, uint256 amount) public override {
        require(msg.sender == fxManager, "Invalid sender");
        _mint(user, amount);
    }

    function withdraw(uint256 amount) public override {
        _burn(msg.sender, amount);
    }
}
