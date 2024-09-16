// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    NetworkConfig public actualNetworkConfig;

    uint256 DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint8 constant DECIMALS = 8;
    int256 constant MOCK_ETH_INITIAL_ANSWER = 2000e8;
    int256 constant MOCK_BTC_INITIAL_ANSWER = 1000e8;

    struct NetworkConfig {
        address wEthPriceFeedAddress;
        address wBtcPriceFeedAddress;
        address wEthAddress;
        address wBtcAddress;
        uint256 deployerKey;
    }

    constructor() {
        if (block.chainid == 11155111) {
            actualNetworkConfig = getSepoliaNetworkConfig();
        } else {
            actualNetworkConfig = createAndGetLocalNetworkConfig();
        }
    }

    function getSepoliaNetworkConfig()
        internal
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                wEthPriceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
                wBtcPriceFeedAddress: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
                wEthAddress: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
                wBtcAddress: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function createAndGetLocalNetworkConfig()
        internal
        returns (NetworkConfig memory)
    {
        if (actualNetworkConfig.wEthPriceFeedAddress != address(0)) {
            return actualNetworkConfig;
        }

        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        MockV3Aggregator wEthPriceFeedAddress = new MockV3Aggregator(
            DECIMALS,
            MOCK_ETH_INITIAL_ANSWER
        );
        ERC20Mock wEthAddress = new ERC20Mock();

        MockV3Aggregator wBtcPriceFeedAddress = new MockV3Aggregator(
            DECIMALS,
            MOCK_BTC_INITIAL_ANSWER
        );
        ERC20Mock wBtcAddress = new ERC20Mock();
        vm.stopBroadcast();

        return
            NetworkConfig({
                wEthPriceFeedAddress: address(wEthPriceFeedAddress),
                wBtcPriceFeedAddress: address(wBtcPriceFeedAddress),
                wEthAddress: address(wEthAddress),
                wBtcAddress: address(wBtcAddress),
                deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
            });
    }
}
