// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollection is ERC721, Ownable {
    uint256 public nextTokenId;
    uint256 public constant MAX_SUPPLY = 100;
    string private baseTokenURI;

    constructor() ERC721("Iker Collection", "IKER") Ownable(msg.sender) {}

    function mint(address to) external onlyOwner {
        require(nextTokenId < MAX_SUPPLY, "Max supply reached");

        uint256 tokenId = nextTokenId;

        nextTokenId++;

        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
