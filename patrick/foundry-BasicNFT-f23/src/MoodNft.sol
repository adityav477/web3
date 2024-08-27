// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {console} from "forge-std/Test.sol";

contract MoodNft is ERC721 {
    /* Errors */
    error MoodNft_FlipFailedSenderIsNotOwner();

    /* Storage */
    uint256 private s_tokenCounter;
    string private s_happySvgUri;
    string private s_sadSvgUri;

    /* Mappings */
    mapping(uint256 tokenId => Mood) private s_tokenIdToMood;

    /* enum */
    enum Mood {
        HAPPY,
        SAD
    }

    constructor(
        string memory happySVgUri,
        string memory sadSvgUri
    ) ERC721("MoodNft", "MNFT") {
        s_tokenCounter = 0;
        s_happySvgUri = happySVgUri;
        s_sadSvgUri = sadSvgUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    //to change the mood of the owner nft bu the owner pr operator
    function flipMood(uint256 tokenId) public {
        //isApprovedOrOwner doesnt exists in the ERc721 which we have used from openzeppelin
        if (
            ownerOf(tokenId) != msg.sender &&
            getApproved(tokenId) != msg.sender &&
            !isApprovedForAll(ownerOf(tokenId), msg.sender)
        ) {
            // console.log("msg.sender", msg.sender);
            // console.log("ownerOf is ", ownerOf(tokenId));
            // console.log(
            //     "isApprovedForAll ",
            //     isApprovedForAll(ownerOf(tokenId), msg.sender)
            // );
            revert MoodNft_FlipFailedSenderIsNotOwner();
        }

        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    //we need to convert the imageUri to a json which with the image uri in it and assign it to a token id
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory tokenUri) {
        string memory image;
        string memory name;
        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            image = s_happySvgUri;
            name = "Happy";
        } else {
            image = s_sadSvgUri;
            name = "Sad";
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '","description": "Sends emoji based on the Mood","attributes": [{ "trait": "mood","value": "100" }],"image":"',
                            image,
                            '"}'
                        )
                    )
                )
            );
    }
}
