// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkMock.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

/**
 * creates a subscription id for a given vrf coordinator
 */
contract CreateSubscriptionId is Script {
    function createsubIdHelperConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ,uint256 deployerKey ) = helperConfig
            .actualNetworkConfig();
        return createSubId(vrfCoordinator,deployerKey);
    }

    //creates the subId from the vrf address provided from helperConfig
    function createSubId(address vrfCoordinator,uint256 deployerKey) public returns (uint64) {
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = VRFCoordinatorV2Mock(
            vrfCoordinator
        );
        uint64 subId = vrfCoordinatorV2Mock.createSubscription();
        vm.stopBroadcast();
        return subId;
    }

    function run() external returns (uint64) {
        return createsubIdHelperConfig();
    }
}

/**
 * Funds the above created subscription Id
 * 1. Funds the VRFcontract if provided with subId, VRfcontract address, and link
 * 2. creates a vrf Contract with the help of helperConfig then we fund this Contract with link
 * 3. Deploys a Mock link contract for local chains
 */

contract FundSubscription is Script {
    uint96 FUND_AMOUNT = 5 ether;

    function fundSubscriptionHelperConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            address link,
            uint256 deployerKey

        ) = helperConfig.actualNetworkConfig();

        fundSubscription(subId, vrfCoordinator, link,deployerKey);
    }

    function fundSubscription(
        uint64 subId,
        address vrfCoordinator,
        address link,
        uint256 deployerKey
    ) public {
        console.log("subId is ", subId);
        console.log("vrfCoordinator is ", vrfCoordinator);
        console.log("link address is ", link);
        if (block.chainid == 11155111) {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock vrfCoordinatorV2Mock = VRFCoordinatorV2Mock(
                vrfCoordinator
            );
            vm.stopBroadcast();
            vrfCoordinatorV2Mock.fundSubscription(subId, FUND_AMOUNT);
        }
    }

    function run() external {
        return fundSubscriptionHelperConfig();
    }
}

//to programatically add the consumer to the subscription
contract AddConsumer is Script {
    HelperConfig helperConfig = new HelperConfig();

    function addConsumerHelper(address recentRaffle) internal {
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.actualNetworkConfig();
        addConsumer(subId, vrfCoordinator, recentRaffle, deployerKey);
    }

    function addConsumer(
        uint64 subId,
        address vrfCoordinator,
        address raffle,
        uint256 deployerKey
    ) public {
        console.log("msg.sender is ", msg.sender);
        console.log("vrfCoordinator is ", vrfCoordinator);
        console.log("raffle address is ", raffle);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock vrfCoordinatorMock = VRFCoordinatorV2Mock(
            vrfCoordinator
        );
        vrfCoordinatorMock.addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function run() external {
        address recentRaffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerHelper(recentRaffle);
    }
}
