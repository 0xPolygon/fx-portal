// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Events {
    event TokenMappedERC20(address indexed rootToken, address indexed childToken); // root chain
    event TokenMappedERC721(address indexed rootToken, address indexed childToken);
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
    event FxWithdrawERC721(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 id
    );
    event FxDepositERC721(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 id
    );

    event TokenMappedERC1155(address indexed rootToken, address indexed childToken);
    event FxWithdrawERC1155(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 id,
        uint256 amount
    );
    event FxDepositERC1155(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 id,
        uint256 amount
    );
    event FxWithdrawBatchERC1155(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256[] ids,
        uint256[] amounts
    );
    event FxDepositBatchERC1155(
        address indexed rootToken,
        address indexed userAddress,
        uint256[] ids,
        uint256[] amounts
    );

    event FxWithdrawMintableERC20(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 amount
    );
    event FxDepositMintableERC20(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 amount
    );
    event FxWithdrawMintableERC721(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 id
    );
    event FxDepositMintableERC721(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 id
    );
    event TokenMappedMintableERC1155(address indexed rootToken, address indexed childToken);
    event FxWithdrawMintableERC1155(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 id,
        uint256 amount
    );
    event FxDepositMintableERC1155(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 id,
        uint256 amount
    );
    event FxWithdrawBatchMintableERC1155(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256[] ids,
        uint256[] amounts
    );
    event FxDepositBatchMintableERC1155(
        address indexed rootToken,
        address indexed userAddress,
        uint256[] ids,
        uint256[] amounts
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event MessageSent(bytes message);
}
