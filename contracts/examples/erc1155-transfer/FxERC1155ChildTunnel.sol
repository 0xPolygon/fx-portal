// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFxERC1155} from "../../tokens/IFxERC1155.sol";
import {ERC1155Holder} from "../../lib/ERC1155Holder.sol";
import {Create2} from "../..//lib/Create2.sol";
import {FxBaseChildTunnel} from "../../tunnel/FxBaseChildTunnel.sol";

contract FxERC1155ChildTunnel is FxBaseChildTunnel, Create2, ERC1155Holder {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
    //string public constant URI = "FXERC1155URI" ;

    event TokenMapped(address indexed rootToken, address indexed childToken);
    // root to child token
    mapping(address => address) public rootToChildToken;
    address public tokenTemplate;

    constructor(address _fxChild, address _tokenTemplate) FxBaseChildTunnel(_fxChild) {
        tokenTemplate = _tokenTemplate;
        require(_isContract(_tokenTemplate), "Token template is not contract");
    }

    function withdraw(
        address childToken,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _withdraw(childToken, msg.sender, id, amount, data);
    }

    function withdrawTo(
        address childToken,
        address receiver,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _withdraw(childToken, receiver, id, amount, data);
    }

    function withdrawBatch(
        address childToken,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _withdrawBatch(childToken, msg.sender, ids, amounts, data);
    }

    function withdrawToBatch(
        address childToken,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _withdrawBatch(childToken, receiver, ids, amounts, data);
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == MAP_TOKEN) {
            _mapToken(syncData);
        } else if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else if (syncType == DEPOSIT_BATCH) {
            _syncDepositBatch(syncData);
        } else {
            revert("FxERC1155ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _mapToken(bytes memory syncData) internal returns (address) {
        (address rootToken, string memory uri) = abi.decode(syncData, (address, string));

        address childToken = rootToChildToken[rootToken];
        require(childToken == address(0x0), "FxERC1155ChildTunnel: ALREADY_MAPPED");

        bytes32 salt = keccak256(abi.encodePacked(rootToken));
        childToken = createClone(salt, tokenTemplate);
        IFxERC1155(childToken).initialize(address(this), rootToken, string(abi.encodePacked(uri)));

        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        return childToken;
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address user, uint256 id, uint256 amount, bytes memory data) = abi
            .decode(syncData, (address, address, address, uint256, uint256, bytes));

        address childToken = rootToChildToken[rootToken];
        IFxERC1155 childTokenContract = IFxERC1155(childToken);

        childTokenContract.mint(user, id, amount, data);
    }

    function _syncDepositBatch(bytes memory syncData) internal {
        (
            address rootToken,
            address depositor,
            address user,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes));

        address childToken = rootToChildToken[rootToken];
        IFxERC1155 childTokenContract = IFxERC1155(childToken);

        childTokenContract.mintBatch(user, ids, amounts, data);
    }

    function _withdraw(
        address childToken,
        address receiver,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        IFxERC1155 childTokenContract = IFxERC1155(childToken);
        address rootToken = childTokenContract.connectedToken();

        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxERC1155ChildTunnel: NO_MAPPED_TOKEN"
        );

        childTokenContract.burn(msg.sender, id, amount);

        bytes memory message = abi.encode(WITHDRAW, abi.encode(rootToken, childToken, receiver, id, amount, data));
        _sendMessageToRoot(message);
    }

    function _withdrawBatch(
        address childToken,
        address receiver,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        IFxERC1155 childTokenContract = IFxERC1155(childToken);
        address rootToken = childTokenContract.connectedToken();

        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxERC1155ChildTunnel: NO_MAPPED_TOKEN"
        );

        childTokenContract.burnBatch(msg.sender, ids, amounts);

        bytes memory message = abi.encode(
            WITHDRAW_BATCH,
            abi.encode(rootToken, childToken, receiver, ids, amounts, data)
        );
        _sendMessageToRoot(message);
    }

    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
