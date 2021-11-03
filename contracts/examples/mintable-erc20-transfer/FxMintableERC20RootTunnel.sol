// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Create2} from "../../lib/Create2.sol";
import {SafeMath} from "../../lib/SafeMath.sol";
import {FxERC20} from "../../tokens/FxERC20.sol";
import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FxMintableERC20RootTunnel
 */
contract FxMintableERC20RootTunnel is FxBaseRootTunnel, Create2 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    //bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    mapping(address => address) public rootToChildTokens;
    address public rootTokenTemplate;
    bytes32 public childTokenTemplateCodeHash;

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
        uint256 amount,
        bytes memory data
    ) public {
        // map token if not mapped
        require(rootToChildTokens[rootToken] != address(0x0), "FxMintableERC20RootTunnel: NO_MAPPING_FOUND");

        // transfer from depositor to this contract
        IERC20(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            amount
        );

        // DEPOSIT, encode(rootToken, depositor, user, amount, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, amount, data));
        _sendMessageToChild(message);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, address childToken, address to, uint256 amount, bytes memory metaData) = abi.decode(
            data,
            (address, address, address, uint256, bytes)
        );

        // if root token is not available, create it
        if (!_isContract(rootToken) && rootToChildTokens[rootToken] == address(0x0)) {
            (string memory name, string memory symbol, uint8 decimals) = abi.decode(metaData, (string, string, uint8));

            address _createdToken = _deployRootToken(childToken, name, symbol, decimals);
            require(_createdToken == rootToken, "FxMintableERC20RootTunnel: ROOT_TOKEN_CREATION_MISMATCH");
        }

        // validate mapping for root to child
        require(rootToChildTokens[rootToken] == childToken, "FxERC20RootTunnel: INVALID_MAPPING_ON_EXIT");

        // check if current balance for token is less than amount,
        // mint remaining amount for this address
        FxERC20 tokenObj = FxERC20(rootToken);
        uint256 balanceOf = tokenObj.balanceOf(address(this));
        if (balanceOf < amount) {
            tokenObj.mint(address(this), amount.sub(balanceOf));
        }

        //approve token transfer
        tokenObj.approve(address(this), amount);

        // transfer from tokens
        IERC20(rootToken).safeTransferFrom(address(this), to, amount);
    }

    function _deployRootToken(
        address childToken,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal returns (address) {
        // deploy new root token
        bytes32 salt = keccak256(abi.encodePacked(childToken));
        address rootToken = createClone(salt, rootTokenTemplate);
        FxERC20(rootToken).initialize(address(this), rootToken, name, symbol, decimals);

        // add into mapped tokens
        rootToChildTokens[rootToken] = childToken;

        return rootToken;
    }

    // check if address is contract
    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
