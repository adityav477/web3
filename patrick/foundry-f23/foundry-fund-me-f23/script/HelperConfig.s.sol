//we need to
//1. Deploy the mock of the Aggregatorv3.. on any local blockchain to save the testing
//2. To keep the track of address of AggregatorV3.. to use the contract for any chain be it sepolia or eth mainnet

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";

//to import mocked aggregator
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

//magic numbers
uint8 constant DECIMAL = 8;
int256 constant INITIAL_PRICE = 2000e8;

contract HelperConfig is Script {
    //to save the address which will be passed to the DeployFundMe
    NetworkConfig public activeNetworkConfig;

    //to decide as soon the script is run what is the address of the AggregatorV3..
    constructor() {
        if (block.chainid == 11155111) {
            //patricks
            activeNetworkConfig = getSepoliaConfig();

            //this works too
            // activeNetworkConfig = NetworkConfig({
            //     priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            // });
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    //we make this of struct type becasue in future we may need to pass gas price along with the address
    struct NetworkConfig {
        address priceFeed;
    }

    //to retrieve and send the address where the Aggregator is saved on sepolia network
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        return
            NetworkConfig({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
        // return sepoliaconfig;
    }

    //to get the address of the aggregator saved on the eth chain
    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        //returns the address on the eth mainnet
        return
            NetworkConfig({
                priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
    }

    //to send the address where the aggregator mock is saved in the local anvil or the ganache chain.
    //in this we didn't use pure because we will be deploying mock address on the local chain
    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        //if we have already deployed a mock V3 then no need to deploy again
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        //this deploys the code a new aggregator in the local chain
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMAL,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
