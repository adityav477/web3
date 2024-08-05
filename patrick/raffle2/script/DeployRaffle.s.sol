// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 timeInterval,
            address vrfCoordinatorAddress,
            uint64 subscriptionId,
            bytes32 keyHash,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.realNetworkConfig();

        if (subscriptionId == 0) {
            //creating subscription  to get subId
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription
                .createSubscriptionBasedOnAddress(vrfCoordinatorAddress);

            //funding subscription with Linktokens
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorAddress,
                subscriptionId,
                link
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            timeInterval,
            vrfCoordinatorAddress,
            subscriptionId,
            keyHash,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            subscriptionId,
            address(raffle),
            vrfCoordinatorAddress
        );

        return (raffle, helperConfig);
    }
}
