// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "../../lib/ERC721.sol";
import {Create2} from "../../lib/Create2.sol";
import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";
import {IERC721Receiver} from "../../lib/IERC721Receiver.sol";

/**
 * @title FxERC721RootTunnel
 */
contract FxERC721RootTunnel is FxBaseRootTunnel, Create2, IERC721Receiver {
    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    event TokenMappedERC721(address indexed rootToken, address indexed childToken);
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

    mapping(address => address) public rootToChildTokens;
    bytes32 public childTokenTemplateCodeHash;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC721Token
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        // compute child token template code hash
        childTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_fxERC721Token));
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Map a token to enable its movement via the PoS Portal, callable only by mappers
     * @param rootToken address of token on root chain
     */
    function mapToken(address rootToken) public {
        // check if token is already mapped
        require(rootToChildTokens[rootToken] == address(0x0), "FxERC721RootTunnel: ALREADY_MAPPED");

        // name, symbol
        ERC721 rootTokenContract = ERC721(rootToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();

        // MAP_TOKEN, encode(rootToken, name, symbol)
        bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken, name, symbol));
        _sendMessageToChild(message);

        // compute child token address before deployment using create2
        bytes32 salt = keccak256(abi.encodePacked(rootToken));
        address childToken = computedCreate2Address(salt, childTokenTemplateCodeHash, fxChildTunnel);

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;
        emit TokenMappedERC721(rootToken, childToken);
    }

    function deposit(
        address rootToken,
        address user,
        uint256 tokenId,
        bytes memory data
    ) public {
        // map token if not mapped
        if (rootToChildTokens[rootToken] == address(0x0)) {
            mapToken(rootToken);
        }

        // transfer from depositor to this contract
        ERC721(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            tokenId,
            data
        );

        // DEPOSIT, encode(rootToken, depositor, user, tokenId, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, tokenId, data));
        _sendMessageToChild(message);
        emit FxDepositERC721(rootToken, msg.sender, user, tokenId);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, address childToken, address to, uint256 tokenId, bytes memory syncData) = abi.decode(
            data,
            (address, address, address, uint256, bytes)
        );
        // validate mapping for root to child
        require(rootToChildTokens[rootToken] == childToken, "FxERC721RootTunnel: INVALID_MAPPING_ON_EXIT");

        // transfer from tokens to
        ERC721(rootToken).safeTransferFrom(address(this), to, tokenId, syncData);
        emit FxWithdrawERC721(rootToken, childToken, to, tokenId);
    }
}
