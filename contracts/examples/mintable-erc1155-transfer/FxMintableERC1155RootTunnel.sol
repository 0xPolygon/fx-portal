// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1155} from "../../lib/ERC1155.sol";
import {ERC1155Holder} from "../../lib/ERC1155Holder.sol";
import {Create2} from "../../lib/Create2.sol";
import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";

contract FxMintableERC1155RootTunnel is FxBaseRootTunnel, Create2, ERC1155Holder {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

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

    mapping(address => address) public rootToChildTokens;
    bytes32 public immutable childTokenTemplateCodeHash;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC1155Token
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        childTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_fxERC1155Token));
    }

    function mapToken(address rootToken) public {
        require(rootToChildTokens[rootToken] == address(0x0), "FxMintableERC1155RootTunnel: ALREADY_MAPPED");

        ERC1155 rootTokenContract = ERC1155(rootToken);
        string memory uri = rootTokenContract.uri(0);

        // MAP_TOKEN, encode(rootToken,uri)
        bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken, uri));
        _sendMessageToChild(message);

        // compute child token address before deployment using create2
        address childToken = computedCreate2Address(
            keccak256(abi.encodePacked(rootToken)), // childSalt
            childTokenTemplateCodeHash,
            fxChildTunnel
        );

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;
        emit TokenMappedMintableERC1155(rootToken, childToken);
    }

    function deposit(
        address rootToken,
        address user,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        // map token if not mapped
        if (rootToChildTokens[rootToken] == address(0x0)) {
            mapToken(rootToken);
        }

        // transfer from depositor to this contract
        ERC1155(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            id,
            amount,
            data
        );

        // DEPOSIT, encode(rootToken, depositor, user, id, amount, extra data)
        _sendMessageToChild(abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, id, amount, data)));
        emit FxDepositMintableERC1155(rootToken, msg.sender, user, id, amount);
    }

    function depositBatch(
        address rootToken,
        address user,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        // map token if not mapped
        if (rootToChildTokens[rootToken] == address(0x0)) {
            mapToken(rootToken);
        }

        // transfer from depositor to this contract
        ERC1155(rootToken).safeBatchTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            ids,
            amounts,
            data
        );

        // DEPOSIT_BATCH, encode(rootToken, depositor, user, id, amount, extra data)
        _sendMessageToChild(abi.encode(DEPOSIT_BATCH, abi.encode(rootToken, msg.sender, user, ids, amounts, data)));
        emit FxDepositBatchMintableERC1155(rootToken, user, ids, amounts);
    }

    function _processMessageFromChild(bytes memory data) internal override {
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == WITHDRAW) {
            _syncWithdraw(syncData);
        } else if (syncType == WITHDRAW_BATCH) {
            _syncBatchWithdraw(syncData);
        } else {
            revert("FxMintableERC1155RootTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncWithdraw(bytes memory syncData) internal {
        (address rootToken, address childToken, address user, uint256 id, uint256 amount, bytes memory data) = abi
            .decode(syncData, (address, address, address, uint256, uint256, bytes));
        require(rootToChildTokens[rootToken] == childToken, "FxMintableERC1155RootTunnel: INVALID_MAPPING_ON_EXIT");
        ERC1155(rootToken).safeTransferFrom(address(this), user, id, amount, data);
        emit FxWithdrawMintableERC1155(rootToken, childToken, user, id, amount);
    }

    function _syncBatchWithdraw(bytes memory syncData) internal {
        (
            address rootToken,
            address childToken,
            address user,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes));
        require(rootToChildTokens[rootToken] == childToken, "FxMintableERC1155RootTunnel: INVALID_MAPPING_ON_EXIT");
        ERC1155(rootToken).safeBatchTransferFrom(address(this), user, ids, amounts, data);
        emit FxWithdrawBatchMintableERC1155(rootToken, childToken, user, ids, amounts);
    }
}
