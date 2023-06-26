// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2 as console} from "forge-std/console2.sol";
import {AddressSet, LibAddressSet} from "@utils/AddressSet.sol";
import {FxERC721ChildTunnel} from "contracts/examples/erc721-transfer/FxERC721ChildTunnel.sol";
import {FxERC721RootTunnel} from "contracts/examples/erc721-transfer/FxERC721RootTunnel.sol";
import {IFxERC721} from "contracts/tokens/IFxERC721.sol";
import {FxERC721} from "contracts/tokens/FxERC721.sol";

uint256 constant MAX_BALANCE = 1e20;
uint256 constant NUM_TOKENS = 5;
bytes constant NULL_DATA = new bytes(0);
struct Token {
    IFxERC721 root;
    IFxERC721 child;
}

contract ERC721Handler is CommonBase, StdCheats, StdUtils {
    address public immutable manager = makeAddr("manager");
    using LibAddressSet for AddressSet;

    FxERC721ChildTunnel public erc721ChildTunnel;
    FxERC721RootTunnel public erc721RootTunnel;
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

    constructor(FxERC721RootTunnel _erc721RootTunnel, FxERC721ChildTunnel _erc721ChildTunnel) {
        erc721RootTunnel = _erc721RootTunnel;
        erc721ChildTunnel = _erc721ChildTunnel;

        vm.startPrank(manager);
        bytes32 tokenCodeHash = erc721RootTunnel.childTokenTemplateCodeHash();
        for (uint256 i; i < NUM_TOKENS; i++) {
            IFxERC721 root = new FxERC721();
            root.initialize(manager, address(erc721ChildTunnel), "FxERC721", vm.toString(i));
            IFxERC721 child = IFxERC721(
                computeCreate2Address(
                    keccak256(abi.encodePacked(address(root))),
                    tokenCodeHash,
                    address(erc721ChildTunnel)
                )
            );
            tokens.push(Token({root: root, child: child}));
        }
        vm.stopPrank();
    }

    function depositOnRoot(
        uint256 tokenSeed,
        uint256 tokenId
    ) public createActor useToken(tokenSeed) countCall("depositOnRoot") {
        if (!tokenOwned(currentToken.root, currentActor, tokenId)) {
            vm.prank(manager);
            currentToken.root.mint(currentActor, tokenId, NULL_DATA);
        }

        vm.startPrank(currentActor);
        currentToken.root.approve(address(erc721RootTunnel), tokenId);
        erc721RootTunnel.deposit(address(currentToken.root), currentActor, tokenId, NULL_DATA);
        vm.stopPrank();

        ghostRootTotalDeposits++;
        ghostRootTokenDeposits[currentActor][address(currentToken.root)]++;
    }

    function withdrawOnChild(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 tokenId
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("withdrawOnChild") {
        vm.assume(childTokenExists(currentToken.root));
        vm.assume(tokenOwned(currentToken.child, currentActor, tokenId));

        vm.prank(currentActor);
        erc721ChildTunnel.withdraw(address(currentToken.child), tokenId, NULL_DATA);

        pendingWithdrawalProofs.push(
            abi.encode(address(currentToken.root), address(currentToken.root), currentActor, tokenId)
        );

        ghostChildTotalWithdrawals++;
        ghostChildTokenWithdrawals[currentActor][address(currentToken.child)]++;
    }

    function withdrawOnChildAndExit(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 tokenId
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("withdrawOnChildAndExit") {
        vm.assume(childTokenExists(currentToken.root));
        vm.assume(tokenOwned(currentToken.child, currentActor, tokenId));

        vm.startPrank(currentActor);
        erc721ChildTunnel.withdraw(address(currentToken.child), tokenId, NULL_DATA);
        vm.stopPrank();

        assert(currentToken.root.ownerOf(tokenId) == address(erc721RootTunnel));
        erc721RootTunnel.receiveMessage(
            abi.encode(address(currentToken.root), address(currentToken.root), currentActor, tokenId)
        );
        assert(currentToken.root.ownerOf(tokenId) == currentActor);

        ghostChildTotalWithdrawals++;
        ghostChildTokenWithdrawals[currentActor][address(currentToken.child)]++;

        ghostChildTotalExits++;
        ghostChildTokenExits[currentActor][address(currentToken.child)]++;
    }

    function exitAllPendingToRoot() public countCall("exitAllPendingToRoot") {
        uint num = pendingWithdrawalProofs.length;
        vm.assume(num > 0);
        for (uint i; i < num; i++) {
            erc721RootTunnel.receiveMessage(pendingWithdrawalProofs[i]);

            (, address childToken, address who, ) = abi.decode(
                pendingWithdrawalProofs[i],
                (address, address, address, uint256)
            );

            ghostChildTotalExits++;
            ghostChildTokenExits[who][address(childToken)]++;
        }
    }

    function transferRoot(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 toSeed,
        uint256 tokenId
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("transferRoot") {
        vm.assume(tokenOwned(currentToken.root, currentActor, tokenId));
        address to = actors.rand(toSeed);

        vm.prank(currentActor);
        currentToken.root.transferFrom(currentActor, to, tokenId);
    }

    function transferChild(
        uint256 actorSeed,
        uint256 tokenSeed,
        uint256 toSeed,
        uint256 tokenId
    ) public useActor(actorSeed) useToken(tokenSeed) countCall("transferChild") {
        vm.assume(childTokenExists(currentToken.root));
        vm.assume(tokenOwned(currentToken.child, currentActor, tokenId));
        address to = actors.rand(toSeed);

        vm.prank(currentActor);
        currentToken.child.transferFrom(currentActor, to, tokenId);
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

    function childTokenExists(IFxERC721 rootToken) public view returns (bool) {
        return erc721RootTunnel.rootToChildTokens(address(rootToken)) != address(0);
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

    function tokenOwned(IFxERC721 token, address who, uint256 tokenId) internal view returns (bool owned) {
        try token.ownerOf(tokenId) returns (address currentOwner) {
            owned = currentOwner == who;
        } catch {}
    }
}
