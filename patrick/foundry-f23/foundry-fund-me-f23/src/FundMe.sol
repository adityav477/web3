// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    //to add priceconverter library and abi's to uint256
    using PriceConverter for uint256;

    uint256 public constant minDonation = 5; //constant to minimize the gas fees cause minDonation is only declared once

    //this used for refactoring so as to make the contract deployable on any chain with the provided node address
    AggregatorV3Interface s_priceFeed;

    //to store the addresses of funders in an address array
    address[] private s_funder;

    mapping(address funder => uint256 amountFunded)
        private s_addresstoamoundFuded;

    //to fund which can be done by anyone
    function fund() public payable {
        require(
            msg.value.convertodollars(s_priceFeed) >= (minDonation * 1e18),
            "the message was reverted"
        );

        s_funder.push(msg.sender);
        s_addresstoamoundFuded[msg.sender] += msg.value;
    }

    //to check whether the function is working or not we use this
    function getVersion() public view returns (uint256) {
        //AggregatorV3Interface dataFeed = new AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //return dataFeed.Version();

        //this after refactoring to get version
        return s_priceFeed.version();
    }

    // withdraw

    address public immutable owner; //use immutable cause after deployment it is not getting used again

    //constructor immediately executes the lines inside it as soon as the contract is deployed
    constructor(address priceFeed) {
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function withdraw() public isowner {
        //if != owner then return the error message

        //this for loop makes the value associated with each address to 0
        //if after withdrawal any past funder funds again then it will be added to the prior fund which is already withdrawn
        for (
            uint256 funderindex = 0;
            funderindex < s_funder.length;
            funderindex++
        ) {
            s_addresstoamoundFuded[s_funder[funderindex]] = 0;
        }

        //this to make the funder array empty
        s_funder = new address[](0);

        //now we need to transfer the balance from the contract to the owners account
        //for more ifno go to cahgtpt blockchain list
        // //1.transfer
        // payable(msg.sender).transfer(address(this).balance);

        // //2.send - returns a bool for error
        // bool successsend = payable(msg.sender).send(address(this).balance);
        // require(successsend,"the withdraw function gets reverted");

        //3.call - the most suggested one
        //call returns two variable: one - to indicate success, second - some data in bytes
        (bool successcall, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(successcall, "successcall failed");
    }

    function cheaperwithdraw() public isowner {
        uint256 funderlenght = s_funder.length;
        for (
            uint256 funderindex = 0;
            funderindex < funderlenght;
            funderindex++
        ) {
            s_addresstoamoundFuded[s_funder[funderindex]] = 0;
        }

        s_funder = new address[](0);

        (bool successcall, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(successcall, "successcall failed");
    }

    modifier isowner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    //recieve() and fallback() are used if the money is sent to the contract directly without using triggering any function
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()
    receive() external payable {
        fund(); //whenever there is transaction to contract without any data fund is triggered through receive function
    }

    fallback() external payable {
        fund(); //whenever there is funds transfered to contract with wrong data(i.e there is no proper function given)
        //  then also fund is triggered ;
    }

    //views and getters function used for testing
    //for testing the getAddressToAmount
    function getAddressToAmount(
        address fundersAddress
    ) public view returns (uint256) {
        return s_addresstoamoundFuded[fundersAddress];
    }

    //for gettting the address based on the index from the funders[] array
    function getFunder(uint256 index) public view returns (address) {
        return s_funder[index];
    }

    //get's the owner of the contract
    function getOwner() public view returns (address) {
        return owner;
    }
}
