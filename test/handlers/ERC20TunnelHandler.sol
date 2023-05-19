// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2 as console} from "forge-std/console2.sol";
import {AddressSet, LibAddressSet} from "@utils/AddressSet.sol";
import {FxERC20ChildTunnel} from "contracts/examples/erc20-transfer/FxERC20ChildTunnel.sol";
import {FxERC20RootTunnel} from "contracts/examples/erc20-transfer/FxERC20RootTunnel.sol";
import {IFxERC20} from "contracts/tokens/IFxERC20.sol";
import {FxERC20} from "contracts/tokens/FxERC20.sol";

uint256 constant MAX_BALANCE = 1e20;
uint256 constant NUM_TOKENS = 5;
bytes constant NULL_DATA = new bytes(0);
struct Token {
    IFxERC20 root;
    IFxERC20 child;
}

contract ERC20Handler is CommonBase, StdCheats, StdUtils {
    address public immutable manager = makeAddr("manager");
    using LibAddressSet for AddressSet;

    FxERC20ChildTunnel public erc20ChildTunnel;
    FxERC20RootTunnel public erc20RootTunnel;
    Token[] public tokens;

    bytes[] public pendingWithdrawalProofs;

    uint256 public ghostRootTotalDeposits;
    mapping(address => mapping(address => uint256)) public ghostRootTokenDeposits;

    uint256 public ghostChildTotalWithdrawals;
    mapping(address => mapping(address => uint256)) public ghostChildTokenWithdrawals;

    uint256 public ghostChildTotalExits;
    mapping(address => mapping(address => uint256)) public ghostChildTokenExits;

    mapping(bytes32 => uint256) public calls;

    AddressSet internal actors;
    address internal currentActor;
    Token internal currentToken;

    modifier createActor() {
        currentActor = msg.sender;
        actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors.rand(actorIndexSeed);
        _;
    }

    modifier useToken(uint256 tokenIndexSeed) {
        currentToken = tokens[bound(tokenIndexSeed, 0, tokens.length)];
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor(FxERC20RootTunnel _erc20RootTunnel, FxERC20ChildTunnel _erc20ChildTunnel) {
        erc20RootTunnel = _erc20RootTunnel;
        erc20ChildTunnel = _erc20ChildTunnel;

        vm.startPrank(manager);
        bytes32 tokenCodeHash = erc20RootTunnel.childTokenTemplateCodeHash();
        for (uint256 i; i < NUM_TOKENS; i++) {
            IFxERC20 root = new FxERC20();
            root.initialize(manager, address(erc20ChildTunnel), "FxERC20", vm.toString(i), 18);
            IFxERC20 child = IFxERC20(
                computeCreate2Address(
                    keccak256(abi.encodePacked(address(root))),
                    tokenCodeHash,
                    address(erc20ChildTunnel)
                )
            );
            tokens.push(Token({root: root, child: child}));
        }
        vm.stopPrank();
    }

    function depositOnRoot(
        uint256 tokenSeed,
        uint256 amount
    ) public createActor useToken(tokenSeed) countCall("depositOnRoot") {
        amount = bound(amount, 0, MAX_BALANCE - currentToken.root.balanceOf(currentActor));
        deal(address(currentToken.root), currentActor, amount, true);

        vm.startPrank(currentActor);
        currentToken.root.approve(address(erc20RootTunnel), amount);
        erc20RootTunnel.deposit(address(currentToken.root), currentActor, amount, NULL_DATA);
        vm.stopPrank();

        ghostRootTotalDeposits += amount;
        ghostRootTokenDeposits[currentActor][address(currentToken.root)] += amount;
    }

    function withdrawOnChild(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 amount
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("withdrawOnChild") {
        vm.assume(childTokenExists(currentToken.root));
        amount = bound(amount, 0, currentToken.child.balanceOf(currentActor));

        vm.prank(currentActor);
        erc20ChildTunnel.withdraw(address(currentToken.child), amount);

        pendingWithdrawalProofs.push(
            abi.encode(address(currentToken.root), address(currentToken.root), currentActor, amount)
        );

        ghostChildTotalWithdrawals += amount;
        ghostChildTokenWithdrawals[currentActor][address(currentToken.child)] += amount;
    }

    function withdrawOnChildAndExit(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 amount
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("withdrawOnChildAndExit") {
        vm.assume(childTokenExists(currentToken.root));
        amount = bound(amount, 0, currentToken.child.balanceOf(currentActor));

        uint256 childTokenBalanceBefore = currentToken.child.balanceOf(currentActor);
        uint256 rootTokenBalanceBefore = currentToken.root.balanceOf(currentActor);

        vm.startPrank(currentActor);
        erc20ChildTunnel.withdraw(address(currentToken.child), amount);
        vm.stopPrank();

        assert(currentToken.child.balanceOf(currentActor) == childTokenBalanceBefore - amount);
        erc20RootTunnel.receiveMessage(
            abi.encode(address(currentToken.root), address(currentToken.root), currentActor, amount)
        );
        assert(currentToken.root.balanceOf(currentActor) == rootTokenBalanceBefore + amount);

        ghostChildTotalWithdrawals += amount;
        ghostChildTokenWithdrawals[currentActor][address(currentToken.child)] += amount;

        ghostChildTotalExits += amount;
        ghostChildTokenExits[currentActor][address(currentToken.child)] += amount;
    }

    function exitAllPendingToRoot() public countCall("exitAllPendingToRoot") {
        uint num = pendingWithdrawalProofs.length;
        vm.assume(num > 0);
        for (uint i; i < num; i++) {
            erc20RootTunnel.receiveMessage(pendingWithdrawalProofs[i]);

            (, address childToken, address who, uint256 amount) = abi.decode(
                pendingWithdrawalProofs[i],
                (address, address, address, uint256)
            );

            ghostChildTotalExits += amount;
            ghostChildTokenExits[who][address(childToken)] += amount;
        }
    }

    function transferRoot(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 toSeed,
        uint256 amount
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("transferRoot") {
        amount = bound(amount, 0, currentToken.root.balanceOf(currentActor));
        address to = actors.rand(toSeed);

        vm.prank(currentActor);
        currentToken.root.transferFrom(currentActor, to, amount);
    }

    function transferChild(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 toSeed,
        uint256 amount
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("transferChild") {
        vm.assume(childTokenExists(currentToken.root));
        amount = bound(amount, 0, currentToken.child.balanceOf(currentActor));
        address to = actors.rand(toSeed);

        vm.prank(currentActor);
        currentToken.child.transferFrom(currentActor, to, amount);
    }

    function getTokens() external view returns (Token[] memory) {
        return tokens;
    }

    function getActors() external view returns (address[] memory) {
        return actors.addrs;
    }

    function forEachActorForAllToken(function(Token memory, address) external func) public {
        for (uint i; i < tokens.length; i++) {
            for (uint j; j < actors.addrs.length; j++) {
                func(tokens[i], actors.addrs[j]);
            }
        }
    }

    function reduceActorForAllToken(
        uint256 acc,
        function(Token memory, address) external returns (uint256) func
    ) public returns (uint256) {
        for (uint i; i < tokens.length; i++) {
            for (uint j; j < actors.addrs.length; j++) {
                acc += func(tokens[i], actors.addrs[j]);
            }
        }
        return acc;
    }

    function reduceToken(uint256 acc, function(Token memory) external returns (uint256) func) public returns (uint256) {
        for (uint i; i < tokens.length; i++) {
            acc += func(tokens[i]);
        }
        return acc;
    }

    function getRootTunnelBalance() public view returns (uint256 ret) {
        for (uint i; i < tokens.length; i++) {
            ret += tokens[i].root.balanceOf(address(erc20RootTunnel));
        }
    }

    function getChildTunnelBalance() public view returns (uint256 ret) {
        for (uint i; i < tokens.length; i++) {
            if (childTokenExists(tokens[i].root)) {
                ret += tokens[i].child.balanceOf(address(erc20ChildTunnel));
            }
        }
    }

    function childTokenExists(IFxERC20 rootToken) public view returns (bool) {
        return erc20RootTunnel.rootToChildTokens(address(rootToken)) != address(0);
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("depositOnRoot", calls["depositOnRoot"]);
        console.log("withdrawOnChild", calls["withdrawOnChild"]);
        console.log("withdrawOnChildAndExit", calls["withdrawOnChildAndExit"]);
        console.log("exitAllPendingToRoot", calls["exitAllPendingToRoot"]);
        console.log("transferRoot", calls["transferRoot"]);
        console.log("transferChild", calls["transferChild"]);
        console.log("Total Deposit Sum:", ghostRootTotalDeposits);
        console.log("Total Withdrawal (incl exit) Sum:", ghostChildTotalWithdrawals);
        console.log("Total Exit Sum:", ghostChildTotalExits);
    }
}
