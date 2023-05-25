// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBase} from "@utils/FxBase.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {FxERC1155} from "contracts/tokens/FxERC1155.sol";
import {IFxERC1155} from "contracts/tokens/IFxERC1155.sol";
import {Token, ERC1155Handler} from "@handlers/ERC1155TunnelHandler.sol";

contract FxERC1155TunnelTest is FxBase {
    ERC1155Handler public handler;

    function setUp() public override {
        super.setUp();

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = ERC1155Handler.depositOnRoot.selector;
        selectors[1] = ERC1155Handler.withdrawOnChild.selector;
        selectors[2] = ERC1155Handler.withdrawOnChildAndExit.selector;
        selectors[3] = ERC1155Handler.exitAllPendingToRoot.selector;

        handler = new ERC1155Handler(root.erc1155Tunnel, child.erc1155Tunnel);

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
}
