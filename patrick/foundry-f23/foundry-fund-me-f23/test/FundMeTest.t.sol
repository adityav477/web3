// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //i used both external and public and it compiled perfectly for both
    function setUp() external {
        fundMe = new FundMe();
    }

    //pubic becasue can be accessed by anyone something like that
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.minDonation(), 5);
    }

    function testOwner() public {
        console.log(fundMe.owner());
        console.log(address(this));
        assertEq(fundMe.owner(), address(this));
    }
}
