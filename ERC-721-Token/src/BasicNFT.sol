// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNFT is ERC721 {
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_TokenIdToUri;

    constructor() ERC721("Snowy", "SNY") {
        s_tokenCounter = 0;
    }

    function mintNft(address to, string memory tokenUri) public {
        s_TokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(to, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return s_TokenIdToUri[tokenId];
    }
}
