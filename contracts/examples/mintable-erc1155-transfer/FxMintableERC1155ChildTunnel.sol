// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxERC1155} from "../../tokens/FxERC1155.sol";
import {ERC1155Holder} from "../../lib/ERC1155Holder.sol";
import {Create2} from "../../lib/Create2.sol";
import {FxBaseChildTunnel} from "../../tunnel/FxBaseChildTunnel.sol";
import {Ownable} from "../../lib/Ownable.sol";
import {Address} from "../../lib/Address.sol";

contract FxMintableERC1155ChildTunnel is FxBaseChildTunnel, Create2, ERC1155Holder, Ownable {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");

    event TokenMapped(address indexed rootToken, address indexed childToken);
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
    event FxBatchWithdrawMintableERC1155(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256[] ids,
        uint256[] amounts
    );
    event FxBatchDepositMintableERC1155(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256[] ids,
        uint256[] amounts
    );
    // root to child token
    mapping(address => address) public rootToChildToken;
    // child token template
    address public immutable childTokenTemplate;
    // root token template codehash
    bytes32 public immutable rootTokenTemplateCodeHash;

    constructor(
        address _fxChild,
        address _childTokenTemplate,
        address _rootTokenTemplate
    ) FxBaseChildTunnel(_fxChild) {
        childTokenTemplate = _childTokenTemplate;
        require(
            Address.isContract(_childTokenTemplate),
            "FxMintableERC1155ChildTunnel: Token template is not contract"
        );
        // compute root token template code hash
        rootTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_rootTokenTemplate));
    }

    //
    // External methods
    //

    // deploy child token with unique id
    function deployChildToken(uint256 _uniqueId, string memory _uri) external onlyOwner {
        // deploy new child token using unique id
        bytes32 childSalt = keccak256(abi.encodePacked(_uniqueId));
        address childToken = createClone(childSalt, childTokenTemplate);

        // compute root token address before deployment using create2
        bytes32 rootSalt = keccak256(abi.encodePacked(childToken));
        address rootToken = computedCreate2Address(rootSalt, rootTokenTemplateCodeHash, fxRootTunnel);

        // check if mapping is already there
        require(rootToChildToken[rootToken] == address(0x0), "FxMintableERC1155ChildTunnel: ALREADY_MAPPED");
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        // initialize child token with all parameters
        FxERC1155(childToken).initialize(address(this), rootToken, _uri);
    }

    // Mint tokens on child chain
    function mintToken(
        address _childToken,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner {
        FxERC1155 childTokenContract = FxERC1155(_childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            _childToken != address(0x0) && rootToken != address(0x0) && _childToken == rootToChildToken[rootToken],
            "FxMintableERC721ChildTunnel: NO_MAPPED_TOKEN"
        );
        childTokenContract.mint(msg.sender, _tokenId, _amount, _data);
    }

    function withdraw(
        address childToken,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        _withdraw(childToken, msg.sender, id, amount, data);
    }

    function withdrawTo(
        address childToken,
        address receiver,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        _withdraw(childToken, receiver, id, amount, data);
    }

    function withdrawBatch(
        address childToken,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        _withdrawBatch(childToken, msg.sender, ids, amounts, data);
    }

    function withdrawToBatch(
        address childToken,
        address receiver,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        _withdrawBatch(childToken, receiver, ids, amounts, data);
    }

    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        uint256, /* amount */
        bytes memory /* data */
    ) public pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] memory, /* tokenIds */
        uint256[] memory, /* amounts */
        bytes memory /* data */
    ) public pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    //
    // Internal methods
    //

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else if (syncType == DEPOSIT_BATCH) {
            _syncDepositBatch(syncData);
        } else {
            revert("FxMintableERC1155ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address to, uint256 tokenId, uint256 amount, bytes memory data) = abi
            .decode(syncData, (address, address, address, uint256, uint256, bytes));

        address childToken = rootToChildToken[rootToken];
        FxERC1155 childTokenContract = FxERC1155(childToken);

        childTokenContract.mint(to, tokenId, amount, data);
        emit FxDepositMintableERC1155(rootToken, depositor, to, tokenId, amount);
    }

    function _syncDepositBatch(bytes memory syncData) internal {
        (
            address rootToken,
            address depositor,
            address to,
            uint256[] memory tokenIds,
            uint256[] memory amounts,
            bytes memory data
        ) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes));

        address childToken = rootToChildToken[rootToken];
        FxERC1155 childTokenContract = FxERC1155(childToken);

        childTokenContract.mintBatch(to, tokenIds, amounts, data);
        emit FxBatchDepositMintableERC1155(rootToken, depositor, to, tokenIds, amounts);
    }

    function _withdraw(
        address childToken,
        address receiver,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        FxERC1155 childTokenContract = FxERC1155(childToken);
        address rootToken = childTokenContract.connectedToken();

        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxMintableERC1155ChildTunnel: NO_MAPPED_TOKEN"
        );

        require(
            childTokenContract.balanceOf(msg.sender, id) >= amount,
            "FxMintableERC1155ChildTunnel: INSUFFICIENT_BALANCE"
        );

        childTokenContract.burn(msg.sender, id, amount);
        emit FxWithdrawMintableERC1155(rootToken, childToken, receiver, id, amount);

        FxERC1155 rootTokenContract = FxERC1155(childToken);
        bytes memory metaData = abi.encode(rootTokenContract.uri(id));

        bytes memory message = abi.encode(
            WITHDRAW,
            abi.encode(rootToken, childToken, receiver, id, amount, data, metaData)
        );
        _sendMessageToRoot(message);
    }

    function _withdrawBatch(
        address childToken,
        address receiver,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal {
        FxERC1155 childTokenContract = FxERC1155(childToken);
        address rootToken = childTokenContract.connectedToken();

        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxMintableERC1155ChildTunnel: NO_MAPPED_TOKEN"
        );
        require(ids.length == amounts.length, "FxMintableERC1155ChildTunnel: LENGTH_MIS_MATCH");

        FxERC1155 rootTokenContract = FxERC1155(childToken);
        bytes memory metaData;
        {
            uint256 length = ids.length;
            string[] memory uris = new string[](length);

            for (uint256 i; i < length; ) {
                uris[i] = rootTokenContract.uri(ids[i]);
                unchecked {
                    ++i;
                }
            }

            childTokenContract.burnBatch(msg.sender, ids, amounts);
            emit FxBatchWithdrawMintableERC1155(rootToken, childToken, receiver, ids, amounts);

            metaData = abi.encode(uris);
        }

        bytes memory message = abi.encode(
            WITHDRAW_BATCH,
            abi.encode(rootToken, childToken, receiver, ids, amounts, data, metaData)
        );
        _sendMessageToRoot(message);
    }
}
