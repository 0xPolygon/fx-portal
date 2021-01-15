// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { ERC20 } from "../../lib/ERC20.sol";
import { FxBaseRootTunnel } from "../../tunnel/FxBaseRootTunnel.sol";

/** 
 * @title FxERC20RootTunnel
 */
contract FxERC20RootTunnel is FxBaseRootTunnel {
    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    // event for token mapping
    event TokenMapped(address indexed rootToken, address indexed childToken);

    // token mappings
    mapping(address => address) public childToRootToken;

    constructor(address _checkpointManager, address _fxRoot, address _fxChildTunnel) 
      FxBaseRootTunnel(_checkpointManager, _fxRoot, _fxChildTunnel) {}

    /**
     * @notice Map a token to enable its movement via the PoS Portal, callable only by mappers
     * @param rootToken address of token on root chain
     */
    function mapToken(address rootToken) public returns (address) {
        // TODO generate child token from root token
        address childToken = address(0x0);

        // if token is already mapped return child token
        if (childToRootToken[childToken] != address(0)) {
          return childToken;
        }

        // name, symbol and decimals
        ERC20 childTokenContract = ERC20(childToken);
        string memory name = childTokenContract.name();
        string memory symbol = childTokenContract.symbol();
        uint8 decimals = childTokenContract.decimals();

        // MAP_TOKEN, encode(rootToken, name, symbol, decimals)
        bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken, name, symbol, decimals));
        _sendMessageToChild(message);

        // emit an event for token map
        emit TokenMapped(rootToken, childToken);

        // return child token
        return childToken;
    }

    function deposit(address rootToken, address user, uint256 amount, bytes memory data) public {
        // map token if not mapped
        mapToken(rootToken);

        // transfer from depositor to this contract
        ERC20(rootToken).transferFrom(
            msg.sender,    // depositor
            address(this), // manager contract
            amount
        );

        // DEPOSIT, encode(rootToken, depositor, user, amount, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, amount, data));
        _sendMessageToChild(message);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, /* address childToken */, address to, uint256 amount) = abi.decode(data, (address, address, address, uint256));
        // require(rootToken == childToRootToken[childToken], "FxERC20RootTunnel: INVALID_MAPPING_FOR_EXIT"); // no need for now

        // transfer from tokens to 
        ERC20(rootToken).transferFrom(
            address(this),
            to,
            amount
        );
    }
}
