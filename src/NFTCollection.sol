// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract NFTCollection is ERC721, Ownable {
    uint256 public nextTokenId;
    uint256 public constant MAX_SUPPLY = 100;
    string private baseTokenURI;
    using Strings for uint256;
    bool public metadataFrozen;
    bool public revealed;

    constructor() ERC721("Iker Collection", "IKER") Ownable(msg.sender) {}

    function mint(address to) external onlyOwner {
        require(nextTokenId < MAX_SUPPLY, "Max supply reached");

        uint256 tokenId = nextTokenId;

        nextTokenId++;

        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        require(!metadataFrozen, "Metadata is frozen");

        baseTokenURI = newBaseURI;
    }

    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        return string.concat(_baseURI(), tokenId.toString(), ".json");
    }

    function reveal(string calldata finalBaseURI) external onlyOwner {
        require(!revealed, "Already revealed");
        require(!metadataFrozen, "Metadata is frozen");

        baseTokenURI = finalBaseURI;
        revealed = true;
    }
}
