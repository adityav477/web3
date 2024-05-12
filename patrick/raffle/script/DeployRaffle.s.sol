//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscriptionId, FundSubscription, AddConsumer} from "./ForVRF.s.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 timeInterval,
            uint256 raffleEntranceFees,
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.actualNetworkConfig();

        if (subscriptionId == 0) {
            //got a subscriptionId
            CreateSubscriptionId createSubscriptionId = new CreateSubscriptionId();
            subscriptionId = createSubscriptionId.createSubId(vrfCoordinator,deployerKey);
            // console.log(
            //     "createSubscriptionId address is ",
            //     address(createSubscriptionId)
            // );

            //fund the vrfContract
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                subscriptionId,
                vrfCoordinator,
                link,
                deployerKey
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            timeInterval,
            raffleEntranceFees,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        //add the raffle to the subscritpion created
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            subscriptionId,
            vrfCoordinator,
            address(raffle),
            deployerKey
        );

        return (raffle, helperConfig);
    }
}
