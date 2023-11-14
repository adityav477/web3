// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function giverate() internal view returns (uint256) {
        //to save the AggregatorV3Interface on address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        AggregatorV3Interface dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        //this is the format in which latestRoundData() sends the data
        (
            ,
            /* uint80 roundID */ int256 answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = dataFeed.latestRoundData();
        //answer is price of ETH in USD which will be 2000.00000000
        //to convert this to 18 decimal places we do answer * 1e10
        return uint256(answer * 1e10);
    }

    //to convert eht eth amount to dollars and takes the ETH in USD as input
    function convertodollars(
        uint256 depositedETH
    ) internal view returns (uint256 ethindollars) {
        return ((depositedETH * giverate()) / 1e18);
        //both depositedEth and giverate is 1e18 and their multiplicatoin gives 1e36 thus divide by 1e18
    }
}
