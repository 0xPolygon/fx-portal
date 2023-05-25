// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxERC20RootTunnel} from "contracts/examples/erc20-transfer/FxERC20RootTunnel.sol";
import {FxMintableERC20RootTunnel} from "contracts/examples/mintable-erc20-transfer/FxMintableERC20RootTunnel.sol";
import {FxERC721RootTunnel} from "contracts/examples/erc721-transfer/FxERC721RootTunnel.sol";
import {FxMintableERC721RootTunnel} from "contracts/examples/mintable-erc721-transfer/FxMintableERC721RootTunnel.sol";
import {FxERC1155RootTunnel} from "contracts/examples/erc1155-transfer/FxERC1155RootTunnel.sol";
import {FxMintableERC1155RootTunnel} from "contracts/examples/mintable-erc1155-transfer/FxMintableERC1155RootTunnel.sol";

contract MockERC20RootTunnel is FxERC20RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC20Token
    ) FxERC20RootTunnel(_checkpointManager, _fxRoot, _fxERC20Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}

contract MockMintableERC20RootTunnel is FxMintableERC20RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC20Token
    ) FxMintableERC20RootTunnel(_checkpointManager, _fxRoot, _fxERC20Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}

contract MockERC721RootTunnel is FxERC721RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC721Token
    ) FxERC721RootTunnel(_checkpointManager, _fxRoot, _fxERC721Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}

contract MockMintableERC721RootTunnel is FxMintableERC721RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC721Token
    ) FxMintableERC721RootTunnel(_checkpointManager, _fxRoot, _fxERC721Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}

contract MockERC1155RootTunnel is FxERC1155RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC1155Token
    ) FxERC1155RootTunnel(_checkpointManager, _fxRoot, _fxERC1155Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}

contract MockMintableERC1155RootTunnel is FxMintableERC1155RootTunnel {
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _fxERC1155Token
    ) FxMintableERC1155RootTunnel(_checkpointManager, _fxRoot, _fxERC1155Token) {}

    function receiveMessage(bytes memory message) public virtual override {
        _processMessageFromChild(message);
    }
}
