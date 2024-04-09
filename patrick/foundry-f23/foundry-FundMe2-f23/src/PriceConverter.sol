// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //to get the exchange rate from chainlink
    function getPrice(
        AggregatorV3Interface dataFeed
    ) internal view returns (uint256) {
        // AggregatorV3Interface dataFeed = AggregatorV3Interface(
        //     0x694AA1769357215DE4FAC081bf1f309aDC325306
        // );
        (, int answer, , , ) = dataFeed.latestRoundData();
        return uint256(answer) / 1e8;
    }

    //to get the conversin rate
    function getConversionRate(
        uint256 sentAmount,
        AggregatorV3Interface dataFeed
    ) internal view returns (uint256) {
        uint256 exchangeRate = getPrice(dataFeed);
        uint256 sentAmountInUSD = (sentAmount * exchangeRate);
        return sentAmountInUSD;
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface dataFeed = AggregatorV3Interface(
    //         0x694AA1769357215DE4FAC081bf1f309aDC325306
    //     );
    //     return dataFeed.version();
    // }
}
