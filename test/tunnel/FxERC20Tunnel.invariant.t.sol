// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {FxERC20} from "contracts/tokens/FxERC20.sol";
import {IFxERC20} from "contracts/tokens/IFxERC20.sol";
import {Token, ERC20Handler} from "@handlers/ERC20TunnelHandler.sol";

contract FxERC20TunnelTest is FxBase {
    ERC20Handler public handler;

    function setUp() public override {
        super.setUp();

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = ERC20Handler.depositOnRoot.selector;
        selectors[1] = ERC20Handler.withdrawOnChild.selector;
        selectors[2] = ERC20Handler.withdrawOnChildAndExit.selector;
        selectors[3] = ERC20Handler.exitAllPendingToRoot.selector;
        selectors[4] = ERC20Handler.transferRoot.selector;
        selectors[5] = ERC20Handler.transferChild.selector;

        handler = new ERC20Handler(root.erc20Tunnel, child.erc20Tunnel);

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        targetContract(address(handler));
    }

    function invariant_LockedOnRootLtChild() public {
        assertLe(handler.ghostChildTotalWithdrawals(), handler.ghostRootTotalDeposits());
    }

    function invariant_ExitedLtLocked() public {
        assertLe(handler.ghostChildTotalExits(), handler.ghostRootTotalDeposits());
    }

    function invariant_ExitedLtWithdrawn() public {
        assertLe(handler.ghostChildTotalExits(), handler.ghostChildTotalWithdrawals());
    }

    function invariant_AmountOnChildEqLockedOnRoot() public {
        assertEq(
            handler.reduceActorForAllToken(0, this.accumulateChildTokenBalances) + handler.ghostChildTotalWithdrawals(),
            handler.ghostRootTotalDeposits()
        );
    }

    function invariant_ConservationOfDeposits() public {
        assertLe(handler.ghostRootTotalDeposits(), handler.reduceActorForAllToken(0, this.accumulateRootTokenDeposits));
    }

    function invariant_ConservationOfWithdrawals() public {
        assertLe(
            handler.ghostChildTotalWithdrawals(),
            handler.reduceActorForAllToken(0, this.accumulateChildTokenWithdrawals)
        );
    }

    function invariant_ConservationOfExits() public {
        assertLe(handler.ghostChildTotalExits(), handler.reduceActorForAllToken(0, this.accumulateChildTokenExits));
    }

    function invariant_AccountBalances() public {
        handler.forEachActorForAllToken(this.assertAccountBalanceLteTotalSupply);
    }

    function invariant_ConservationOfRootToken() public {
        assertEq(
            handler.reduceToken(0, this.accumulateRootTokenTotalSupply),
            handler.reduceActorForAllToken(0, this.accumulateRootTokenBalances) + handler.getRootTunnelBalance()
        );
    }

    function invariant_ConservationOfChildToken() public {
        assertEq(
            handler.reduceToken(0, this.accumulateChildTokenTotalSupply),
            handler.reduceActorForAllToken(0, this.accumulateChildTokenBalances) + handler.getChildTunnelBalance()
        );
    }

    function invariant_CallSummary() public view {
        handler.callSummary();
    }

    function assertAccountBalanceLteTotalSupply(Token memory token, address who) external {
        assertLe(token.root.balanceOf(who), token.root.totalSupply());
        // if child token exists & is mapped
        if (handler.childTokenExists(token.root)) {
            assertLe(token.child.balanceOf(who), token.child.totalSupply());
        }
    }

    function accumulateRootTokenDeposits(Token memory token, address who) external view returns (uint256) {
        return handler.ghostRootTokenDeposits(who, address(token.root));
    }

    function accumulateChildTokenWithdrawals(Token memory token, address who) external view returns (uint256) {
        return handler.ghostChildTokenWithdrawals(who, address(token.child));
    }

    function accumulateChildTokenExits(Token memory token, address who) external view returns (uint256) {
        return handler.ghostChildTokenExits(who, address(token.root));
    }

    function accumulateRootTokenBalances(Token memory token, address who) external view returns (uint256) {
        return token.root.balanceOf(who);
    }

    function accumulateChildTokenBalances(Token memory token, address who) external view returns (uint256) {
        return handler.childTokenExists(token.root) ? token.child.balanceOf(who) : 0;
    }

    function accumulateChildTokenTotalSupply(Token memory token) external view returns (uint256) {
        return handler.childTokenExists(token.root) ? token.child.totalSupply() : 0;
    }

    function accumulateRootTokenTotalSupply(Token memory token) external view returns (uint256) {
        return token.root.totalSupply();
    }
}
