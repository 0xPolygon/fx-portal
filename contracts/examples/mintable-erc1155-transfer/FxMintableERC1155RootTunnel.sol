// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFxERC1155} from "../../tokens/IFxERC1155.sol";
import {ERC1155Holder} from "../../lib/ERC1155Holder.sol";
import {Create2} from "../../lib/Create2.sol";
import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";
import {Address} from "../../lib/Address.sol";

contract FxMintableERC1155RootTunnel is FxBaseRootTunnel, Create2, ERC1155Holder {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");

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
    address public immutable rootTokenTemplate;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _rootTokenTemplate
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rootTokenTemplate = _rootTokenTemplate;
    }

    function deposit(
        address rootToken,
        address user,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(rootToChildTokens[rootToken] != address(0x0), "FxMintableERC1155RootTunnel: NO_MAPPING_FOUND");

        // transfer from depositor to this contract
        IFxERC1155(rootToken).safeTransferFrom(
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
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        require(rootToChildTokens[rootToken] != address(0x0), "FxMintableERC1155RootTunnel: NO_MAPPING_FOUND");

        // transfer from depositor to this contract
        IFxERC1155(rootToken).safeBatchTransferFrom(
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
        (
            address rootToken,
            address childToken,
            address user,
            uint256 id,
            uint256 amount,
            bytes memory data,
            string memory metadata
        ) = abi.decode(syncData, (address, address, address, uint256, uint256, bytes, string));
        // if root token is not available, create it
        if (!Address.isContract(rootToken) && rootToChildTokens[rootToken] == address(0x0)) {
            _deployRootToken(rootToken, metadata);
        }
        require(rootToChildTokens[rootToken] == childToken, "FxMintableERC1155RootTunnel: INVALID_MAPPING_ON_EXIT");
        IFxERC1155(rootToken).safeTransferFrom(address(this), user, id, amount, data);
        emit FxWithdrawMintableERC1155(rootToken, childToken, user, id, amount);
    }

    function _syncBatchWithdraw(bytes memory syncData) internal {
        (
            address rootToken,
            address childToken,
            address user,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data,
            string memory metadata
        ) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes, string));
        // if root token is not available, create it
        if (!Address.isContract(rootToken) && rootToChildTokens[rootToken] == address(0x0)) {
            _deployRootToken(rootToken, metadata);
        }
        require(rootToChildTokens[rootToken] == childToken, "FxMintableERC1155RootTunnel: INVALID_MAPPING_ON_EXIT");
        IFxERC1155(rootToken).safeBatchTransferFrom(address(this), user, ids, amounts, data);
        emit FxWithdrawBatchMintableERC1155(rootToken, childToken, user, ids, amounts);
    }

    function _deployRootToken(address childToken, string memory uri) internal {
        // deploy new root token
        bytes32 salt = keccak256(abi.encodePacked(childToken));
        address rootToken = createClone(salt, rootTokenTemplate);
        IFxERC1155(rootToken).initialize(address(this), childToken, uri);

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;
        emit TokenMappedMintableERC1155(rootToken, childToken);
    }
}
