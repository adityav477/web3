// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
  function run() external returns (FundMe) {
    //to get the priceFeed address for the given Chain
    HelperConfig helperConfig = new HelperConfig();
    address actualAddress = helperConfig.actualNetworkAddress();

    vm.startBroadcast();
    FundMe fundMe = new FundMe(actualAddress);
    vm.stopBroadcast();
    return fundMe;
  }
}
