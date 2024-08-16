// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {DeployBasicNft} from "./DeployBasicNft.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MoodNft} from "../src/MoodNft.sol";

contract MintNftInteractions is Script {
    string public PUG =
        "https://ipfs.io/ipfs/bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function mintNftConfig(address mostRecentDeployed) public {
        vm.startBroadcast();
        BasicNft(mostRecentDeployed).mintNft(PUG);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment(
            "BasicNft",
            block.chainid
        );

        mintNftConfig(mostRecentDeployed);
    }
}

contract MintMoodNftInteractions is Script {
    function mintMoodNft(address mostRecentDeployment) public {
        vm.startBroadcast();
        MoodNft(mostRecentDeployment).mintNft();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "MoodNft",
            block.chainid
        );

        mintMoodNft(mostRecentDeployment);
    }
}

contract MintNftFlipMood is Script {
    function moodNftFlipMood(address mostRecentDeployment) public {
        vm.startBroadcast();
        MoodNft(mostRecentDeployment).flipMood(0);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "MoodNft",
            block.chainid
        );

        moodNftFlipMood(mostRecentDeployment);
    }
}

/*
 * @dev programatically to mint the basicnft
 */
