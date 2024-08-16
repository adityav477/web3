// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployMoodNft is Script {
    MoodNft moodNft;

    function run() external returns (MoodNft) {
        string memory sadSvg = vm.readFile("img/sad.svg");
        string memory happySvg = vm.readFile("img/happy.svg");

        console.log("Sad svg ", sadSvg);
        console.log("Happ svg", happySvg);
        //
        vm.startBroadcast();
        moodNft = new MoodNft(svgToImageUri(happySvg), svgToImageUri(sadSvg));
        vm.stopBroadcast();
        return moodNft;
    }

    //we need to convert the svg to svgimageuri instead of hard coding the imageuri
    function svgToImageUri(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseSvg = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        string memory baseUrl = "data:image/svg+xml;base64,";
        string memory imageUri = string(abi.encodePacked(baseUrl, baseSvg));

        return imageUri;
    }
}
