// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {FxERC721} from "contracts/tokens/FxERC721.sol";
import {IFxERC721} from "contracts/tokens/IFxERC721.sol";
import {Token, ERC721Handler} from "@handlers/ERC721TunnelHandler.sol";

contract FxERC721TunnelTest is FxBase {
    ERC721Handler public handler;

    function setUp() public override {
        super.setUp();

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = ERC721Handler.depositOnRoot.selector;
        selectors[1] = ERC721Handler.withdrawOnChild.selector;
        selectors[2] = ERC721Handler.withdrawOnChildAndExit.selector;
        selectors[3] = ERC721Handler.exitAllPendingToRoot.selector;
        selectors[4] = ERC721Handler.transferRoot.selector;
        selectors[5] = ERC721Handler.transferChild.selector;

        handler = new ERC721Handler(root.erc721Tunnel, child.erc721Tunnel);

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

    function invariant_CallSummary() public view {
        handler.callSummary();
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
}
