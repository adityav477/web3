// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkMock.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function createSubscription() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinatorAddress, , , , ) = helperConfig
            .realNetworkConfig();

        return createSubscriptionBasedOnAddress(vrfCoordinatorAddress);
    }

    function createSubscriptionBasedOnAddress(
        address vrfCoordinatorAddress
    ) public returns (uint64) {
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(
            vrfCoordinatorAddress
        );

        uint64 subId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function run() external returns (uint64) {
        return createSubscription();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // to fund the vrf from the link token

    function fundSubscriptionHelperConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinatorAddress,
            uint64 subId,
            ,
            ,
            address linkToken
        ) = helperConfig.realNetworkConfig();

        fundSubscription(vrfCoordinatorAddress, subId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinatorAddress,
        uint64 subId,
        address linkToken
    ) public {
        if (block.chainid == 11155111) {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinatorAddress,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinatorAddress).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        return fundSubscriptionHelperConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerHelperConfig(address recentRaffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinatorAddress, uint64 subId, , , ) = helperConfig
            .realNetworkConfig();

        addConsumer(subId, recentRaffle, vrfCoordinatorAddress);
    }

    function addConsumer(
        uint64 subId,
        address recentRaffle,
        address vrfCoordinatorAddress
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(
            vrfCoordinatorAddress
        );
        vrfCoordinator.addConsumer(subId, recentRaffle);
        vm.stopBroadcast();
    }

    function run() external {
        address recentRaffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );

        addConsumerHelperConfig(recentRaffle);
    }
}
