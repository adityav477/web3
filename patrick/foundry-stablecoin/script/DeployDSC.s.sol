// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script,console} from "forge-std/Script.sol";
import {DSC} from "../src/DecentralizedStableCoin.sol";
import {DSCE} from "../src/DSCEngine.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] tokenPriceFeedAddresses;
    address[] tokenAddresses;

    function run() external returns ( DSC dsc, DSCE engine, HelperConfig helper) {
        helper = new HelperConfig();
        (
            address wEthPriceFeedAddress,
            address wBtcPriceFeedAddress,
            address wEthAddress,
            address wBtcAddress,
            uint256 deployerKey
        ) = helper.actualNetworkConfig();

        tokenPriceFeedAddresses = [wEthPriceFeedAddress, wBtcPriceFeedAddress];
        tokenAddresses = [wEthAddress, wBtcAddress];

        vm.startBroadcast(deployerKey);
        dsc = new DSC();
        console.log("dsc owner is ",dsc.getOwner());

        engine = new DSCE(
            tokenAddresses,
            tokenPriceFeedAddresses,
            address(dsc)
        );

        //to transfer the ownership of the dsc to the dscEngin
        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();
    }
}
