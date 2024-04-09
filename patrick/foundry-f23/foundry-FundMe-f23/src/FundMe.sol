// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//custom errors to save gas price
error NotEnoughFunds();
error NotTheOwner();
error WithdrawalFailed();

contract FundMe {
    //to use the price converter library for every uint256
    using PriceConverter for uint256;

    //to set the minimux donatoin to 5 usd
    uint256 private constant minimumUsd = 5 * 1e18;

    //to save the funders addresses
    address[] funders;

    //mappings to store the amount funded with the address of the sender
    mapping(address funder => uint256 amount) addressToAmount;

    //to save the owner of the contract at the time of deployment
    address private immutable i_owner;

    //to store the AggregatorV3Interface throughout
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    //function to get the check the amount is greater then minimum dollar or not
    function fund() public payable {
        if (!(msg.value.getConversionRate(s_priceFeed) >= minimumUsd)) {
            revert NotEnoughFunds();
        }
        funders.push(msg.sender);
        addressToAmount[msg.sender] = msg.value;
    }

    //to withdraw the funds by the owner
    function withdraw() public payable is_owner {
        //here the funders is a storage variable thus we store it in a memory and use it
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmount[funders[funderIndex]] = 0;
        }

        //emptying the arry of funders
        funders = new address[](0);

        //sendint the balance eth of in contract to the ownders account
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!success) {
            revert WithdrawalFailed();
        }
    }

    //cheaper withdraw
    function cheaperWithdraw() public payable is_owner {
        //here the funders is a storage variable thus we store it in a memory and use it
        uint256 funderLength = funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < funderLength;
            funderIndex++
        ) {
            addressToAmount[funders[funderIndex]] = 0;
        }

        //emptying the arry of funders
        funders = new address[](0);

        //sendint the balance eth of in contract to the ownders account
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!success) {
            revert WithdrawalFailed();
        }
    }

    //getVersion for testing the if the priceFeed is workign accurately or not
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    //modifier to check the owner
    modifier is_owner() {
        if (msg.sender != i_owner) {
            revert NotTheOwner();
        }
        _;
    }

    // VIEW FUNCTIONS
    //to read the addressToAmount
    function getAddressToAmount(
        address sentAddress
    ) external view returns (uint256) {
        return addressToAmount[sentAddress];
    }

    //to get the element of funders array
    function getFunders(uint256 index) external view returns (address) {
        return funders[index];
    }

    //get minimumUsd
    function getMinimumUSD() external pure returns (uint256) {
        return minimumUsd;
    }

    //get owner of contract
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
