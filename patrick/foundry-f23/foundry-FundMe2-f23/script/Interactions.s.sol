// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    function fundFundMe(address recentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable((recentlyDeployed))).fund{value: 1 ether}();
        vm.stopBroadcast();
        console.log("Ran fundFundMe in Interactions");
    }

    function run() external {
        address recentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(recentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address recentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(recentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Ran WithdrawFundMe in Interactions Script");
    }

    function run() external {
        address recentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(recentlyDeployed);
    }
}
