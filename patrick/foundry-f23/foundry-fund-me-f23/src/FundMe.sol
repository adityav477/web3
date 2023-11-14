// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PriceConverter} from "./PriceConverter.sol";

contract FundMe {
    //to add priceconverter library and abi's to uint256
    using PriceConverter for uint256;

    uint256 public constant minDonation = 5; //constant to minimize the gas fees cause minDonation is only declared once

    //to store the addresses of funders in an address array
    address[] funder;

    mapping(address funder => uint256 amountFunded) public addresstoamoundFuded;

    //to fund which can be done by anyone
    function fund() public payable {
        require(
            msg.value.convertodollars() >= (minDonation * 1e18),
            "the message was reverted"
        );

        funder.push(msg.sender);
        addresstoamoundFuded[msg.sender] += msg.value;
    }

    // withdraw

    address public immutable owner; //use immutable cause after deployment it is not getting used again

    //constructor immediately executes the lines inside it as soon as the contract is deployed
    constructor() {
        owner = msg.sender;
    }

    function withdraw() public isowner {
        //if != owner then return the error message

        //this for loop makes the value associated with each address to 0
        //if after withdrawal any past funder funds again then it will be added to the prior fund which is already withdrawn
        for (
            uint256 funderindex = 0;
            funderindex < funder.length;
            funderindex++
        ) {
            addresstoamoundFuded[funder[funderindex]] = 0;
        }

        //this to make the funder array empty
        funder = new address[](0);

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
}
