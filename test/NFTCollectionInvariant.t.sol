// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {NFTCollection} from "../src/NFTCollection.sol";

contract NFTCollectionHandler is Test {
    NFTCollection internal nft;

    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    constructor(NFTCollection _nft) {
        nft = _nft;
    }

    function mintToAlice() external {
        if (nft.nextTokenId() >= nft.MAX_SUPPLY()) {
            return;
        }

        nft.mint(ALICE);
    }

    function mintToBob() external {
        if (nft.nextTokenId() >= nft.MAX_SUPPLY()) {
            return;
        }

        nft.mint(BOB);
    }

    function transferAliceToBob(uint256 tokenId) external {
        uint256 minted = nft.nextTokenId();

        if (minted == 0) {
            return;
        }

        tokenId = bound(tokenId, 0, minted - 1);

        if (nft.ownerOf(tokenId) != ALICE) {
            return;
        }

        vm.prank(ALICE);

        nft.safeTransferFrom(ALICE, BOB, tokenId);
    }

    function transferBobToAlice(uint256 tokenId) external {
        uint256 minted = nft.nextTokenId();

        if (minted == 0) {
            return;
        }

        tokenId = bound(tokenId, 0, minted - 1);

        if (nft.ownerOf(tokenId) != BOB) {
            return;
        }

        vm.prank(BOB);

        nft.safeTransferFrom(BOB, ALICE, tokenId);
    }

    function alice() external pure returns (address) {
        return ALICE;
    }

    function bob() external pure returns (address) {
        return BOB;
    }
}

contract NFTCollectionInvariantTest is StdInvariant, Test {
    NFTCollection internal nft;
    NFTCollectionHandler internal handler;

    function setUp() public {
        nft = new NFTCollection();

        handler = new NFTCollectionHandler(nft);

        nft.transferOwnership(address(handler));

        targetContract(address(handler));
    }

    function invariant_NextTokenIdNeverExceedsMaxSupply() public view {
        assertLe(nft.nextTokenId(), nft.MAX_SUPPLY());
    }

    function invariant_AllMintedTokensHaveOwner() public view {
        uint256 minted = nft.nextTokenId();

        for (uint256 i = 0; i < minted; i++) {
            assertTrue(nft.ownerOf(i) != address(0));
        }
    }

    function invariant_BalancesMatchMintedSupply() public view {
        uint256 totalBalances = nft.balanceOf(handler.alice()) + nft.balanceOf(handler.bob());

        assertEq(totalBalances, nft.nextTokenId());
    }
}
