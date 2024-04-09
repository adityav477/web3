// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //makeAddr
    address USER = makeAddr("user");
    uint256 constant CHANDA = 0.1 ether;
    uint256 constant INITIAL_BALANCE = 10 ether;

    //setup is the functions that runs first
    // first deploys the deployFundme and then deployse fundMe
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        //assigning balance to USER
        //deal is used to give fake balance to a makeAddr
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testMinimumUsd() public view {
        assertEq(fundMe.getMinimumUSD(), 5e18);
    }

    function testOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    //to test to rever if no value was send with contract
    function testWithoutFundsReverts() public {
        vm.expectRevert();
        fundMe.fund();
    }

    //to check if the addressToAmount get's updated
    function testAddressToAmountUpdation() public {
        vm.prank(USER);
        fundMe.fund{value: CHANDA}();
        assertEq(fundMe.getAddressToAmount(USER), 0.1 ether);
    }

    //using modifier to write a code to send value to fundMe with prank
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: CHANDA}();
        _;
    }

    //test if the funders is getting updated
    function testFundersUpdation() public funded {
        assertEq(USER, fundMe.getFunders(0));
    }

    //test if only owner can withdraw
    function testUSERCantWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw(); //this works because the deploy function is deploying fundMe hence only it can withdraw
    }

    //testig withdraw when single funder is there
    function testWithdrawWithSingleFunder() public funded {
        //Arragne
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endOwnerBalance = fundMe.getOwner().balance;
        uint256 endContractBalance = address(fundMe).balance;

        assertEq(
            startingOwnerBalance + startingContractBalance,
            endOwnerBalance
        );
        assertEq(endContractBalance, 0);
    }

    //testing wwith multiple testFundersUpdation
    function testWitnMultipleFunders() public funded {
        //Arrange
        //number of accounts which will fund
        uint160 numberOfFunders = 10; //used 160 becaue that's what\s used for explicitly type conversion from
        // number to address

        for (uint160 index = 1; index < numberOfFunders; index++) {
            //hoax does both the things done by prank and deal
            hoax(address(index), INITIAL_BALANCE);
            fundMe.fund{value: CHANDA}();
        }

        //Act
        vm.prank(msg.sender);
        // console.log(USER);
        // console.log(address(this));
        // console.log(msg.sender);
        // console.log(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        assert(address(fundMe).balance == 0);
    }

    //cheaper testWithmutltplefuonders
    function testWithdrawWithMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;

        for (uint160 index = 1; index < numberOfFunders; index++) {
            hoax(address(index), INITIAL_BALANCE);
            fundMe.fund{value: CHANDA}();
        }

        //Act
        vm.prank(msg.sender);
        fundMe.cheaperWithdraw();

        //Assert
        assert(address(fundMe).balance == 0);
    }
}
