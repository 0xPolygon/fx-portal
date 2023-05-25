// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {FxERC721ChildTunnel} from "contracts/examples/erc721-transfer/FxERC721ChildTunnel.sol";
import {FxERC721RootTunnel} from "contracts/examples/erc721-transfer/FxERC721RootTunnel.sol";
import {FxERC721} from "contracts/tokens/FxERC721.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract FxERC721TunnelTest is FxBase {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public override {
        super.setUp();
    }

    function test_FxRootMapToken() public {
        assertEq(child.erc721Tunnel.rootToChildToken(address(root.erc721Token)), address(0));
        assertEq(root.erc721Tunnel.rootToChildTokens(address(root.erc721Token)), address(0));

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(address(root.erc721Token))),
            root.erc721Tunnel.childTokenTemplateCodeHash(),
            address(child.erc721Tunnel)
        );

        vm.expectEmit(address(child.erc721Tunnel));
        emit TokenMapped(address(root.erc721Token), computedChildToken);
        vm.expectEmit(address(root.erc721Tunnel));
        emit TokenMappedERC721(address(root.erc721Token), computedChildToken);

        root.erc721Tunnel.mapToken(address(root.erc721Token));

        assertEq(child.erc721Tunnel.rootToChildToken(address(root.erc721Token)), computedChildToken);
        assertEq(root.erc721Tunnel.rootToChildTokens(address(root.erc721Token)), computedChildToken);
    }

    function test_AlreadyMappedRevert() public {
        root.erc721Tunnel.mapToken(address(root.erc721Token));

        vm.expectRevert("FxERC721RootTunnel: ALREADY_MAPPED");
        root.erc721Tunnel.mapToken(address(root.erc721Token));

        bytes memory mockMessage = abi.encode(
            root.erc721Tunnel.MAP_TOKEN(),
            abi.encode(address(root.erc721Token), "mock", "MOCK")
        );

        vm.expectRevert("FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        fxRoot.sendMessageToChild(address(child.erc721Tunnel), mockMessage);

        vm.expectRevert("FxERC721ChildTunnel: ALREADY_MAPPED");
        vm.prank(address(root.erc721Tunnel));
        fxRoot.sendMessageToChild(address(child.erc721Tunnel), mockMessage);
    }

    function test_FxRootDepositWithMapToken() public {
        FxERC721 childToken = FxERC721(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(root.erc721Token))),
                root.erc721Tunnel.childTokenTemplateCodeHash(),
                address(child.erc721Tunnel)
            )
        );
        uint256 tokenId = 1;
        vm.prank(manager);
        root.erc721Token.mint(alice, tokenId, NULL_DATA);
        vm.startPrank(alice); // depositor
        root.erc721Token.approve(address(root.erc721Tunnel), tokenId);

        vm.expectEmit(address(child.erc721Tunnel));
        emit TokenMapped(address(root.erc721Token), address(childToken));
        vm.expectEmit(address(root.erc721Tunnel));
        emit TokenMappedERC721(address(root.erc721Token), address(childToken));
        vm.expectEmit(address(root.erc721Tunnel));
        emit FxDepositERC721(address(root.erc721Token), alice, bob, tokenId);

        root.erc721Tunnel.deposit(address(root.erc721Token), bob /*receiver*/, tokenId, bytes(""));

        assertEq(childToken.ownerOf(tokenId), bob);
        assertEq(childToken.balanceOf(address(child.erc721Tunnel)), 0);

        assertEq(root.erc721Token.balanceOf(alice), 0);
        assertEq(root.erc721Token.ownerOf(tokenId), address(root.erc721Tunnel));

        vm.stopPrank();
    }

    function test_FxRootDepositAfterMapToken(uint tokenId) public {
        root.erc721Tunnel.mapToken(address(root.erc721Token));
        FxERC721 childToken = FxERC721(root.erc721Tunnel.rootToChildTokens(address(root.erc721Token)));

        vm.prank(manager);
        root.erc721Token.mint(alice, tokenId, NULL_DATA);
        vm.startPrank(alice); // depositor
        root.erc721Token.approve(address(root.erc721Tunnel), tokenId);

        vm.expectEmit(address(root.erc721Tunnel));
        emit FxDepositERC721(address(root.erc721Token), alice, bob, tokenId);

        root.erc721Tunnel.deposit(address(root.erc721Token), bob /*user*/, tokenId, bytes(""));

        assertEq(childToken.ownerOf(tokenId), bob);
        assertEq(childToken.balanceOf(address(child.erc721Tunnel)), 0);

        assertEq(root.erc721Token.balanceOf(alice), 0);
        assertEq(root.erc721Token.ownerOf(tokenId), address(root.erc721Tunnel));

        vm.stopPrank();
    }

    function test_FxChildWithdraw() public {
        uint256 tokenId = 1;

        vm.prank(manager);
        root.erc721Token.mint(alice, tokenId, NULL_DATA);

        vm.startPrank(alice); // depositor
        root.erc721Token.approve(address(root.erc721Tunnel), tokenId);
        root.erc721Tunnel.deposit(address(root.erc721Token), bob /*user*/, tokenId, bytes(""));
        vm.stopPrank();
        FxERC721 childToken = FxERC721(root.erc721Tunnel.rootToChildTokens(address(root.erc721Token)));

        assertEq(childToken.ownerOf(tokenId), bob);
        assertEq(childToken.balanceOf(address(child.erc721Tunnel)), 0);

        assertEq(root.erc721Token.balanceOf(alice), 0);
        assertEq(root.erc721Token.ownerOf(tokenId), address(root.erc721Tunnel));

        bytes memory burnMessage = abi.encode(address(root.erc721Token), address(childToken), bob, tokenId, NULL_DATA);

        vm.prank(bob);
        vm.expectEmit(address(child.erc721Tunnel));
        emit MessageSent(burnMessage);
        child.erc721Tunnel.withdraw(address(childToken), tokenId, NULL_DATA);

        assertEq(childToken.balanceOf(bob), 0);
        vm.expectRevert("ERC721: owner query for nonexistent token");
        childToken.ownerOf(tokenId);
    }

    function test_FxChildWithdrawSyncOnRoot() public {
        uint256 tokenId = 1;

        vm.prank(manager);
        root.erc721Token.mint(alice, tokenId, NULL_DATA);

        vm.startPrank(alice); // depositor
        root.erc721Token.approve(address(root.erc721Tunnel), tokenId);
        root.erc721Tunnel.deposit(address(root.erc721Token), bob /*user*/, tokenId, bytes(""));
        vm.stopPrank();
        FxERC721 childToken = FxERC721(root.erc721Tunnel.rootToChildTokens(address(root.erc721Token)));

        assertEq(childToken.ownerOf(tokenId), bob);
        assertEq(childToken.balanceOf(address(child.erc721Tunnel)), 0);

        assertEq(root.erc721Token.balanceOf(alice), 0);
        assertEq(root.erc721Token.ownerOf(tokenId), address(root.erc721Tunnel));

        bytes memory burnMessage = abi.encode(
            address(root.erc721Token),
            address(childToken),
            alice,
            tokenId,
            NULL_DATA
        );

        vm.prank(bob);
        vm.expectEmit(address(child.erc721Tunnel));
        emit MessageSent(burnMessage);
        child.erc721Tunnel.withdrawTo(address(childToken), alice, tokenId, NULL_DATA);

        assertEq(childToken.balanceOf(bob), 0);
        vm.expectRevert("ERC721: owner query for nonexistent token");
        childToken.ownerOf(tokenId);

        root.erc721Tunnel.receiveMessage(burnMessage); // submit burn proof

        assertEq(root.erc721Token.ownerOf(tokenId), alice);
    }

    function test_FxChildCannotWithdrawUnmappedToken() public {
        uint256 tokenId = 1;

        FxERC721 rootToken2 = new FxERC721();
        vm.prank(manager);
        rootToken2.initialize(manager, address(child.erc721Tunnel), "FxERC721", "FE");
        FxERC721 childToken2 = FxERC721(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(rootToken2))),
                root.erc721Tunnel.childTokenTemplateCodeHash(),
                address(child.erc721Tunnel)
            )
        );

        vm.prank(manager);
        rootToken2.mint(alice, tokenId, NULL_DATA);

        vm.expectRevert();
        vm.startPrank(alice);
        child.erc721Tunnel.withdraw(address(childToken2), tokenId, NULL_DATA);

        rootToken2.approve(address(root.erc721Tunnel), tokenId);
        root.erc721Tunnel.deposit(address(rootToken2), alice, tokenId, bytes(""));

        child.erc721Tunnel.withdraw(address(childToken2), tokenId, NULL_DATA);
        vm.stopPrank();
    }

    function test_InvalidSyncType() public {
        bytes32 randomSyncType = keccak256("0x1337");
        bytes memory message = abi.encode(randomSyncType, abi.encode(0));
        vm.expectRevert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        stateSender.syncState(
            address(child.erc721Tunnel),
            abi.encode(address(root.erc721Tunnel), address(child.erc721Tunnel), message)
        );
    }

    function depositOnRoot(address who, uint256 tokenId) internal {
        vm.startPrank(who);
        vm.prank(manager);
        root.erc721Token.mint(who, tokenId, NULL_DATA);
        root.erc721Token.approve(address(root.erc721Tunnel), tokenId);
        root.erc721Tunnel.deposit(address(root.erc721Token), who /*receiver*/, tokenId, bytes(""));
        vm.stopPrank();
    }
}
