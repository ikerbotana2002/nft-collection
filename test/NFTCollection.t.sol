// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NFTCollection} from "../src/NFTCollection.sol";
import {ERC721ReceiverMock} from "./ERC721ReceiverMock.sol";
import {NonERC721Receiver} from "./NonERC721Receiver.sol";

contract NFTCollectionTest is Test {
    NFTCollection internal nft;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        nft = new NFTCollection();
    }

    function testNameAndSymbol() public view {
        assertEq(nft.name(), "Iker Collection");
        assertEq(nft.symbol(), "IKER");
    }

    function testOwnerCanMint() public {
        nft.mint(alice);

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.nextTokenId(), 1);
    }

    function testMultipleMintsUseDifferentTokenIds() public {
        nft.mint(alice);
        nft.mint(alice);

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.nextTokenId(), 2);
    }

    function testNonOwnerCannotMint() public {
        vm.prank(alice);

        vm.expectRevert();

        nft.mint(alice);
    }

    function testSafeMintToCompatibleContract() public {
        ERC721ReceiverMock receiver = new ERC721ReceiverMock();

        nft.mint(address(receiver));

        assertEq(nft.ownerOf(0), address(receiver));
    }

    function testSafeMintRevertsForIncompatibleContract() public {
        NonERC721Receiver receiver = new NonERC721Receiver();

        vm.expectRevert();

        nft.mint(address(receiver));
    }

    function testOwnerCanTransferNFT() public {
        nft.mint(alice);

        vm.prank(alice);

        nft.safeTransferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);

        assertEq(nft.balanceOf(alice), 0);

        assertEq(nft.balanceOf(bob), 1);
    }

    function testApprovedAddressCanTransferNFT() public {
        nft.mint(alice);

        vm.prank(alice);
        nft.approve(bob, 0);

        vm.prank(bob);
        nft.safeTransferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
    }

    function testOperatorCanTransferAllOwnerNFTs() public {
        nft.mint(alice);
        nft.mint(alice);

        vm.prank(alice);
        nft.setApprovalForAll(bob, true);

        vm.startPrank(bob);

        nft.safeTransferFrom(alice, bob, 0);
        nft.safeTransferFrom(alice, bob, 1);

        vm.stopPrank();

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.ownerOf(1), bob);
    }

    function testCannotMintBeyondMaxSupply() public {
        for (uint256 i = 0; i < nft.MAX_SUPPLY(); i++) {
            nft.mint(alice);
        }

        assertEq(nft.balanceOf(alice), nft.MAX_SUPPLY());

        vm.expectRevert("Max supply reached");

        nft.mint(alice);
    }

    function testCannotMintToZeroAddress() public {
        vm.expectRevert();

        nft.mint(address(0));
    }

    function testTokenURIUsesBaseURI() public {
        nft.setBaseURI("ipfs://collection/");

        nft.mint(alice);

        assertEq(nft.tokenURI(0), "ipfs://collection/0.json");
    }

    function testNonOwnerCannotSetBaseURI() public {
        vm.prank(alice);

        vm.expectRevert();

        nft.setBaseURI("ipfs://fake/");
    }

    function testTokenURIWithRealMetadataCID() public {
        nft.setBaseURI("ipfs://bafybeibt6phl3sh4sqmkg76qqn7xqbvfq2laafbqdy33klqxqtmrvueexu/");

        nft.mint(alice);

        assertEq(nft.tokenURI(0), "ipfs://bafybeibt6phl3sh4sqmkg76qqn7xqbvfq2laafbqdy33klqxqtmrvueexu/0.json");
    }

    function testChangingBaseURIChangesExistingTokenURI() public {
        nft.setBaseURI("ipfs://first/");

        nft.mint(alice);

        assertEq(nft.tokenURI(0), "ipfs://first/0.json");

        nft.setBaseURI("ipfs://second/");

        assertEq(nft.tokenURI(0), "ipfs://second/0.json");
    }

    function testOwnerCanFreezeMetadata() public {
        nft.freezeMetadata();

        assertTrue(nft.metadataFrozen());
    }

    function testCannotChangeBaseURIAfterFreeze() public {
        nft.setBaseURI("ipfs://first/");

        nft.freezeMetadata();

        vm.expectRevert("Metadata is frozen");

        nft.setBaseURI("ipfs://second/");
    }

    function testNonOwnerCannotFreezeMetadata() public {
        vm.prank(alice);

        vm.expectRevert();

        nft.freezeMetadata();
    }

    function testOwnerCanRevealCollection() public {
        nft.setBaseURI("ipfs://placeholder/");

        nft.mint(alice);

        nft.reveal("ipfs://final/");

        assertTrue(nft.revealed());

        assertEq(nft.tokenURI(0), "ipfs://final/0.json");
    }

    function testCannotRevealTwice() public {
        nft.reveal("ipfs://first/");

        vm.expectRevert("Already revealed");

        nft.reveal("ipfs://second/");
    }

    function testNonOwnerCannotReveal() public {
        vm.prank(alice);

        vm.expectRevert();

        nft.reveal("ipfs://fake/");
    }

    function testRevealThenFreezeMetadata() public {
        nft.setBaseURI("ipfs://placeholder/");

        nft.mint(alice);

        nft.reveal("ipfs://final/");

        assertEq(nft.tokenURI(0), "ipfs://final/0.json");

        nft.freezeMetadata();

        vm.expectRevert("Metadata is frozen");

        nft.setBaseURI("ipfs://changed/");
    }

    function testCannotSetBaseURIAfterMetadataFreeze() public {
        nft.freezeMetadata();

        vm.expectRevert("Metadata is frozen");

        nft.setBaseURI("ipfs://new/");
    }

    function testCannotRevealAfterMetadataFreeze() public {
        nft.freezeMetadata();

        vm.expectRevert("Metadata is frozen");

        nft.reveal("ipfs://final/");
    }
}
