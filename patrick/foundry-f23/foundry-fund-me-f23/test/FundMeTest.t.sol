// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //to make a fake address using makeAddr
    address USER = makeAddr("user");

    //to avoind magic numbers
    uint256 SEND_VALUE = 0.1 ether; //10000000000000000
    uint256 STARTING_BALANCE = 10 ether;

    //i used both external and public and it compiled perfectly for both
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        //did this because the changes in DeployFundMe get's directly reflected in Test saving time
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        //to give the USER some balance
        vm.deal(USER, STARTING_BALANCE);
    }

    //pubic becasue can be accessed by anyone something like that
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.minDonation(), 5);
    }

    function testOwner() public {
        // console.log(fundMe.owner());
        // console.log(msg.sender);

        assertEq(fundMe.owner(), msg.sender);
    }

    function testFundFailWithoutETH() public {
        vm.expectRevert(); //this test is true if the revert conditions is met which is fund() reverts if no eth is provided
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        //prank - makes the next transactioN will be sent by USER
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        // console.log(msg.sender);
        // console.log(address(this));
        console.log(USER);

        // uint256 amount = fundMe.getAddressToAmount(address(this);
        uint256 amount = fundMe.getAddressToAmount(USER);
        assertEq(amount, SEND_VALUE);
    }
}

//notes
//1.vm.prank(address) - sends the next tx from the address provided
//2.makeAddr("user") - makes and fake address
//3.vm.deal(USER,STARTING_BALANCE) - gives the balance in the USER i.e, fake address
