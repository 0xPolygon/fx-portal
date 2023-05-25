// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {FxMintableERC20ChildTunnel} from "contracts/examples/mintable-erc20-transfer/FxMintableERC20ChildTunnel.sol";
import {FxMintableERC20RootTunnel} from "contracts/examples/mintable-erc20-transfer/FxMintableERC20RootTunnel.sol";
import {Create2} from "contracts/lib/Create2.sol";
import {FxMintableERC20} from "contracts/tokens/FxMintableERC20.sol";
import {FxERC20} from "contracts/tokens/FxERC20.sol";

contract FxMintableERC20TunnelTest is FxBase, Create2 {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    FxMintableERC20 rootToken;
    FxMintableERC20 childToken;

    function setUp() public override {
        super.setUp();

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(uniqueId)),
            keccak256(minimalProxyCreationCode(child.erc20MintableTunnel.childTokenTemplate())),
            address(child.erc20MintableTunnel)
        );

        address computedRootToken = computedCreate2Address(
            keccak256(abi.encodePacked(computedChildToken)), // rootSalt
            child.erc20MintableTunnel.rootTokenTemplateCodeHash(),
            address(root.erc20MintableTunnel)
        );

        childToken = FxMintableERC20(computedChildToken);
        rootToken = FxMintableERC20(computedRootToken);
    }

    function test_FxChildDeploy() public {
        assertEq(child.erc20MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc20MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        vm.expectEmit(address(child.erc20MintableTunnel));
        emit TokenMapped(address(rootToken), address(childToken));
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);

        assertEq(child.erc20MintableTunnel.rootToChildToken(address(rootToken)), address(childToken));
        assertEq(root.erc20MintableTunnel.rootToChildTokens(address(rootToken)), address(0)); // map on first withdraw
    }

    function test_FxChildDeployFail() public {
        assertEq(child.erc20MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc20MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);

        vm.expectRevert("Create2: Failed on minimal deploy");
        child.erc20MintableTunnel.deployChildToken(
            uniqueId, // reuse
            "FxMintableERC20",
            "FM1",
            18
        );
    }

    function test_FxChildWithdraw() public {
        vm.prank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);

        uint256 amt = 1e10;
        assertEq(childToken.balanceOf(alice), 0);

        vm.prank(manager);
        childToken.mintToken(alice, amt);

        assertEq(childToken.balanceOf(alice), amt);

        assertEq0(address(rootToken).code, NULL_DATA); // rootToken not deployed yet

        bytes memory burnData = abi.encode(
            address(rootToken),
            address(childToken),
            alice,
            amt,
            abi.encode(childToken.name(), childToken.symbol(), childToken.decimals())
        );
        vm.expectEmit(address(child.erc20MintableTunnel));
        emit FxWithdrawMintableERC20(address(rootToken), address(childToken), alice, amt);
        vm.expectEmit(address(child.erc20MintableTunnel));
        emit MessageSent(burnData);
        vm.prank(alice);
        child.erc20MintableTunnel.withdraw(address(childToken), amt);

        assertEq(childToken.balanceOf(alice), 0);
    }

    function test_FxRootDeploy() public {
        vm.prank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);

        uint256 amt = 1e10;
        assertEq(childToken.balanceOf(alice), 0);

        vm.prank(manager);
        childToken.mintToken(alice, amt);

        assertEq(childToken.balanceOf(alice), amt);

        assertEq0(address(rootToken).code, NULL_DATA); // rootToken not deployed yet

        bytes memory burnData = abi.encode(
            address(rootToken),
            address(childToken),
            alice,
            amt,
            abi.encode(childToken.name(), childToken.symbol(), childToken.decimals())
        );
        vm.prank(alice);
        child.erc20MintableTunnel.withdraw(address(childToken), amt);

        assertEq(childToken.balanceOf(alice), 0);

        vm.expectEmit(address(root.erc20MintableTunnel));
        emit FxWithdrawMintableERC20(address(rootToken), address(childToken), alice, amt);
        vm.prank(alice);
        root.erc20MintableTunnel.receiveMessage(burnData);

        assertNotEq0(address(rootToken).code, NULL_DATA); // root token creation
        assertEq(rootToken.balanceOf(alice), amt);
    }

    function test_FxRootNoMappingFound() public {
        assertEq(child.erc20MintableTunnel.rootToChildToken(address(rootToken)), address(0));
        assertEq(root.erc20MintableTunnel.rootToChildTokens(address(rootToken)), address(0));

        FxERC20 rootTokenSecond = new FxERC20();
        vm.prank(manager);
        rootTokenSecond.initialize(manager, address(childToken), "", "FE2", 18);

        vm.expectRevert("FxMintableERC20RootTunnel: NO_MAPPING_FOUND");
        root.erc20MintableTunnel.deposit(address(rootTokenSecond), alice, 1, NULL_DATA);
    }

    function test_FxRootDeposit() public {
        uint256 amt = 1e10;
        vm.startPrank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);
        childToken.mintToken(alice, amt);
        childToken.mintToken(bob, amt);
        vm.stopPrank();

        vm.prank(alice);
        child.erc20MintableTunnel.withdrawTo(bob, address(childToken), amt);
        assertEq0(address(rootToken).code, NULL_DATA);
        vm.prank(manager);
        root.erc20MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                bob,
                amt,
                abi.encode(childToken.name(), childToken.symbol(), childToken.decimals())
            )
        );

        assertEq(rootToken.balanceOf(alice), 0);
        assertEq(rootToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(bob), amt);

        vm.startPrank(bob);
        rootToken.approve(address(root.erc20MintableTunnel), amt);
        root.erc20MintableTunnel.deposit(address(rootToken), bob, amt, NULL_DATA);
        vm.stopPrank();

        assertEq(rootToken.balanceOf(address(root.erc20MintableTunnel)), amt); // token locked
        assertEq(childToken.balanceOf(bob), 2 * amt);
    }

    function test_FxChildWithdrawExistingToken() public {
        uint256 amt = 1e10;
        vm.startPrank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);
        childToken.mintToken(alice, amt);
        vm.stopPrank();

        vm.prank(alice);
        child.erc20MintableTunnel.withdraw(address(childToken), amt);
        assertEq0(address(rootToken).code, NULL_DATA);
        vm.prank(manager);
        root.erc20MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                alice,
                amt,
                abi.encode(childToken.name(), childToken.symbol(), childToken.decimals())
            )
        );

        assertEq(rootToken.balanceOf(alice), amt);

        vm.startPrank(alice);
        rootToken.approve(address(root.erc20MintableTunnel), amt);
        root.erc20MintableTunnel.deposit(address(rootToken), bob, amt, NULL_DATA);
        vm.stopPrank();

        assertEq(rootToken.balanceOf(address(root.erc20MintableTunnel)), amt); // token locked
        assertEq(childToken.balanceOf(bob), amt); // token transfered

        assertNotEq0(address(rootToken).code, NULL_DATA);

        vm.prank(bob);
        child.erc20MintableTunnel.withdraw(address(childToken), amt);

        root.erc20MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                bob,
                amt,
                abi.encode(childToken.name(), childToken.symbol(), childToken.decimals())
            )
        );

        assertEq(rootToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(alice), 0);
    }

    function test_FxChildBobCannotWithdrawAlicesToken() public {
        uint256 amt = 1e10;
        vm.startPrank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableerc20", "FM1", 18);
        childToken.mintToken(alice, amt);
        vm.stopPrank();

        vm.expectRevert("ERC20: burn amount exceeds balance");
        vm.prank(bob);
        child.erc20MintableTunnel.withdraw(address(childToken), amt);
    }

    function test_FxRootTokenInvalidMappingOnExit() public {
        vm.prank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);

        vm.expectRevert("FxERC20RootTunnel: INVALID_MAPPING_ON_EXIT");
        root.erc20MintableTunnel.receiveMessage(
            abi.encode(
                address(childToken), // inverse
                address(rootToken),
                bob,
                1,
                abi.encode("", "", 18)
            )
        );
    }

    function test_FxChildContractReceiver() public {
        uint256 amt = 1e10;
        vm.startPrank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableerc20", "FM1", 18);
        childToken.mintToken(alice, amt);
        vm.stopPrank();

        vm.startPrank(alice);
        child.erc20MintableTunnel.withdraw(address(childToken), amt);
        root.erc20MintableTunnel.receiveMessage(
            abi.encode(
                address(rootToken),
                address(childToken),
                alice,
                amt,
                abi.encode(childToken.name(), childToken.symbol(), childToken.decimals())
            )
        );
        rootToken.approve(address(root.erc20MintableTunnel), amt);
        root.erc20MintableTunnel.deposit(address(rootToken), address(fxChild), amt, NULL_DATA);
        vm.stopPrank();
    }

    function test_FxRootTokenCreationMismatch() public {
        vm.prank(manager);
        child.erc20MintableTunnel.deployChildToken(uniqueId, "FxMintableERC20", "FM1", 18);

        vm.expectRevert("FxMintableERC20RootTunnel: ROOT_TOKEN_CREATION_MISMATCH");
        root.erc20MintableTunnel.receiveMessage(
            abi.encode(address(0x1337), address(childToken), bob, 1, abi.encode("", "", 18))
        );
    }

    function test_InvalidSyncType() public {
        bytes32 randomSyncType = keccak256("0x1337");
        bytes memory message = abi.encode(randomSyncType, abi.encode(0));
        vm.expectRevert("FxMintableERC20ChildTunnel: INVALID_SYNC_TYPE");
        stateSender.syncState(
            address(child.erc20MintableTunnel),
            abi.encode(address(root.erc20MintableTunnel), address(child.erc20MintableTunnel), message)
        );
    }
}
