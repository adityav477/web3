// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //i used both external and public and it compiled perfectly for both
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        //did this because the changes in DeployFundMe get's directly reflected in Test saving time
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    //pubic becasue can be accessed by anyone something like that
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.minDonation(), 5);
    }

    function testOwner() public {
        console.log(fundMe.owner());
        console.log(msg.sender);
        assertEq(fundMe.owner(), msg.sender);
    }
}
