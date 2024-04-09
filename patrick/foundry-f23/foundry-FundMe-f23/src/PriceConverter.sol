// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //function to get the eth in usdkk
    function getPrice(AggregatorV3Interface s_priceFeed) internal view returns (uint256) {
        (, int answer, , , ) = s_priceFeed.latestRoundData();

        return uint256(answer * 1e10);
    }

    //to get the conversin rate based on the eth/usd get
    function getConversionRate(
        uint256 ethSent,
        AggregatorV3Interface s_priceFeed
    ) internal view returns (uint256) {
        uint256 ethInUsd = getPrice(s_priceFeed);
        uint256 ethSentInUsd = (ethInUsd * ethSent) / 1e18;
        return ethSentInUsd;
    }
}
