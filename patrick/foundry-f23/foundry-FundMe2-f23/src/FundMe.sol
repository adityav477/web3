//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();
error InSufficientFunds();
error TransferFailed();

contract FundMe {
    //calculate the current price and the amount sent through in dollars
    using PriceConverter for uint256;
    //to get a global AggregatorV3Interface
    AggregatorV3Interface dataFeed;

    //declaring the minimum USD
    uint256 private constant MINIMUM_USD = 5 * 1e18;

    //address array to save the funders addresseses
    address[] private s_funder;

    //mapping to map the addresses of funders to the amoutn they have deposited
    mapping(address funder => uint256 amountFunded) addressToAmount;

    //to save make the address of deployer as the only one to be able to withdraw the funders
    address private immutable i_owner;

    //constructor acts as groundwork while deploying the contracts
    constructor(address priceFeedAddress) {
        dataFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    //function to fund the contract
    function fund() public payable {
        if (!(msg.value.getConversionRate(dataFeed) >= MINIMUM_USD)) {
            revert InSufficientFunds();
        }
        s_funder.push(msg.sender);
        addressToAmount[msg.sender] = addressToAmount[msg.sender] + msg.value;
    }

    //to winthdraw
    function withdraw() public onlyOwner {
        //emptying the funders array and the addressToAmount funded

        for (uint256 index = 0; index < s_funder.length; index++) {
            addressToAmount[s_funder[index]] = 0;
        }
        s_funder = new address[](0);

        //now need to transfer the money saved in the contract back to the i_owner
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!success) {
            revert TransferFailed();
        }
    }

    function cheaperWithdraw() public onlyOwner {
        //cheaper because here we don't read from a storage variable with eveyr loop instance
        uint256 fundersLength = s_funder.length;

        for (uint256 index = 0; index < fundersLength; index++) {
            addressToAmount[s_funder[index]] = 0;
        }
        s_funder = new address[](0);

        //now need to transfer the money saved in the contract back to the i_owner
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!success) {
            revert TransferFailed();
        }
    }

    //modifieres
    modifier onlyOwner() {
        if (!(msg.sender == i_owner)) {
            revert NotOwner();
        }
        _;
    }

    // //receive
    // receive() external payable {
    //     fund();
    // }
    //
    // fallback() external payable {
    //     fund();
    // }

    //View functions to read the values of private stored variables or constants
    //get version to test AggregatorV3Interface

    function getMinimumUSD() public pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getFundersAddress(uint256 index) public view returns (address) {
        return s_funder[index];
    }

    function getVersion() public view returns (uint256) {
        return dataFeed.version();
    }

    function getAddressToAmount(
        address sentAddress
    ) external view returns (uint256) {
        return addressToAmount[sentAddress];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
