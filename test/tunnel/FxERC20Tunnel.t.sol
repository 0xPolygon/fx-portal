// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {FxERC20ChildTunnel} from "contracts/examples/erc20-transfer/FxERC20ChildTunnel.sol";
import {FxERC20RootTunnel} from "contracts/examples/erc20-transfer/FxERC20RootTunnel.sol";
import {FxERC20} from "contracts/tokens/FxERC20.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract FxERC20TunnelTest is FxBase {
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public override {
        super.setUp();
    }

    function test_FxRootMapToken() public {
        assertEq(erc20ChildTunnel.rootToChildToken(erc20RootToken), address(0));
        assertEq(erc20RootTunnel.rootToChildTokens(erc20RootToken), address(0));

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(erc20RootToken)),
            erc20RootTunnel.childTokenTemplateCodeHash(),
            address(erc20ChildTunnel)
        );

        vm.expectEmit(true, true, true, true, address(erc20ChildTunnel));
        emit TokenMapped(erc20RootToken, computedChildToken);
        vm.expectEmit(true, true, true, true, address(erc20RootTunnel));
        emit TokenMappedERC20(erc20RootToken, computedChildToken);

        erc20RootTunnel.mapToken(erc20RootToken);

        assertEq(erc20ChildTunnel.rootToChildToken(erc20RootToken), computedChildToken);
        assertEq(erc20RootTunnel.rootToChildTokens(erc20RootToken), computedChildToken);

        FxERC20 childToken = FxERC20(computedChildToken);
        FxERC20 rootToken = FxERC20(erc20RootToken);
        assertEq(childToken.decimals(), rootToken.decimals());
    }

    function test_AlreadyMappedRevert() public {
        erc20RootTunnel.mapToken(erc20RootToken);

        vm.expectRevert("FxERC20RootTunnel: ALREADY_MAPPED");
        erc20RootTunnel.mapToken(erc20RootToken);

        bytes memory mockMessage = abi.encode(
            erc20RootTunnel.MAP_TOKEN(),
            abi.encode(erc20RootToken, "mock", "MOCK", 18)
        );

        vm.expectRevert("FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        fxRoot.sendMessageToChild(address(erc20ChildTunnel), mockMessage);

        vm.expectRevert("FxERC20ChildTunnel: ALREADY_MAPPED");
        vm.prank(address(erc20RootTunnel));
        fxRoot.sendMessageToChild(address(erc20ChildTunnel), mockMessage);
    }

    function test_FxRootDepositWithMapToken() public {
        FxERC20 childToken = FxERC20(
            computeCreate2Address(
                keccak256(abi.encodePacked(erc20RootToken)),
                erc20RootTunnel.childTokenTemplateCodeHash(),
                address(erc20ChildTunnel)
            )
        );
        uint256 amt = 10 ether;
        vm.startPrank(alice); // depositor
        deal(erc20RootToken, alice, amt);
        FxERC20(erc20RootToken).approve(address(erc20RootTunnel), amt);

        vm.expectEmit(true, true, true, true, address(erc20ChildTunnel));
        emit TokenMapped(erc20RootToken, address(childToken));
        vm.expectEmit(true, true, true, true, address(erc20RootTunnel));
        emit TokenMappedERC20(erc20RootToken, address(childToken));
        vm.expectEmit(true, true, true, true, address(childToken));
        emit Transfer(address(0), bob, amt);
        vm.expectEmit(true, true, true, true, address(erc20RootTunnel));
        emit FxDepositERC20(erc20RootToken, alice, bob, amt);

        erc20RootTunnel.deposit(erc20RootToken, bob /*receiver*/, amt, bytes(""));

        assertEq(childToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(address(erc20ChildTunnel)), 0);

        assertEq(FxERC20(erc20RootToken).balanceOf(alice), 0);
        assertEq(FxERC20(erc20RootToken).balanceOf(address(erc20RootTunnel)), amt);

        vm.stopPrank();
    }

    function test_FxRootDepositAfterMapToken(uint amt) public {
        erc20RootTunnel.mapToken(erc20RootToken);
        FxERC20 childToken = FxERC20(erc20RootTunnel.rootToChildTokens(erc20RootToken));

        // uint256 amt = 10 ether;
        vm.startPrank(alice); // depositor
        deal(erc20RootToken, alice, amt);
        FxERC20(erc20RootToken).approve(address(erc20RootTunnel), amt);

        vm.expectEmit(true, true, true, true, address(childToken));
        emit Transfer(address(0), bob, amt);
        vm.expectEmit(true, true, true, true, address(erc20RootTunnel));
        emit FxDepositERC20(erc20RootToken, alice, bob, amt);

        erc20RootTunnel.deposit(erc20RootToken, bob /*user*/, amt, bytes(""));

        assertEq(childToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(address(erc20ChildTunnel)), 0);

        assertEq(FxERC20(erc20RootToken).balanceOf(alice), 0);
        assertEq(FxERC20(erc20RootToken).balanceOf(address(erc20RootTunnel)), amt);

        vm.stopPrank();
    }

    function test_FxChildWithdraw() public {
        uint256 amt = 10 ether;
        uint256 withdrawAmt = 1 ether;

        vm.startPrank(alice); // depositor
        deal(erc20RootToken, alice, amt);
        FxERC20(erc20RootToken).approve(address(erc20RootTunnel), amt);

        erc20RootTunnel.deposit(erc20RootToken, bob /*user*/, amt, bytes(""));
        vm.stopPrank();
        FxERC20 childToken = FxERC20(erc20RootTunnel.rootToChildTokens(erc20RootToken));

        assertEq(childToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(address(erc20ChildTunnel)), 0);

        assertEq(FxERC20(erc20RootToken).balanceOf(alice), 0);
        assertEq(FxERC20(erc20RootToken).balanceOf(address(erc20RootTunnel)), amt);

        bytes memory burnMessage = abi.encode(erc20RootToken, address(childToken), bob, withdrawAmt);

        vm.prank(bob);
        vm.expectEmit(true, true, true, true, address(childToken));
        emit Transfer(bob, address(0), withdrawAmt);
        vm.expectEmit(true, true, true, true, address(erc20ChildTunnel));
        emit MessageSent(burnMessage);
        erc20ChildTunnel.withdraw(address(childToken), withdrawAmt);

        assertEq(childToken.balanceOf(bob), amt - withdrawAmt);
        assertEq(childToken.balanceOf(address(erc20ChildTunnel)), 0);
    }

    function test_FxChildWithdrawSyncOnRoot() public {
        uint256 amt = 10 ether;
        uint256 withdrawAmt = 1 ether;

        depositOnRoot(bob, amt);

        FxERC20 childToken = FxERC20(erc20RootTunnel.rootToChildTokens(erc20RootToken));

        bytes memory burnMessage = abi.encode(erc20RootToken, address(childToken), bob, withdrawAmt);

        vm.prank(bob);
        vm.expectEmit(true, true, true, true, address(childToken));
        emit Transfer(bob, address(0), withdrawAmt);
        vm.expectEmit(true, true, true, true, address(erc20ChildTunnel));
        emit MessageSent(burnMessage);
        erc20ChildTunnel.withdraw(address(childToken), withdrawAmt);

        assertEq(childToken.balanceOf(bob), amt - withdrawAmt);
        assertEq(childToken.balanceOf(address(erc20ChildTunnel)), 0);

        FxERC20 rootToken = FxERC20(erc20RootToken);
        assertEq(rootToken.balanceOf(bob), 0);
        assertEq(rootToken.balanceOf(address(erc20RootTunnel)), amt);

        erc20RootTunnel.receiveMessage(burnMessage); // submit burn proof

        assertEq(rootToken.balanceOf(bob), withdrawAmt);
        assertEq(rootToken.balanceOf(address(erc20RootTunnel)), amt - withdrawAmt);
    }

    function test_FxChildCannotWithdrawMore() public {
        uint256 amt = 10 ether;

        depositOnRoot(alice, amt); // alice deposits amt for herself
        depositOnRoot(bob, amt); // bob deposits amt for himself
        depositOnRoot(charlie, amt / 2); // charlie deposits amt/2 for himself

        FxERC20 childToken = FxERC20(erc20RootTunnel.rootToChildTokens(erc20RootToken));
        FxERC20 rootToken = FxERC20(erc20RootToken);

        // charlie cannot withdraw more than amt/2
        vm.expectRevert("ERC20: burn amount exceeds balance");
        vm.prank(charlie);
        erc20ChildTunnel.withdraw(address(childToken), amt);

        vm.prank(charlie);
        erc20ChildTunnel.withdraw(address(childToken), amt / 2);

        assertEq(childToken.balanceOf(charlie), 0);
        assertEq(rootToken.balanceOf(charlie), 0); // yet to exit

        assertEq(rootToken.balanceOf(address(erc20RootTunnel)), 2 * amt + (amt / 2)); // alice, bob, charlie deposits
        erc20RootTunnel.receiveMessage(abi.encode(erc20RootToken, address(childToken), charlie, amt / 2)); // charlie exits
        assertEq(rootToken.balanceOf(address(erc20RootTunnel)), 2 * amt); // alice, bob deposits
        assertEq(rootToken.balanceOf(charlie), amt / 2);
    }

    function test_FxChildCannotWithdrawUnmappedToken() public {
        uint256 amt = 10 ether;

        FxERC20 rootToken2 = new FxERC20();
        vm.prank(manager);
        rootToken2.initialize(manager, address(erc20ChildTunnel), "FxERC20", "FE", 18);
        FxERC20 childToken2 = FxERC20(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(rootToken2))),
                erc20RootTunnel.childTokenTemplateCodeHash(),
                address(erc20ChildTunnel)
            )
        );

        vm.expectRevert();
        vm.startPrank(alice);
        erc20ChildTunnel.withdraw(address(childToken2), amt);

        deal(address(rootToken2), alice, amt);
        rootToken2.approve(address(erc20RootTunnel), amt);
        erc20RootTunnel.deposit(address(rootToken2), alice, amt, bytes(""));

        erc20ChildTunnel.withdraw(address(childToken2), amt);
        vm.stopPrank();
    }

    function depositOnRoot(address who, uint256 amt) internal {
        vm.startPrank(who);
        deal(erc20RootToken, who, amt);
        FxERC20(erc20RootToken).approve(address(erc20RootTunnel), amt);
        erc20RootTunnel.deposit(erc20RootToken, who /*receiver*/, amt, bytes(""));
        vm.stopPrank();
    }
}
