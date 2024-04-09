//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant CHANDA = 1 ether;

    //fundFundMe
    function fundFundMe(address sentAddress) public {
        vm.startBroadcast();
        FundMe(payable(sentAddress)).fund{value: CHANDA}();
        vm.stopBroadcast();
        console.log("Funded FundMe");
    }

    //get the address of latest deployed fundMe contract
    function run() external {
        address mostRecentDeployyedFundMe = DevOpsTools
            .get_most_recent_deployment("FundMe", block.chainid);

        fundFundMe(mostRecentDeployyedFundMe);
    }
}

contract WithdrawFundMe is Script {
    uint256 constant CHANDA = 1 ether;

    //withdrawFundMe
    function withdrawFundMe(address sentAddress) public {
        vm.startBroadcast();
        FundMe(payable(sentAddress)).withdraw();
        vm.stopBroadcast();
        console.log("Withdrawn FundMe");
    }

    function run() external {
        address mostRecentDeployyedFundMe = DevOpsTools
            .get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentDeployyedFundMe);
    }
}
