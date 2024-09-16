// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {CharityDonation} from "../src/Charity.sol";

contract DeployCharity is Script {
    function run() external returns (CharityDonation charityDonation) {
        vm.startBroadcast();
        charityDonation = new CharityDonation();
        vm.stopBroadcast();
    }
}
