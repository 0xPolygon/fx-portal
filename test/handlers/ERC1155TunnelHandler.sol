// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2 as console} from "forge-std/console2.sol";
import {AddressSet, LibAddressSet} from "@utils/AddressSet.sol";
import {FxERC1155ChildTunnel} from "contracts/examples/erc1155-transfer/FxERC1155ChildTunnel.sol";
import {FxERC1155RootTunnel} from "contracts/examples/erc1155-transfer/FxERC1155RootTunnel.sol";
import {IFxERC1155} from "contracts/tokens/IFxERC1155.sol";
import {FxERC1155} from "contracts/tokens/FxERC1155.sol";

uint256 constant MAX_BALANCE = 1e20;
uint256 constant NUM_TOKENS = 5;
bytes constant NULL_DATA = new bytes(0);
struct Token {
    IFxERC1155 root;
    IFxERC1155 child;
}

contract ERC1155Handler is CommonBase, StdCheats, StdUtils {
    address public immutable manager = makeAddr("manager");
    using LibAddressSet for AddressSet;

    FxERC1155ChildTunnel public erc1155ChildTunnel;
    FxERC1155RootTunnel public erc1155RootTunnel;
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

    constructor(FxERC1155RootTunnel _erc1155RootTunnel, FxERC1155ChildTunnel _erc1155ChildTunnel) {
        erc1155RootTunnel = _erc1155RootTunnel;
        erc1155ChildTunnel = _erc1155ChildTunnel;

        vm.startPrank(manager);
        bytes32 tokenCodeHash = erc1155RootTunnel.childTokenTemplateCodeHash();
        for (uint256 i; i < NUM_TOKENS; i++) {
            IFxERC1155 root = new FxERC1155();
            root.initialize(manager, address(erc1155ChildTunnel), "ipfs://");
            IFxERC1155 child = IFxERC1155(
                computeCreate2Address(
                    keccak256(abi.encodePacked(address(root))),
                    tokenCodeHash,
                    address(erc1155ChildTunnel)
                )
            );
            tokens.push(Token({root: root, child: child}));
        }
        vm.stopPrank();
    }

    function depositOnRoot(
        uint256 tokenSeed,
        uint256 tokenId,
        uint256 amount
    ) public createActor useToken(tokenSeed) countCall("depositOnRoot") {
        amount = bound(amount, 0, MAX_BALANCE - currentToken.root.balanceOf(currentActor, tokenId));
        vm.prank(manager);
        currentToken.root.mint(currentActor, tokenId, amount, NULL_DATA);

        vm.startPrank(currentActor);
        currentToken.root.setApprovalForAll(address(erc1155RootTunnel), true);
        erc1155RootTunnel.deposit(address(currentToken.root), currentActor, tokenId, amount, NULL_DATA);
        vm.stopPrank();

        ghostRootTotalDeposits += amount;
        ghostRootTokenDeposits[currentActor][address(currentToken.root)] += amount;
    }

    function withdrawOnChild(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 tokenId,
        uint256 amount
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("withdrawOnChild") {
        vm.assume(childTokenExists(currentToken.root));
        vm.assume((amount = bound(amount, 0, currentToken.child.balanceOf(currentActor, tokenId))) > 0);

        vm.prank(currentActor);
        erc1155ChildTunnel.withdraw(address(currentToken.child), tokenId, amount, NULL_DATA);

        pendingWithdrawalProofs.push(
            abi.encode(address(currentToken.root), address(currentToken.root), currentActor, tokenId, amount, NULL_DATA)
        );

        ghostChildTotalWithdrawals += amount;
        ghostChildTokenWithdrawals[currentActor][address(currentToken.child)] += amount;
    }

    function withdrawOnChildAndExit(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 tokenId,
        uint256 amount
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("withdrawOnChild") {
        vm.assume(childTokenExists(currentToken.root));
        vm.assume((amount = bound(amount, 0, currentToken.child.balanceOf(currentActor, tokenId))) > 0);

        vm.prank(currentActor);
        erc1155ChildTunnel.withdraw(address(currentToken.child), tokenId, amount, NULL_DATA);

        erc1155RootTunnel.receiveMessage(
            abi.encode(address(currentToken.root), address(currentToken.root), currentActor, tokenId, amount, NULL_DATA)
        );

        ghostChildTotalWithdrawals += amount;
        ghostChildTokenWithdrawals[currentActor][address(currentToken.child)] += amount;

        ghostChildTotalExits += amount;
        ghostChildTokenExits[currentActor][address(currentToken.child)] += amount;
    }

    function exitAllPendingToRoot() public countCall("exitAllPendingToRoot") {
        uint num = pendingWithdrawalProofs.length;
        vm.assume(num > 0);
        for (uint i; i < num; i++) {
            erc1155RootTunnel.receiveMessage(pendingWithdrawalProofs[i]);

            (, address childToken, address who, , uint256 amount, ) = abi.decode(
                pendingWithdrawalProofs[i],
                (address, address, address, uint256, uint256, bytes)
            );

            ghostChildTotalExits += amount;
            ghostChildTokenExits[who][address(childToken)] += amount;
        }
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

    function childTokenExists(IFxERC1155 rootToken) public view returns (bool) {
        return erc1155RootTunnel.rootToChildTokens(address(rootToken)) != address(0);
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
