// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNFT is ERC721, Ownable {
    error Flip__CannotFlipMoodIfNotOwner();

    uint256 private s_tokenCounter;
    string private s_happySvgImageURI;
    string private s_sadSvgImageURI;

    enum Mood {
        HAPPY,
        SAD
    }

    mapping(uint256 => Mood) private s_TokenIdToMood;

    constructor(
        address _initialOwner,
        string memory _happySvgImageURI,
        string memory _sadSvgImageURI
    ) ERC721("Moody NFT", "MOOD") Ownable(_initialOwner) {
        s_tokenCounter = 0;
        s_happySvgImageURI = _happySvgImageURI;
        s_sadSvgImageURI = _sadSvgImageURI;
    }

    function mintNFT() public {
        // Initialize all NFT mood to be happy
        s_TokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function flipMood(uint256 tokenId) public {
        if (_ownerOf(tokenId) != msg.sender) {
            revert Flip__CannotFlipMoodIfNotOwner();
        }

        if (s_TokenIdToMood[tokenId] == Mood.HAPPY) {
            s_TokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_TokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory imageURI;
        if (s_TokenIdToMood[tokenId] == Mood.HAPPY) {
            imageURI = s_happySvgImageURI;
        } else {
            imageURI = s_sadSvgImageURI;
        }

        bytes memory dataURI = abi.encodePacked(
            '{ "name": "',
            name(),
            '","description": "A Moody NFT which defines the holder\'s current Mood", "image": "',
            imageURI,
            '", "attributes":[ { "trait_type": "modiness", "value": 100 } ] }'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}
