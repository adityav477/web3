// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

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

    //test's whether the mappig function AddresstoAmount works properly
    function testFundUpdatesFundedDataStructure() public {
        //prank -  the next transactioN will be sent by USER
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        // console.log(msg.sender);
        // console.log(address(this));
        // console.log(USER);

        uint256 amount = fundMe.getAddressToAmount(USER);
        assertEq(amount, SEND_VALUE);
    }

    //test's wehther the s_funder works proprly in storing the addresses of the senders
    function testAddsFunderToArrayofFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address add = fundMe.getFunder(0);
        assertEq(add, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    //test's that only owner can withdraw the funds
    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);

        // console.log(USER);
        // console.log(fundMe.getOwner());

        vm.expectRevert();
        fundMe.withdraw(); //this fais becasue the USER is not the owner of the contract
    }

    //test withdraw function
    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //to check balance of ownder(here it is USER that deployed contract)
        uint256 startingFundMeBalance = address(fundMe).balance; //to check the balance in the fundMe contract

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // console.log(fundMe.getOwner());
        // console.log(address(this));

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance,
            (startingOwnerBalance + startingFundMeBalance)
        );
        assertEq(endingFundMeBalance, 0);
    }

    //testing with multiple funded contract
    function testWithdrawFromMultipleFunders() public {
        //Arrange
        //we use uint160 cause only these type of number's can be converted to address

        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1; //we start from 1 bebcuse address(0) reverts sometimes

        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            //to create and add balance to the various funder address
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Assert
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Act
        assert(address(fundMe).balance == 0);
        assert(
            (startingOwnerBalance + startingFundMeBalance) ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public {
        //Arrange
        //we use uint160 cause only these type of number's can be converted to address

        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1; //we start from 1 bebcuse address(0) reverts sometimes

        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            //to create and add balance to the various funder address
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Assert
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperwithdraw();
        vm.stopPrank();

        //Act
        assert(address(fundMe).balance == 0);
        assert(
            (startingOwnerBalance + startingFundMeBalance) ==
                fundMe.getOwner().balance
        );
    }
}

//notes
//1.vm.prank(address) - sends the next tx from the address provided this works only in test in foundry
//2.makeAddr("user") - makes and fake address
//3.vm.deal(USER,STARTING_BALANCE) - gives the balance in the USER i.e, fake address
//4.hoax("user",value) - hoax is combination of prank and deal and is a standard function so doesn't require vm.*
