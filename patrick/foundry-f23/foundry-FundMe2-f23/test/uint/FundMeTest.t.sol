// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //Constants
    uint256 constant SEND_ETH = 1 ether;
    address USER = makeAddr("user");
    uint256 INITIAL_BALANCE = 10 ether;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        //giving money to USER
        vm.deal(USER, INITIAL_BALANCE);
    }

    //test the getVersino
    function testgetVersion() public view {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    //testinf if the contract reverts when the eth sent is 0
    function testFundMeFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    //to test if the dataStructures of the fundme updates properly

    function testBalanceOfContractEqualsTotalMoneySent() public {
        for (uint256 i = 0; i < 5; i++) {
            address newAddress = makeAddr(string(abi.encode(i)));
            hoax(newAddress);
            fundMe.fund{value: SEND_ETH}();
            console.log(address(fundMe).balance);
        }

        uint256 totalBalance = SEND_ETH * 5;
        // console.log("totalBalnce is ", totalBalance);
        // console.log("fundMe balance is ", address(fundMe).balance);
        // console.log("test address is ", address(this));

        assertEq(address(fundMe).balance, totalBalance);
    }

    // Withdraw //
    function testOwnerIsMsgSender() public view {
        // console.log(fundMe.getOwner());
        // console.log(address(this));
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testWithdrawbyOwner() public {
        console.log("msg.sender is ", msg.sender);
        console.log("getowner returns ", fundMe.getOwner());
        vm.prank(msg.sender);
        fundMe.withdraw();
        assertEq(address(fundMe).balance, 0);
    }

    function testOnlyOwnerCanWithrdaw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testBalanceIsZeroAfterWithdraw() public {
        uint256 sendersBalanceBeforeWithdraw = address(msg.sender).balance;
        for (uint256 i = 0; i < 5; i++) {
            address newAddress = makeAddr(string(abi.encode(i)));
            hoax(newAddress, INITIAL_BALANCE);
            fundMe.fund{value: SEND_ETH}();
        }
        uint256 contractBalance = address(fundMe).balance;

        vm.prank(msg.sender);
        fundMe.withdraw();
        uint256 sendersBalanceAfterWithdraw = address(msg.sender).balance;

        assert(address(fundMe).balance == 0);
        assertEq(
            sendersBalanceBeforeWithdraw + contractBalance,
            sendersBalanceAfterWithdraw
        );
    }

    function testFunderBecomesEpmty() public {
        for (uint256 i = 0; i <= 5; i++) {
            address newAddress = makeAddr(string(abi.encode(i)));
            hoax(newAddress, INITIAL_BALANCE);
            fundMe.fund{value: SEND_ETH}();
            assertEq(fundMe.getFundersAddress(i), newAddress);
            assertEq(fundMe.getAddressToAmount(newAddress), SEND_ETH);
        }
    }

    // Withdraw *//

    function testMinimumUSD() public view {
        assertEq(fundMe.getMinimumUSD(), 5 ether);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_ETH}();
        _;
    }

    function testFunderArrayGetsUpdated() public funded {
        assertEq(fundMe.getFundersAddress(0), address(USER));
    }

    function testaddressToAmountGetUpdated() public funded {
        assertEq(fundMe.getAddressToAmount(address(USER)), SEND_ETH);
    }
}
