// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.i_owner());
        console.log(address(this));
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.i_owner(), msg.sender);
    }

    //test the getVersino
    function testgetVersion() public view {
      uint256 version = fundMe.getVersion();
      console.log(version);
      assertEq(version,4);
    }

    //testinf if the contract reverts when the eth sent is 0 
    function testFundMeFailsWithoutEnoughETH() public {
      vm.expectRevert();
      fundMe.fund();
    }

    //to test if the dataStructures of the fundme updates properly
    function testaddressToAmountGetUpdated() public {
      fundMe.fund{value: 10e18}();
      assertEq(fundMe.getAddressToAmount(address(this)),10e18);
      
    }
}
