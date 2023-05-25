// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {FxERC1155ChildTunnel} from "contracts/examples/erc1155-transfer/FxERC1155ChildTunnel.sol";
import {FxERC1155RootTunnel} from "contracts/examples/erc1155-transfer/FxERC1155RootTunnel.sol";
import {FxERC1155} from "contracts/tokens/FxERC1155.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract FxERC1155TunnelTest is FxBase {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public override {
        super.setUp();
    }

    function test_FxRootMapToken() public {
        assertEq(child.erc1155Tunnel.rootToChildToken(address(root.erc1155Token)), address(0));
        assertEq(root.erc1155Tunnel.rootToChildTokens(address(root.erc1155Token)), address(0));

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(address(root.erc1155Token))),
            root.erc1155Tunnel.childTokenTemplateCodeHash(),
            address(child.erc1155Tunnel)
        );

        vm.expectEmit(address(child.erc1155Tunnel));
        emit TokenMapped(address(root.erc1155Token), computedChildToken);
        vm.expectEmit(address(root.erc1155Tunnel));
        emit TokenMappedERC1155(address(root.erc1155Token), computedChildToken);

        root.erc1155Tunnel.mapToken(address(root.erc1155Token));

        assertEq(child.erc1155Tunnel.rootToChildToken(address(root.erc1155Token)), computedChildToken);
        assertEq(root.erc1155Tunnel.rootToChildTokens(address(root.erc1155Token)), computedChildToken);
    }

    function test_AlreadyMappedRevert() public {
        root.erc1155Tunnel.mapToken(address(root.erc1155Token));

        vm.expectRevert("FxERC1155RootTunnel: ALREADY_MAPPED");
        root.erc1155Tunnel.mapToken(address(root.erc1155Token));

        bytes memory mockMessage = abi.encode(
            root.erc1155Tunnel.MAP_TOKEN(),
            abi.encode(address(root.erc1155Token), "ipfs://")
        );

        vm.expectRevert("FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        fxRoot.sendMessageToChild(address(child.erc1155Tunnel), mockMessage);

        vm.expectRevert("FxERC1155ChildTunnel: ALREADY_MAPPED");
        vm.prank(address(root.erc1155Tunnel));
        fxRoot.sendMessageToChild(address(child.erc1155Tunnel), mockMessage);
    }

    function test_FxRootDepositWithMapToken() public {
        FxERC1155 childToken = FxERC1155(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(root.erc1155Token))),
                root.erc1155Tunnel.childTokenTemplateCodeHash(),
                address(child.erc1155Tunnel)
            )
        );
        uint256 tokenId = 1;
        uint256 amt = 1e10;
        vm.prank(manager);
        root.erc1155Token.mint(alice, tokenId, amt, NULL_DATA);
        vm.startPrank(alice); // depositor
        root.erc1155Token.setApprovalForAll(address(root.erc1155Tunnel), true);

        vm.expectEmit(address(child.erc1155Tunnel));
        emit TokenMapped(address(root.erc1155Token), address(childToken));
        vm.expectEmit(address(root.erc1155Tunnel));
        emit TokenMappedERC1155(address(root.erc1155Token), address(childToken));
        vm.expectEmit(address(root.erc1155Tunnel));
        emit FxDepositERC1155(address(root.erc1155Token), alice, bob, tokenId, amt);

        root.erc1155Tunnel.deposit(address(root.erc1155Token), bob /*receiver*/, tokenId, amt, bytes(""));

        assertEq(childToken.balanceOf(bob, tokenId), amt);
        assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenId), 0);

        assertEq(root.erc1155Token.balanceOf(alice, tokenId), 0);
        assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenId), amt);

        vm.stopPrank();
    }

    function test_FxRootDepositAfterMapToken() public {
        uint256 tokenId = 1;
        uint256 amt = 1e10;

        root.erc1155Tunnel.mapToken(address(root.erc1155Token));
        FxERC1155 childToken = FxERC1155(root.erc1155Tunnel.rootToChildTokens(address(root.erc1155Token)));

        vm.prank(manager);
        root.erc1155Token.mint(alice, tokenId, amt, NULL_DATA);
        vm.startPrank(alice); // depositor
        root.erc1155Token.setApprovalForAll(address(root.erc1155Tunnel), true);

        vm.expectEmit(address(root.erc1155Tunnel));
        emit FxDepositERC1155(address(root.erc1155Token), alice, bob, tokenId, amt);

        root.erc1155Tunnel.deposit(address(root.erc1155Token), bob /*user*/, tokenId, amt, bytes(""));

        assertEq(childToken.balanceOf(bob, tokenId), amt);
        assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenId), 0);

        assertEq(root.erc1155Token.balanceOf(alice, tokenId), 0);
        assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenId), amt);

        vm.stopPrank();
    }

    function test_FxChildWithdraw() public {
        uint256 tokenId = 1;
        uint256 amt = 1e10;

        vm.prank(manager);
        root.erc1155Token.mint(alice, tokenId, amt, NULL_DATA);

        vm.startPrank(alice); // depositor
        root.erc1155Token.setApprovalForAll(address(root.erc1155Tunnel), true);
        root.erc1155Tunnel.deposit(address(root.erc1155Token), bob /*user*/, tokenId, amt, bytes(""));
        vm.stopPrank();
        FxERC1155 childToken = FxERC1155(root.erc1155Tunnel.rootToChildTokens(address(root.erc1155Token)));

        assertEq(childToken.balanceOf(bob, tokenId), amt);
        assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenId), 0);

        assertEq(root.erc1155Token.balanceOf(alice, tokenId), 0);
        assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenId), amt);

        bytes memory burnMessage = abi.encode(
            child.erc1155Tunnel.WITHDRAW(),
            abi.encode(address(root.erc1155Token), address(childToken), bob, tokenId, amt, NULL_DATA)
        );

        vm.prank(bob);
        vm.expectEmit(address(child.erc1155Tunnel));
        emit MessageSent(burnMessage);
        child.erc1155Tunnel.withdraw(address(childToken), tokenId, amt, NULL_DATA);

        assertEq(childToken.balanceOf(bob, tokenId), 0);
    }

    function test_FxChildWithdrawSyncOnRoot() public {
        uint256 tokenId = 1;
        uint256 amt = 1e10;

        vm.prank(manager);
        root.erc1155Token.mint(alice, tokenId, amt, NULL_DATA);

        vm.startPrank(alice); // depositor
        root.erc1155Token.setApprovalForAll(address(root.erc1155Tunnel), true);
        root.erc1155Tunnel.deposit(address(root.erc1155Token), bob /*user*/, tokenId, amt, bytes(""));
        vm.stopPrank();
        FxERC1155 childToken = FxERC1155(root.erc1155Tunnel.rootToChildTokens(address(root.erc1155Token)));

        assertEq(childToken.balanceOf(bob, tokenId), amt);
        assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenId), 0);

        assertEq(root.erc1155Token.balanceOf(alice, tokenId), 0);
        assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenId), amt);

        bytes memory burnMessage = abi.encode(
            child.erc1155Tunnel.WITHDRAW(),
            abi.encode(address(root.erc1155Token), address(childToken), alice, tokenId, amt, NULL_DATA)
        );

        vm.prank(bob);
        vm.expectEmit(address(child.erc1155Tunnel));
        emit MessageSent(burnMessage);
        child.erc1155Tunnel.withdrawTo(address(childToken), alice, tokenId, amt, NULL_DATA);

        assertEq(childToken.balanceOf(bob, tokenId), 0);

        root.erc1155Tunnel.receiveMessage(burnMessage); // submit burn proof

        assertEq(root.erc1155Token.balanceOf(alice, tokenId), amt);
    }

    function test_FxChildCannotWithdrawUnmappedToken() public {
        uint256 tokenId = 1;
        uint256 amt = 1e10;

        FxERC1155 rootToken2 = new FxERC1155();
        vm.prank(manager);
        rootToken2.initialize(manager, address(child.erc1155Tunnel), "ipfs://");
        FxERC1155 childToken2 = FxERC1155(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(rootToken2))),
                root.erc1155Tunnel.childTokenTemplateCodeHash(),
                address(child.erc1155Tunnel)
            )
        );

        vm.prank(manager);
        rootToken2.mint(alice, tokenId, amt, NULL_DATA);

        vm.expectRevert();
        vm.startPrank(alice);
        child.erc1155Tunnel.withdraw(address(childToken2), tokenId, amt, NULL_DATA);

        rootToken2.setApprovalForAll(address(root.erc1155Tunnel), true);
        root.erc1155Tunnel.deposit(address(rootToken2), alice, tokenId, amt, bytes(""));

        child.erc1155Tunnel.withdraw(address(childToken2), tokenId, amt, NULL_DATA);
        vm.stopPrank();
    }

    function test_BatchDepositAndWithdraw() public {
        FxERC1155 childToken = FxERC1155(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(root.erc1155Token))),
                root.erc1155Tunnel.childTokenTemplateCodeHash(),
                address(child.erc1155Tunnel)
            )
        );

        uint256 len = 5;
        uint256[] memory tokenIds = new uint256[](len);
        uint256[] memory amts = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            tokenIds[i] = i;
            amts[i] = i * 1e5;
        }

        vm.startPrank(manager);
        root.erc1155Token.mintBatch(alice, tokenIds, amts, NULL_DATA);
        root.erc1155Token.mintBatch(bob, tokenIds, amts, NULL_DATA);
        vm.stopPrank();

        for (uint256 i; i < len; ++i) {
            assertEq(root.erc1155Token.balanceOf(alice, tokenIds[i]), amts[i]);
            assertEq(root.erc1155Token.balanceOf(bob, tokenIds[i]), amts[i]);
        }

        vm.startPrank(alice);
        root.erc1155Token.setApprovalForAll(address(root.erc1155Tunnel), true);
        root.erc1155Tunnel.depositBatch(address(root.erc1155Token), alice, tokenIds, amts, NULL_DATA);
        vm.stopPrank();

        for (uint256 i; i < len; ++i) {
            assertEq(root.erc1155Token.balanceOf(alice, tokenIds[i]), 0);
            assertEq(root.erc1155Token.balanceOf(bob, tokenIds[i]), amts[i]);

            assertEq(childToken.balanceOf(alice, tokenIds[i]), amts[i]);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), 0);

            assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenIds[i]), amts[i]); // token locked
            assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenIds[i]), 0);
        }

        vm.prank(alice);
        child.erc1155Tunnel.withdrawBatch(address(childToken), tokenIds, amts, NULL_DATA); // burn
        root.erc1155Tunnel.receiveMessage(
            abi.encode(
                child.erc1155Tunnel.WITHDRAW_BATCH(),
                abi.encode(
                    address(root.erc1155Token),
                    address(childToken),
                    alice,
                    tokenIds,
                    amts,
                    NULL_DATA,
                    abi.encode(childToken.uri(0))
                )
            )
        ); // claim

        for (uint256 i; i < len; ++i) {
            assertEq(root.erc1155Token.balanceOf(alice, tokenIds[i]), amts[i]);
            assertEq(root.erc1155Token.balanceOf(bob, tokenIds[i]), amts[i]);

            assertEq(childToken.balanceOf(alice, tokenIds[i]), 0);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), 0);

            assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenIds[i]), 0); // token released
            assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenIds[i]), 0);
        }

        vm.startPrank(bob);
        root.erc1155Token.setApprovalForAll(address(root.erc1155Tunnel), true);
        root.erc1155Tunnel.depositBatch(address(root.erc1155Token), bob, tokenIds, amts, NULL_DATA);
        child.erc1155Tunnel.withdrawToBatch(address(childToken), alice, tokenIds, amts, NULL_DATA);
        root.erc1155Tunnel.receiveMessage(
            abi.encode(
                child.erc1155Tunnel.WITHDRAW_BATCH(),
                abi.encode(
                    address(root.erc1155Token),
                    address(childToken),
                    alice,
                    tokenIds,
                    amts,
                    NULL_DATA,
                    abi.encode(childToken.uri(0))
                )
            )
        );

        for (uint256 i; i < len; ++i) {
            assertEq(root.erc1155Token.balanceOf(alice, tokenIds[i]), 2 * amts[i]);
            assertEq(root.erc1155Token.balanceOf(bob, tokenIds[i]), 0);

            assertEq(childToken.balanceOf(alice, tokenIds[i]), 0);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), 0);

            assertEq(root.erc1155Token.balanceOf(address(root.erc1155Tunnel), tokenIds[i]), 0); // token released
            assertEq(childToken.balanceOf(address(child.erc1155Tunnel), tokenIds[i]), 0);
        }
    }

    function test_InvalidSyncType() public {
        bytes32 randomSyncType = keccak256("0x1337");
        bytes memory message = abi.encode(randomSyncType, abi.encode(0));
        vm.expectRevert("FxERC1155ChildTunnel: INVALID_SYNC_TYPE");
        stateSender.syncState(
            address(child.erc1155Tunnel),
            abi.encode(address(root.erc1155Tunnel), address(child.erc1155Tunnel), message)
        );
    }
}
