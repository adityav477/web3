// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.s.sol";

contract HelperConfig is Script {
    //we create a different structure based on the chainId so if in future
    //if there is need to send more details we can do it
    struct NetworkDetails {
        address priceFeed;
    }

    //to store the NetworkDetails which will be updated and paseed to FundMe for deployment
    NetworkDetails public actualNetworkDetails;

    constructor() {
        uint256 chainId = block.chainid;
        if (chainId == 11155111) {
            actualNetworkDetails = getSepolia();
        } else {
            actualNetworkDetails = getLocalChain();
        }
    }

    //to send back the sepolia address
    function getSepolia() public pure returns (NetworkDetails memory) {
        return
            NetworkDetails({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    //get address of Aggregatov3Interface for local chain using mocked StdChains
    function getLocalChain() public returns (NetworkDetails memory) {
        //if a address is already deployed then why to use and deploy other chain
        if (actualNetworkDetails.priceFeed != address(0)) {
            return actualNetworkDetails;
        }

        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(8, 2000e8);
        vm.stopBroadcast();
        return NetworkDetails({priceFeed: address(mockV3Aggregator)});
    }
}
