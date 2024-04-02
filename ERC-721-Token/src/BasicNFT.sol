// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BasicNFT is ERC721, Ownable {
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_TokenIdToUri;

    constructor(
        address initialOwner
    ) ERC721("Snowy", "SNY") Ownable(initialOwner) {
        s_tokenCounter = 0;
    }

    function mintNft(string memory tokenUri) public onlyOwner {
        s_TokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return s_TokenIdToUri[tokenId];
    }
}
