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
        assertEq(child.erc20Tunnel.rootToChildToken(address(root.erc20Token)), address(0));
        assertEq(root.erc20Tunnel.rootToChildTokens(address(root.erc20Token)), address(0));

        address computedChildToken = computeCreate2Address(
            keccak256(abi.encodePacked(address(root.erc20Token))),
            root.erc20Tunnel.childTokenTemplateCodeHash(),
            address(child.erc20Tunnel)
        );

        vm.expectEmit(address(child.erc20Tunnel));
        emit TokenMapped(address(root.erc20Token), computedChildToken);
        vm.expectEmit(address(root.erc20Tunnel));
        emit TokenMappedERC20(address(root.erc20Token), computedChildToken);

        root.erc20Tunnel.mapToken(address(root.erc20Token));

        assertEq(child.erc20Tunnel.rootToChildToken(address(root.erc20Token)), computedChildToken);
        assertEq(root.erc20Tunnel.rootToChildTokens(address(root.erc20Token)), computedChildToken);

        FxERC20 childToken = FxERC20(computedChildToken);
        assertEq(childToken.decimals(), root.erc20Token.decimals());
    }

    function test_AlreadyMappedRevert() public {
        root.erc20Tunnel.mapToken(address(root.erc20Token));

        vm.expectRevert("FxERC20RootTunnel: ALREADY_MAPPED");
        root.erc20Tunnel.mapToken(address(root.erc20Token));

        bytes memory mockMessage = abi.encode(
            root.erc20Tunnel.MAP_TOKEN(),
            abi.encode(address(root.erc20Token), "mock", "MOCK", 18)
        );

        vm.expectRevert("FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        fxRoot.sendMessageToChild(address(child.erc20Tunnel), mockMessage);

        vm.expectRevert("FxERC20ChildTunnel: ALREADY_MAPPED");
        vm.prank(address(root.erc20Tunnel));
        fxRoot.sendMessageToChild(address(child.erc20Tunnel), mockMessage);
    }

    function test_FxRootDepositWithMapToken() public {
        FxERC20 childToken = FxERC20(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(root.erc20Token))),
                root.erc20Tunnel.childTokenTemplateCodeHash(),
                address(child.erc20Tunnel)
            )
        );
        uint256 amt = 10 ether;
        vm.startPrank(alice); // depositor
        deal(address(root.erc20Token), alice, amt);
        root.erc20Token.approve(address(root.erc20Tunnel), amt);

        vm.expectEmit(address(child.erc20Tunnel));
        emit TokenMapped(address(root.erc20Token), address(childToken));
        vm.expectEmit(address(root.erc20Tunnel));
        emit TokenMappedERC20(address(root.erc20Token), address(childToken));
        vm.expectEmit(address(childToken));
        emit Transfer(address(0), bob, amt);
        vm.expectEmit(address(root.erc20Tunnel));
        emit FxDepositERC20(address(root.erc20Token), alice, bob, amt);

        root.erc20Tunnel.deposit(address(root.erc20Token), bob /*receiver*/, amt, bytes(""));

        assertEq(childToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(address(child.erc20Tunnel)), 0);

        assertEq(root.erc20Token.balanceOf(alice), 0);
        assertEq(root.erc20Token.balanceOf(address(root.erc20Tunnel)), amt);

        vm.stopPrank();
    }

    function test_FxRootDepositAfterMapToken(uint amt) public {
        root.erc20Tunnel.mapToken(address(root.erc20Token));
        FxERC20 childToken = FxERC20(root.erc20Tunnel.rootToChildTokens(address(root.erc20Token)));

        // uint256 amt = 10 ether;
        vm.startPrank(alice); // depositor
        deal(address(root.erc20Token), alice, amt);
        root.erc20Token.approve(address(root.erc20Tunnel), amt);

        vm.expectEmit(address(childToken));
        emit Transfer(address(0), bob, amt);
        vm.expectEmit(address(root.erc20Tunnel));
        emit FxDepositERC20(address(root.erc20Token), alice, bob, amt);

        root.erc20Tunnel.deposit(address(root.erc20Token), bob /*user*/, amt, bytes(""));

        assertEq(childToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(address(child.erc20Tunnel)), 0);

        assertEq(root.erc20Token.balanceOf(alice), 0);
        assertEq(root.erc20Token.balanceOf(address(root.erc20Tunnel)), amt);

        vm.stopPrank();
    }

    function test_FxChildWithdraw() public {
        uint256 amt = 10 ether;
        uint256 withdrawAmt = 1 ether;

        vm.startPrank(alice); // depositor
        deal(address(root.erc20Token), alice, amt);
        root.erc20Token.approve(address(root.erc20Tunnel), amt);

        root.erc20Tunnel.deposit(address(root.erc20Token), bob /*user*/, amt, bytes(""));
        vm.stopPrank();
        FxERC20 childToken = FxERC20(root.erc20Tunnel.rootToChildTokens(address(root.erc20Token)));

        assertEq(childToken.balanceOf(bob), amt);
        assertEq(childToken.balanceOf(address(child.erc20Tunnel)), 0);

        assertEq(root.erc20Token.balanceOf(alice), 0);
        assertEq(root.erc20Token.balanceOf(address(root.erc20Tunnel)), amt);

        bytes memory burnMessage = abi.encode(address(root.erc20Token), address(childToken), bob, withdrawAmt);

        vm.prank(bob);
        vm.expectEmit(address(childToken));
        emit Transfer(bob, address(0), withdrawAmt);
        vm.expectEmit(address(child.erc20Tunnel));
        emit MessageSent(burnMessage);
        child.erc20Tunnel.withdraw(address(childToken), withdrawAmt);

        assertEq(childToken.balanceOf(bob), amt - withdrawAmt);
        assertEq(childToken.balanceOf(address(child.erc20Tunnel)), 0);
    }

    function test_FxChildWithdrawSyncOnRoot() public {
        uint256 amt = 10 ether;
        uint256 withdrawAmt = 1 ether;

        depositOnRoot(bob, amt);

        FxERC20 childToken = FxERC20(root.erc20Tunnel.rootToChildTokens(address(root.erc20Token)));

        bytes memory burnMessage = abi.encode(address(root.erc20Token), address(childToken), bob, withdrawAmt);

        vm.prank(bob);
        vm.expectEmit(address(childToken));
        emit Transfer(bob, address(0), withdrawAmt);
        vm.expectEmit(address(child.erc20Tunnel));
        emit MessageSent(burnMessage);
        child.erc20Tunnel.withdraw(address(childToken), withdrawAmt);

        assertEq(childToken.balanceOf(bob), amt - withdrawAmt);
        assertEq(childToken.balanceOf(address(child.erc20Tunnel)), 0);

        FxERC20 rootToken = root.erc20Token;
        assertEq(rootToken.balanceOf(bob), 0);
        assertEq(rootToken.balanceOf(address(root.erc20Tunnel)), amt);

        root.erc20Tunnel.receiveMessage(burnMessage); // submit burn proof

        assertEq(rootToken.balanceOf(bob), withdrawAmt);
        assertEq(rootToken.balanceOf(address(root.erc20Tunnel)), amt - withdrawAmt);
    }

    function test_FxChildCannotWithdrawMore() public {
        uint256 amt = 10 ether;

        depositOnRoot(alice, amt); // alice deposits amt for herself
        depositOnRoot(bob, amt); // bob deposits amt for himself
        depositOnRoot(charlie, amt / 2); // charlie deposits amt/2 for himself

        FxERC20 childToken = FxERC20(root.erc20Tunnel.rootToChildTokens(address(root.erc20Token)));
        FxERC20 rootToken = root.erc20Token;

        // charlie cannot withdraw more than amt/2
        vm.expectRevert("ERC20: burn amount exceeds balance");
        vm.prank(charlie);
        child.erc20Tunnel.withdraw(address(childToken), amt);

        vm.prank(charlie);
        child.erc20Tunnel.withdraw(address(childToken), amt / 2);

        assertEq(childToken.balanceOf(charlie), 0);
        assertEq(rootToken.balanceOf(charlie), 0); // yet to exit

        assertEq(rootToken.balanceOf(address(root.erc20Tunnel)), 2 * amt + (amt / 2)); // alice, bob, charlie deposits
        root.erc20Tunnel.receiveMessage(abi.encode(address(root.erc20Token), address(childToken), charlie, amt / 2)); // charlie exits
        assertEq(rootToken.balanceOf(address(root.erc20Tunnel)), 2 * amt); // alice, bob deposits
        assertEq(rootToken.balanceOf(charlie), amt / 2);
    }

    function test_FxChildCannotWithdrawUnmappedToken() public {
        uint256 amt = 10 ether;

        FxERC20 rootToken2 = new FxERC20();
        vm.prank(manager);
        rootToken2.initialize(manager, address(child.erc20Tunnel), "FxERC20", "FE", 18);
        FxERC20 childToken2 = FxERC20(
            computeCreate2Address(
                keccak256(abi.encodePacked(address(rootToken2))),
                root.erc20Tunnel.childTokenTemplateCodeHash(),
                address(child.erc20Tunnel)
            )
        );

        vm.expectRevert();
        vm.startPrank(alice);
        child.erc20Tunnel.withdraw(address(childToken2), amt);

        deal(address(rootToken2), alice, amt);
        rootToken2.approve(address(root.erc20Tunnel), amt);
        root.erc20Tunnel.deposit(address(rootToken2), alice, amt, bytes(""));

        child.erc20Tunnel.withdraw(address(childToken2), amt);
        vm.stopPrank();
    }

    function depositOnRoot(address who, uint256 amt) internal {
        vm.startPrank(who);
        deal(address(root.erc20Token), who, amt);
        root.erc20Token.approve(address(root.erc20Tunnel), amt);
        root.erc20Tunnel.deposit(address(root.erc20Token), who /*receiver*/, amt, bytes(""));
        vm.stopPrank();
    }
}
