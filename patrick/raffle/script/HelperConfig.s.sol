//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 timeInterval;
        uint256 raffleEntranceFees;
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    /* State Variables */
    NetworkConfig public actualNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            actualNetworkConfig = getSepoliaConfig();
        } else {
            actualNetworkConfig = getGanacheConfig();
        }
    }

    /* Functions */
    function getSepoliaConfig() internal view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                timeInterval: 30,
                raffleEntranceFees: 0.01 ether,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 10993,
                callbackGasLimit: 50000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("PRIVATE_KEY_SEPOLIA")
            });
    }

    function getGanacheConfig() internal returns (NetworkConfig memory) {
        if (actualNetworkConfig.vrfCoordinator != address(0)) {
            return actualNetworkConfig;
        }

        uint64 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        return
            NetworkConfig({
                timeInterval: 30,
                raffleEntranceFees: 0.01 ether,
                vrfCoordinator: address(vrfCoordinatorV2Mock),
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 50000,
                link: address(linkToken),
                deployerKey: vm.envUint("PRIVATE_KEY_ANVIL")
            });
    }
}
