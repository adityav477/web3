// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 timeInterval;
        address vrfCoordinatorAddress;
        uint64 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public realNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            realNetworkConfig = getSepoliaDetails();
        } else {
            realNetworkConfig = getLocalChainDetails();
        }
    }

    function getSepoliaDetails() internal pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                timeInterval: 30,
                vrfCoordinatorAddress: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                subscriptionId: 10993,
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                callbackGasLimit: 30000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getLocalChainDetails() internal returns (NetworkConfig memory) {
        if (realNetworkConfig.vrfCoordinatorAddress != address(0)) {
            return realNetworkConfig;
        }

        uint96 BASE_FEE = 0.25 ether;
        uint96 GAS_PRICE_LINK = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            BASE_FEE,
            GAS_PRICE_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                timeInterval: 30,
                vrfCoordinatorAddress: address(vrfCoordinator),
                subscriptionId: 0,
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                callbackGasLimit: 30000,
                link: address(linkToken)
            });
    }
}
