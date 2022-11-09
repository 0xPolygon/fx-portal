// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseChildTunnel} from "../../tunnel/FxBaseChildTunnel.sol";
import {Create2} from "../../lib/Create2.sol";
import {FxERC721} from "../../tokens/FxERC721.sol";
import {IERC721Receiver} from "../../lib/IERC721Receiver.sol";
import {Ownable} from "../../lib/Ownable.sol";
import {Address} from "../../lib/Address.sol";

/**
 * @title FxMintableERC721ChildTunnel
 */
contract FxMintableERC721ChildTunnel is FxBaseChildTunnel, Create2, IERC721Receiver, Ownable {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    // bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
    string public constant SUFFIX_NAME = " (FXERC721)";
    string public constant PREFIX_SYMBOL = "fx";

    event TokenMapped(address indexed rootToken, address indexed childToken);
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
    ); // root to child token
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
        require(Address.isContract(_childTokenTemplate), "FxMintableERC721ChildTunnel: Token template is not contract");
        // compute root token template code hash
        rootTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_rootTokenTemplate));
    }

    //
    // External methods
    //

    // deploy child token with unique id
    function deployChildToken(
        uint256 _uniqueId,
        string memory _name,
        string memory _symbol
    ) external onlyOwner {
        // deploy new child token using unique id
        bytes32 childSalt = keccak256(abi.encodePacked(_uniqueId));
        address childToken = createClone(childSalt, childTokenTemplate);

        // compute root token address before deployment using create2
        bytes32 rootSalt = keccak256(abi.encodePacked(childToken));
        address rootToken = computedCreate2Address(rootSalt, rootTokenTemplateCodeHash, fxRootTunnel);

        // check if mapping is already there
        require(rootToChildToken[rootToken] == address(0x0), "FxMintableERC721ChildTunnel: ALREADY_MAPPED");
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        // initialize child token with all parameters
        FxERC721(childToken).initialize(
            address(this),
            rootToken,
            string(abi.encodePacked(_name, SUFFIX_NAME)),
            string(abi.encodePacked(PREFIX_SYMBOL, _symbol))
        );
    }

    // Mint tokens on child chain
    function mintToken(
        address _childToken,
        uint256 _tokenId,
        bytes memory _data
    ) external onlyOwner {
        FxERC721 childTokenContract = FxERC721(_childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            _childToken != address(0x0) && rootToken != address(0x0) && _childToken == rootToChildToken[rootToken],
            "FxMintableERC721ChildTunnel: NO_MAPPED_TOKEN"
        );
        childTokenContract.mint(msg.sender, _tokenId, _data);
    }

    function withdraw(
        address childToken,
        uint256 tokenId,
        bytes memory data
    ) external {
        _withdraw(childToken, msg.sender, tokenId, data);
    }

    function withdrawTo(
        address childToken,
        address receiver,
        uint256 tokenId,
        bytes memory data
    ) external {
        _withdraw(childToken, receiver, tokenId, data);
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //
    // Internal methods
    //

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else {
            revert("FxMintableERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address to, uint256 tokenId, bytes memory depositData) = abi.decode(
            syncData,
            (address, address, address, uint256, bytes)
        );
        address childToken = rootToChildToken[rootToken];

        // deposit tokens
        FxERC721 childTokenContract = FxERC721(childToken);
        childTokenContract.mint(to, tokenId, depositData);
        emit FxDepositMintableERC721(rootToken, depositor, to, tokenId);
    }

    function _withdraw(
        address childToken,
        address receiver,
        uint256 tokenId,
        bytes memory data
    ) internal {
        FxERC721 childTokenContract = FxERC721(childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxMintableERC721ChildTunnel: NO_MAPPED_TOKEN"
        );

        require(msg.sender == childTokenContract.ownerOf(tokenId));

        // withdraw tokens
        childTokenContract.burn(tokenId);
        emit FxWithdrawMintableERC721(rootToken, childToken, receiver, tokenId);

        // ! note: figure out if this metadata is required: if not switch to IFxERC721 or add name and symbol in the interface: https://github.com/ethereum/solidity/issues/13349
        FxERC721 rootTokenContract = FxERC721(childToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        bytes memory metaData = abi.encode(name, symbol);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(rootToken, childToken, receiver, tokenId, data, metaData));
    }
}
