// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFxERC721} from "../../tokens/IFxERC721.sol";
import {Create2} from "../../lib/Create2.sol";
import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";
import {IERC721Receiver} from "../../lib/IERC721Receiver.sol";
import {Address} from "../../lib/Address.sol";

/**
 * @title FxMintableERC721RootTunnel
 */
contract FxMintableERC721RootTunnel is FxBaseRootTunnel, Create2, IERC721Receiver {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    event TokenMappedMintableERC721(address indexed rootToken, address indexed childToken);
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

    mapping(address => address) public rootToChildTokens;
    address public immutable rootTokenTemplate;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _rootTokenTemplate
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        rootTokenTemplate = _rootTokenTemplate;
    }

    //
    // External methods
    //

    function deposit(
        address rootToken,
        address user,
        uint256 tokenId,
        bytes calldata data
    ) external {
        require(rootToChildTokens[rootToken] != address(0x0), "FxMintableERC721RootTunnel: NO_MAPPING_FOUND");

        // transfer from depositor to this contract
        IFxERC721(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            tokenId,
            data
        );

        // DEPOSIT, encode(rootToken, depositor, user, tokenId, extra data)
        _sendMessageToChild(abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, tokenId, data)));
        emit FxDepositMintableERC721(rootToken, msg.sender, user, tokenId);
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

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (
            address rootToken,
            address childToken,
            address to,
            uint256 tokenId,
            bytes memory syncData,
            bytes memory metadata
        ) = abi.decode(data, (address, address, address, uint256, bytes, bytes));
        // if root token is not available, create it
        if (!Address.isContract(rootToken) && rootToChildTokens[rootToken] == address(0x0)) {
            (string memory name, string memory symbol) = abi.decode(metadata, (string, string));
            address _createdToken = _deployRootToken(childToken, name, symbol);
            require(_createdToken == rootToken, "FxMintableERC721RootTunnel: ROOT_TOKEN_CREATION_MISMATCH");
        }

        // validate mapping for root to child
        require(rootToChildTokens[rootToken] == childToken, "FxMintableERC721RootTunnel: INVALID_MAPPING_ON_EXIT");

        // check if current token has been minted on root chain
        IFxERC721 nft = IFxERC721(rootToken);
        address currentOwner = nft.ownerOf(tokenId);
        if (currentOwner == address(0)) {
            nft.mint(address(this), tokenId, "");
        }

        // transfer from tokens to
        IFxERC721(rootToken).safeTransferFrom(address(this), to, tokenId, syncData);
        emit FxWithdrawMintableERC721(rootToken, childToken, to, tokenId);
    }

    function _deployRootToken(
        address childToken,
        string memory name,
        string memory symbol
    ) internal returns (address) {
        // deploy new root token
        bytes32 salt = keccak256(abi.encodePacked(childToken));
        address rootToken = createClone(salt, rootTokenTemplate);
        IFxERC721(rootToken).initialize(address(this), childToken, name, symbol);

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;
        emit TokenMappedMintableERC721(rootToken, childToken);

        return rootToken;
    }
}
