// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 💬 ABOUT
// Custom Test.

// 🧩 MODULES
import {console2 as console} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {stdError} from "forge-std/StdError.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

// 📦 BOILERPLATE
import {TestBase} from "forge-std/Base.sol";
import {DSTest} from "ds-test/test.sol";

// ⭐️ TEST
abstract contract Test is DSTest, StdCheats, StdUtils, StdInvariant, TestBase {
    function assertEq(uint256[] calldata a, uint256[] calldata b) internal {
        assertEq(keccak256(abi.encode(a)), keccak256(abi.encode(b)));
    }
}
