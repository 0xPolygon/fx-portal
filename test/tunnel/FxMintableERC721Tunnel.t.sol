// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {FxMintableERC721ChildTunnel} from "contracts/examples/mintable-erc721-transfer/FxMintableERC721ChildTunnel.sol";
import {FxMintableERC721RootTunnel} from "contracts/examples/mintable-erc721-transfer/FxMintableERC721RootTunnel.sol";
import {Create2} from "contracts/lib/Create2.sol";
import {FxMintableERC721} from "contracts/tokens/FxMintableERC721.sol";
import {FxERC721} from "contracts/tokens/FxERC721.sol";

contract FxMintableERC721TunnelTest is FxBase, Create2 {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    FxMintableERC721 rootToken;
    FxMintableERC721 childToken;

    function setUp() public override {
        super.setUp();

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(uniqueId)),
            keccak256(minimalProxyCreationCode(child.erc721MintableTunnel.childTokenTemplate())),
            address(child.erc721MintableTunnel)
        );

        address computedRootToken = computedCreate2Address(
            keccak256(abi.encodePacked(computedChildToken)), // rootSalt
            child.erc721MintableTunnel.rootTokenTemplateCodeHash(),
            address(root.erc721MintableTunnel)
        );

        childToken = FxMintableERC721(computedChildToken);
        rootToken = FxMintableERC721(computedRootToken);
    }

    function test_FxChildDeploy() public {
        assertEq(child.erc721MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc721MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        vm.expectEmit(address(child.erc721MintableTunnel));
        emit TokenMapped(address(rootToken), address(childToken));
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");

        assertEq(child.erc721MintableTunnel.rootToChildToken(address(rootToken)), address(childToken));
        assertEq(root.erc721MintableTunnel.rootToChildTokens(address(rootToken)), address(0)); // map on first withdraw
    }

    function test_FxChildDeployFail() public {
        assertEq(child.erc721MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc721MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");

        vm.expectRevert("Create2: Failed on minimal deploy");
        child.erc721MintableTunnel.deployChildToken(
            uniqueId, // reuse
            "FxMintableERC721",
            "FE1"
        );
    }

    function test_FxChildWithdraw() public {
        vm.prank(manager);
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");

        uint256 tokenId = 1337;
        assertEq(childToken.balanceOf(alice), 0);
        vm.expectRevert("ERC721: owner query for nonexistent token");
        childToken.ownerOf(tokenId);

        vm.prank(manager);
        childToken.mintToken(alice, tokenId, NULL_DATA);

        assertEq(childToken.balanceOf(alice), 1);
        assertEq(childToken.ownerOf(tokenId), alice);

        assertEq0(address(rootToken).code, NULL_DATA); // rootToken not deployed yet

        bytes memory burnData = abi.encode(
            address(rootToken),
            address(childToken),
            alice,
            tokenId,
            NULL_DATA,
            abi.encode(childToken.name(), childToken.symbol())
        );
        vm.expectEmit(address(child.erc721MintableTunnel));
        emit FxWithdrawMintableERC721(address(rootToken), address(childToken), alice, tokenId);
        vm.expectEmit(address(child.erc721MintableTunnel));
        emit MessageSent(burnData);
        vm.prank(alice);
        child.erc721MintableTunnel.withdraw(address(childToken), tokenId, NULL_DATA);

        assertEq(childToken.balanceOf(alice), 0);
    }

    function test_FxRootDeploy() public {
        vm.prank(manager);
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");

        uint256 tokenId = 1337;
        assertEq(childToken.balanceOf(alice), 0);

        vm.prank(manager);
        childToken.mintToken(alice, tokenId, NULL_DATA);

        assertEq(childToken.balanceOf(alice), 1);
        assertEq(childToken.ownerOf(tokenId), alice);

        assertEq0(address(rootToken).code, NULL_DATA); // rootToken not deployed yet

        vm.prank(alice);
        child.erc721MintableTunnel.withdraw(address(childToken), tokenId, NULL_DATA);

        assertEq(childToken.balanceOf(alice), 0);

        vm.expectEmit(address(root.erc721MintableTunnel));
        emit FxWithdrawMintableERC721(address(rootToken), address(childToken), alice, tokenId);
        vm.prank(alice);
        root.erc721MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                alice,
                tokenId,
                NULL_DATA,
                abi.encode(abi.encode(childToken.name(), childToken.symbol()))
            )
        );

        assertNotEq0(address(rootToken).code, NULL_DATA); // root token creation
        assertEq(rootToken.balanceOf(alice), 1);
        assertEq(rootToken.ownerOf(tokenId), alice);

        assertEq(childToken.balanceOf(alice), 0);
    }

    function test_FxRootNoMappingFound() public {
        assertEq(child.erc721MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc721MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        FxERC721 rootTokenSecond = new FxERC721();
        vm.prank(manager);
        rootTokenSecond.initialize(manager, address(childToken), "FxMintableERC721", "FE1");

        vm.expectRevert("FxMintableERC721RootTunnel: NO_MAPPING_FOUND");
        root.erc721MintableTunnel.deposit(address(rootTokenSecond), alice, 1, NULL_DATA);
    }

    function test_FxRootDeposit() public {
        uint256 tokenIdOne = 1;
        uint256 tokenIdTwo = 2;
        vm.startPrank(manager);
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");
        childToken.mintToken(alice, tokenIdOne, NULL_DATA);
        childToken.mintToken(bob, tokenIdTwo, NULL_DATA);
        vm.stopPrank();

        assertEq(childToken.ownerOf(tokenIdOne), alice);
        assertEq(childToken.ownerOf(tokenIdTwo), bob);

        vm.prank(alice);
        child.erc721MintableTunnel.withdrawTo(address(childToken), bob, tokenIdOne, NULL_DATA);
        assertEq0(address(rootToken).code, NULL_DATA);
        // anyone can call
        root.erc721MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                bob,
                tokenIdOne,
                NULL_DATA,
                abi.encode(abi.encode(childToken.name(), childToken.symbol()))
            )
        );

        assertEq(rootToken.balanceOf(alice), 0);
        assertEq(rootToken.ownerOf(tokenIdOne), bob);

        assertEq(childToken.balanceOf(alice), 0);
        assertEq(childToken.ownerOf(tokenIdTwo), bob);

        vm.startPrank(bob);
        rootToken.setApprovalForAll(address(root.erc721MintableTunnel), true);
        root.erc721MintableTunnel.deposit(address(rootToken), bob, tokenIdOne, NULL_DATA);
        vm.stopPrank();

        assertEq(rootToken.ownerOf(tokenIdOne), address(root.erc721MintableTunnel)); // token locked

        assertEq(childToken.ownerOf(tokenIdOne), bob); // token transfered
    }

    function test_FxChildWithdrawExistingToken() public {
        uint256 tokenId = 1;

        vm.startPrank(manager);
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");
        childToken.mintToken(alice, tokenId, NULL_DATA);
        vm.stopPrank();

        vm.prank(alice);
        child.erc721MintableTunnel.withdraw(address(childToken), tokenId, NULL_DATA);
        assertEq0(address(rootToken).code, NULL_DATA);
        // anyone can call
        root.erc721MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                alice,
                tokenId,
                NULL_DATA,
                abi.encode(abi.encode(childToken.name(), childToken.symbol()))
            )
        );

        assertEq(rootToken.ownerOf(tokenId), alice);
        assertEq(childToken.balanceOf(alice), 0);

        vm.startPrank(alice);
        rootToken.setApprovalForAll(address(root.erc721MintableTunnel), true);
        root.erc721MintableTunnel.deposit(address(rootToken), bob, tokenId, NULL_DATA);
        vm.stopPrank();

        assertEq(rootToken.ownerOf(tokenId), address(root.erc721MintableTunnel)); // token locked
        assertEq(childToken.ownerOf(tokenId), bob); // token transfered

        assertNotEq0(address(rootToken).code, NULL_DATA);

        vm.prank(bob);
        child.erc721MintableTunnel.withdraw(address(childToken), tokenId, NULL_DATA);
        root.erc721MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                bob,
                tokenId,
                NULL_DATA,
                abi.encode(abi.encode(childToken.name(), childToken.symbol()))
            )
        );

        assertEq(rootToken.ownerOf(tokenId), bob);
        assertEq(childToken.balanceOf(alice), 0);
    }

    function test_FxChildBobCannotWithdrawAlicesToken() public {
        uint256 tokenId = 1;

        vm.startPrank(manager);
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");
        childToken.mintToken(alice, tokenId, NULL_DATA);
        vm.stopPrank();

        vm.expectRevert("FxMintableERC721ChildTunnel: INVALID_OWNER");
        vm.prank(bob);
        child.erc721MintableTunnel.withdraw(address(childToken), tokenId, NULL_DATA);
    }

    function test_FxRootInvalidMappingOnExit() public {
        vm.prank(manager);
        child.erc721MintableTunnel.deployChildToken(uniqueId, "FxMintableERC721", "FE1");

        vm.expectRevert("FxMintableERC721RootTunnel: INVALID_MAPPING_ON_EXIT");
        root.erc721MintableTunnel.receiveMessage(
            abi.encode(
                address(childToken), // inverse
                address(rootToken),
                alice,
                1,
                NULL_DATA,
                "FxMintableERC721",
                "FE1"
            )
        );
    }

    function test_InvalidSyncType() public {
        bytes32 randomSyncType = keccak256("0x1337");
        bytes memory message = abi.encode(randomSyncType, abi.encode(0));
        vm.expectRevert("FxMintableERC721ChildTunnel: INVALID_SYNC_TYPE");
        stateSender.syncState(
            address(child.erc721MintableTunnel),
            abi.encode(address(root.erc721MintableTunnel), address(child.erc721MintableTunnel), message)
        );
    }
}
