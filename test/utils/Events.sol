// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Events {
    event TokenMappedERC20(address indexed rootToken, address indexed childToken); // root chain
    event TokenMapped(address indexed rootToken, address indexed childToken); // child chain

    event FxWithdrawERC20(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 amount
    );
    event FxDepositERC20(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 amount
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
    event MessageSent(bytes message);
}
