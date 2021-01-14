// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import { FxBaseChildTunnel } from '../../tunnel/FxBaseChildTunnel.sol';
import { FxERC20 } from './FxERC20.sol';

/** 
 * @title FxERC20ChildTunnel
 */
contract FxERC20ChildTunnel is FxBaseChildTunnel {
    // event for token maping
    event TokenMapped(address indexed rootToken, address indexed childToken);
    // root to child token
    mapping(address => address) public rootToChildToken;
    // token template
    address public tokenTemplate;

    constructor(address _fxChild, address _tokenTemplate) FxBaseChildTunnel(_fxChild) {
        tokenTemplate = _tokenTemplate;
    }

    function mapToken(address rootToken) public returns (address) {
        address childToken = rootToChildToken[rootToken];

        // check if it's already mapped
        require(childToken == address(0x0), "Token is already mapped");

        // deploy new child token
        childToken = _createClone(rootToken, tokenTemplate);
        FxERC20(childToken).initialize(address(this), rootToken, 18);

        // map the token
        rootToChildToken[rootToken] = childToken;
        emit TokenMapped(rootToken, childToken);

        // return new child token
        return childToken;
    }

    function _processMessageFromRoot(uint256 /* stateId */, address /* sender */, bytes memory data) internal override {
        (address rootToken, address depositor, address user, uint256 amount, bytes memory depositData) = abi.decode(data, (address, address, address, uint256, bytes));
        address childTokenAddress = rootToChildToken[rootToken];
        if (childTokenAddress == address(0x0)) {
            childTokenAddress = mapToken(rootToken);
        }

        // deposit tokens
        FxERC20 childTokenContract = FxERC20(childTokenAddress);
        childTokenContract.deposit(user, amount);
    }

    //
    // Internal methods
    //

    function _createClone(address _rootToken, address _target) internal returns (address _result) {
        bytes20 _targetBytes = bytes20(_target);
        bytes32 _salt = keccak256(abi.encodePacked(address(this), _rootToken));

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), _targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _result := create2(0, clone, 0x37, _salt)
        }
    }
}
