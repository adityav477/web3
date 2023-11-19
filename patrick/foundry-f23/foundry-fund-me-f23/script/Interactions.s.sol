// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 SEND_VALUE = 0.1 ether;
    address USER = makeAddr("user");
    // uint256 SEND_VALUE = 0.1 ether; //10000000000000000
    uint256 STARTING_BALANCE = 10 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.deal(USER, STARTING_BALANCE);
        // vm.startBroadcast();
        vm.prank(0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D);
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        // vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();

        console.log("the interaction withdraw works");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}

//i have used vm.prank instead vm.broadcast cause i wanted my sender to be USER and if i have used vm.braodcast() then i didn't know the owner
//and the sender who sends the money to the contract
