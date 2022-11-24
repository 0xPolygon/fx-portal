// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseChildTunnel} from "../../tunnel/FxBaseChildTunnel.sol";
import {Create2} from "../../lib/Create2.sol";
import {Ownable} from "../../lib/Ownable.sol";
import {FxMintableERC20} from "../../tokens/FxMintableERC20.sol";
import {Address} from "../../lib/Address.sol";

/**
 * @title FxMintableERC20ChildTunnel
 */
contract FxMintableERC20ChildTunnel is Ownable, FxBaseChildTunnel, Create2 {
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");

    // event for token mapping
    event TokenMapped(address indexed rootToken, address indexed childToken);
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
    // root to child token
    mapping(address => address) public rootToChildToken;
    // child token template
    address public immutable childTokenTemplate;
    // root token template code hash
    bytes32 public immutable rootTokenTemplateCodeHash;

    constructor(
        address _fxChild,
        address _childTokenTemplate,
        address _rootTokenTemplate
    ) FxBaseChildTunnel(_fxChild) {
        childTokenTemplate = _childTokenTemplate;
        require(Address.isContract(_childTokenTemplate), "FxMintableERC20ChildTunnel: Token template is not contract");
        // compute root token template code hash
        rootTokenTemplateCodeHash = keccak256(minimalProxyCreationCode(_rootTokenTemplate));
    }

    // deploy child token with unique id
    function deployChildToken(
        bytes32 uniqueId,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external {
        // deploy new child token using unique id
        bytes32 childSalt = keccak256(abi.encodePacked(uniqueId));
        address childToken = createClone(childSalt, childTokenTemplate);

        // compute root token address before deployment using create2
        bytes32 rootSalt = keccak256(abi.encodePacked(childToken));
        address rootToken = computedCreate2Address(rootSalt, rootTokenTemplateCodeHash, fxRootTunnel);

        // check if mapping is already there
        require(rootToChildToken[rootToken] == address(0x0), "FxMintableERC20ChildTunnel: ALREADY_MAPPED");
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        // initialize child token with all parameters
        FxMintableERC20(childToken).initialize(address(this), rootToken, name, symbol, decimals, msg.sender);
    }

    function withdraw(address childToken, uint256 amount) public {
        _withdraw(msg.sender, childToken, amount);
    }

    function withdrawTo(
        address receiver,
        address childToken,
        uint256 amount
    ) public {
        _withdraw(receiver, childToken, amount);
    }

    function _withdraw(
        address receiver,
        address childToken,
        uint256 amount
    ) internal {
        FxMintableERC20 childTokenContract = FxMintableERC20(childToken);
        // child token contract will have root token
        address rootToken = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            childToken != address(0x0) && rootToken != address(0x0) && childToken == rootToChildToken[rootToken],
            "FxMintableERC20ChildTunnel: NO_MAPPED_TOKEN"
        );

        // withdraw tokens
        childTokenContract.burn(msg.sender, amount);
        emit FxWithdrawMintableERC20(rootToken, childToken, receiver, amount);

        // name, symbol and decimals
        FxMintableERC20 rootTokenContract = FxMintableERC20(childToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        uint8 decimals = rootTokenContract.decimals();
        bytes memory metaData = abi.encode(name, symbol, decimals);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(rootToken, childToken, receiver, amount, metaData));
    }

    //
    // Internal functions
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
            revert("FxMintableERC20ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address to, uint256 amount, bytes memory depositData) = abi.decode(
            syncData,
            (address, address, address, uint256, bytes)
        );
        address childToken = rootToChildToken[rootToken];

        // deposit tokens
        FxMintableERC20 childTokenContract = FxMintableERC20(childToken);
        childTokenContract.mintToken(to, amount);
        emit FxDepositMintableERC20(rootToken, depositor, to, amount);

        // call `onTokenTranfer` on `to` with limit and ignore error
        if (Address.isContract(to)) {
            uint256 txGas = 2000000;
            bool success = false;
            bytes memory data = abi.encodeWithSignature(
                "onTokenTransfer(address,address,address,address,uint256,bytes)",
                rootToken,
                childToken,
                depositor,
                to,
                amount,
                depositData
            );
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := call(txGas, to, 0, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}
