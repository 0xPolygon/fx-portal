// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {FxMintableERC1155ChildTunnel} from "contracts/examples/mintable-erc1155-transfer/FxMintableERC1155ChildTunnel.sol";
import {FxMintableERC1155RootTunnel} from "contracts/examples/mintable-erc1155-transfer/FxMintableERC1155RootTunnel.sol";
import {Create2} from "contracts/lib/Create2.sol";
import {FxMintableERC1155} from "contracts/tokens/FxMintableERC1155.sol";
import {FxERC1155} from "contracts/tokens/FxERC1155.sol";

contract FxMintableERC1155TunnelTest is FxBase, Create2 {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    FxMintableERC1155 rootToken;
    FxMintableERC1155 childToken;

    function setUp() public override {
        super.setUp();

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(uniqueId)),
            keccak256(minimalProxyCreationCode(child.erc1155MintableTunnel.childTokenTemplate())),
            address(child.erc1155MintableTunnel)
        );

        address computedRootToken = computedCreate2Address(
            keccak256(abi.encodePacked(computedChildToken)), // rootSalt
            child.erc1155MintableTunnel.rootTokenTemplateCodeHash(),
            address(root.erc1155MintableTunnel)
        );

        childToken = FxMintableERC1155(computedChildToken);
        rootToken = FxMintableERC1155(computedRootToken);
    }

    function test_FxChildDeploy() public {
        assertEq(child.erc1155MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc1155MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        vm.expectEmit(address(child.erc1155MintableTunnel));
        emit TokenMapped(address(rootToken), address(childToken));
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");

        assertEq(child.erc1155MintableTunnel.rootToChildToken(address(rootToken)), address(childToken));
        assertEq(root.erc1155MintableTunnel.rootToChildTokens(address(rootToken)), address(0)); // map on first withdraw
    }

    function test_FxChildDeployFail() public {
        assertEq(child.erc1155MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc1155MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");

        vm.expectRevert("Create2: Failed on minimal deploy");
        child.erc1155MintableTunnel.deployChildToken(
            uniqueId, // reuse
            "ipfs://"
        );
    }

    function test_FxChildWithdraw() public {
        vm.prank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");

        uint256 tokenId = 1337;
        uint256 amt = 1e10;
        assertEq(childToken.balanceOf(alice, tokenId), 0);

        vm.prank(manager);
        childToken.mintToken(alice, tokenId, amt, NULL_DATA);

        assertEq(childToken.balanceOf(alice, tokenId), amt);

        assertEq0(address(rootToken).code, NULL_DATA); // rootToken not deployed yet

        bytes memory burnData = abi.encode(
            child.erc1155MintableTunnel.WITHDRAW(),
            abi.encode(address(rootToken), address(childToken), alice, tokenId, amt, NULL_DATA, childToken.uri(0))
        );
        vm.expectEmit(address(child.erc1155MintableTunnel));
        emit FxWithdrawMintableERC1155(address(rootToken), address(childToken), alice, tokenId, amt);
        vm.expectEmit(address(child.erc1155MintableTunnel));
        emit MessageSent(burnData);
        vm.prank(alice);
        child.erc1155MintableTunnel.withdraw(address(childToken), tokenId, amt, NULL_DATA);

        assertEq(childToken.balanceOf(alice, tokenId), 0);
    }

    function test_FxRootDeploy() public {
        vm.prank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");

        uint256 tokenId = 1337;
        uint256 amt = 1e10;
        assertEq(childToken.balanceOf(alice, tokenId), 0);

        vm.prank(manager);
        childToken.mintToken(alice, tokenId, amt, NULL_DATA);

        assertEq(childToken.balanceOf(alice, tokenId), amt);

        assertEq0(address(rootToken).code, NULL_DATA); // rootToken not deployed yet

        vm.prank(alice);
        child.erc1155MintableTunnel.withdraw(address(childToken), tokenId, amt, NULL_DATA);

        assertEq(childToken.balanceOf(alice, tokenId), 0);

        vm.expectEmit(address(root.erc1155MintableTunnel));
        emit FxWithdrawMintableERC1155(address(rootToken), address(childToken), alice, tokenId, amt);
        vm.prank(alice);
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                child.erc1155MintableTunnel.WITHDRAW(),
                abi.encode(
                    address(rootToken),
                    address(childToken),
                    alice,
                    tokenId,
                    amt,
                    NULL_DATA,
                    abi.encode(childToken.uri(0))
                )
            )
        );

        assertNotEq0(address(rootToken).code, NULL_DATA); // root token creation
        assertEq(rootToken.balanceOf(alice, tokenId), amt);
        assertEq(childToken.balanceOf(alice, tokenId), 0);
    }

    function test_FxRootNoMappingFound() public {
        assertEq(child.erc1155MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc1155MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        FxERC1155 rootTokenSecond = new FxERC1155();
        vm.prank(manager);
        rootTokenSecond.initialize(manager, address(childToken), "ipfs://");

        vm.expectRevert("FxMintableERC1155RootTunnel: NO_MAPPING_FOUND");
        root.erc1155MintableTunnel.deposit(address(rootTokenSecond), alice, 1, 1, NULL_DATA);
        vm.expectRevert("FxMintableERC1155RootTunnel: NO_MAPPING_FOUND");
        root.erc1155MintableTunnel.depositBatch(
            address(rootTokenSecond),
            alice,
            new uint256[](1),
            new uint256[](1),
            NULL_DATA
        );
    }

    function test_FxRootDeposit() public {
        uint256 amt = 1e10;
        uint256 tokenIdOne = 1;
        uint256 tokenIdTwo = 2;
        vm.startPrank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");
        childToken.mintToken(alice, tokenIdOne, amt, NULL_DATA);
        childToken.mintToken(bob, tokenIdTwo, amt, NULL_DATA);
        vm.stopPrank();

        assertEq(childToken.balanceOf(alice, tokenIdOne), amt);
        assertEq(childToken.balanceOf(bob, tokenIdTwo), amt);

        vm.prank(alice);
        child.erc1155MintableTunnel.withdrawTo(address(childToken), bob, tokenIdOne, amt, NULL_DATA);
        assertEq0(address(rootToken).code, NULL_DATA);
        // anyone can call
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                child.erc1155MintableTunnel.WITHDRAW(),
                abi.encode(
                    address(rootToken),
                    address(childToken),
                    bob,
                    tokenIdOne,
                    amt,
                    NULL_DATA,
                    abi.encode(childToken.uri(0))
                )
            )
        );

        assertEq(rootToken.balanceOf(alice, tokenIdOne), 0);
        assertEq(rootToken.balanceOf(bob, tokenIdOne), amt);

        assertEq(childToken.balanceOf(alice, tokenIdOne), 0);
        assertEq(childToken.balanceOf(bob, tokenIdTwo), amt);

        vm.startPrank(bob);
        rootToken.setApprovalForAll(address(root.erc1155MintableTunnel), true);
        root.erc1155MintableTunnel.deposit(address(rootToken), bob, tokenIdOne, amt, NULL_DATA);
        vm.stopPrank();

        assertEq(rootToken.balanceOf(address(root.erc1155MintableTunnel), tokenIdOne), amt); // token locked

        assertEq(childToken.balanceOf(bob, tokenIdOne), amt); // token transfered
    }

    function test_FxChildWithdrawExistingToken() public {
        uint256 tokenId = 1;
        uint256 amt = 1e10;
        vm.startPrank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");
        childToken.mintToken(alice, tokenId, amt, NULL_DATA);
        vm.stopPrank();

        vm.prank(alice);
        child.erc1155MintableTunnel.withdraw(address(childToken), tokenId, amt, NULL_DATA);
        assertEq0(address(rootToken).code, NULL_DATA);
        // anyone can call
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                child.erc1155MintableTunnel.WITHDRAW(),
                abi.encode(
                    address(rootToken),
                    address(childToken),
                    alice,
                    tokenId,
                    amt,
                    NULL_DATA,
                    abi.encode(childToken.uri(0))
                )
            )
        );

        assertEq(rootToken.balanceOf(alice, tokenId), amt);
        assertEq(childToken.balanceOf(alice, tokenId), 0);

        vm.startPrank(alice);
        rootToken.setApprovalForAll(address(root.erc1155MintableTunnel), true);
        root.erc1155MintableTunnel.deposit(address(rootToken), bob, tokenId, amt, NULL_DATA);
        vm.stopPrank();

        assertEq(rootToken.balanceOf(address(root.erc1155MintableTunnel), tokenId), amt); // token locked
        assertEq(childToken.balanceOf(bob, tokenId), amt); // token transfered

        assertNotEq0(address(rootToken).code, NULL_DATA);

        vm.prank(bob);
        child.erc1155MintableTunnel.withdraw(address(childToken), tokenId, amt, NULL_DATA);
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                child.erc1155MintableTunnel.WITHDRAW(),
                abi.encode(
                    address(rootToken),
                    address(childToken),
                    bob,
                    tokenId,
                    amt,
                    NULL_DATA,
                    abi.encode(childToken.uri(0))
                )
            )
        );

        assertEq(rootToken.balanceOf(bob, tokenId), amt);
        assertEq(childToken.balanceOf(alice, tokenId), 0);
    }

    function test_FxChildBobCannotWithdrawAlicesToken() public {
        uint256 tokenId = 1;
        uint256 amt = 1e10;
        vm.startPrank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");
        childToken.mintToken(alice, tokenId, amt, NULL_DATA);
        vm.stopPrank();

        vm.expectRevert("ERC1155: burn amount exceeds balance");
        vm.prank(bob);
        child.erc1155MintableTunnel.withdraw(address(childToken), tokenId, amt, NULL_DATA);

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amts = new uint256[](1);
        ids[0] = tokenId;
        amts[0] = amt;
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        vm.prank(bob);
        child.erc1155MintableTunnel.withdrawBatch(address(childToken), ids, amts, NULL_DATA);
    }

    function test_BatchDepositAndWithdraw() public {
        uint256 len = 5;
        uint256[] memory tokenIds = new uint256[](len);
        uint256[] memory amts = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            tokenIds[i] = i;
            amts[i] = i * 1e5;
        }

        vm.startPrank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");
        childToken.mintTokenBatch(alice, tokenIds, amts, NULL_DATA);
        vm.stopPrank();

        assertEq0(address(rootToken).code, NULL_DATA);

        for (uint256 i; i < len; ++i) {
            assertEq(childToken.balanceOf(alice, tokenIds[i]), amts[i]);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), 0);
        }

        vm.prank(alice);
        child.erc1155MintableTunnel.withdrawBatch(address(childToken), tokenIds, amts, NULL_DATA); // burn
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                child.erc1155MintableTunnel.WITHDRAW_BATCH(),
                abi.encode(
                    address(rootToken),
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
            assertEq(childToken.balanceOf(alice, tokenIds[i]), 0);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), 0);

            assertEq(rootToken.balanceOf(alice, tokenIds[i]), amts[i]);
            assertEq(rootToken.balanceOf(bob, tokenIds[i]), 0);
        }

        vm.startPrank(alice);
        rootToken.setApprovalForAll(address(root.erc1155MintableTunnel), true);
        root.erc1155MintableTunnel.depositBatch(address(rootToken), bob, tokenIds, amts, NULL_DATA);
        vm.stopPrank();

        for (uint256 i; i < len; ++i) {
            assertEq(childToken.balanceOf(alice, tokenIds[i]), 0);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), amts[i]);

            assertEq(rootToken.balanceOf(alice, tokenIds[i]), 0);
            assertEq(rootToken.balanceOf(bob, tokenIds[i]), 0);

            assertEq(rootToken.balanceOf(address(root.erc1155MintableTunnel), tokenIds[i]), amts[i]); // token locked
        }

        vm.prank(bob);
        child.erc1155MintableTunnel.withdrawToBatch(address(childToken), alice, tokenIds, amts, NULL_DATA);
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                child.erc1155MintableTunnel.WITHDRAW_BATCH(),
                abi.encode(
                    address(rootToken),
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
            assertEq(childToken.balanceOf(alice, tokenIds[i]), 0);
            assertEq(childToken.balanceOf(bob, tokenIds[i]), 0);

            assertEq(rootToken.balanceOf(alice, tokenIds[i]), amts[i]);
            assertEq(rootToken.balanceOf(bob, tokenIds[i]), 0);
        }
    }

    function test_FxRootInvalidMappingOnExit() public {
        vm.prank(manager);
        child.erc1155MintableTunnel.deployChildToken(uniqueId, "ipfs://");

        bytes32 withdrawType = child.erc1155MintableTunnel.WITHDRAW();
        bytes32 withdrawBatchType = child.erc1155MintableTunnel.WITHDRAW_BATCH();

        vm.expectRevert("FxMintableERC1155RootTunnel: INVALID_MAPPING_ON_EXIT");
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                withdrawType,
                abi.encode(
                    address(childToken), // inverse
                    address(rootToken),
                    alice,
                    1,
                    1,
                    NULL_DATA,
                    "ipfs://"
                )
            )
        );
        vm.expectRevert("FxMintableERC1155RootTunnel: INVALID_MAPPING_ON_EXIT");
        root.erc1155MintableTunnel.receiveMessage(
            abi.encode(
                withdrawBatchType,
                abi.encode(
                    address(childToken), // inverse
                    address(rootToken),
                    alice,
                    new uint256[](1),
                    new uint256[](1),
                    NULL_DATA,
                    "ipfs://"
                )
            )
        );
    }

    function test_InvalidSyncType() public {
        bytes32 randomSyncType = keccak256("0x1337");
        bytes memory message = abi.encode(randomSyncType, abi.encode(0));
        vm.expectRevert("FxMintableERC1155ChildTunnel: INVALID_SYNC_TYPE");
        stateSender.syncState(
            address(child.erc1155MintableTunnel),
            abi.encode(address(root.erc1155MintableTunnel), address(child.erc1155MintableTunnel), message)
        );
    }
}
