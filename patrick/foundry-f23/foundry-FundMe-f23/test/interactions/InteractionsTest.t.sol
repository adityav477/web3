// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant CHANDA = 1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        // vm.prank(USER);
        fundMe = deployFundMe.run();
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testInteractionsFundFundMe() public {
        console.log(USER);
        console.log(fundMe.getOwner());

        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        assertEq(address(fundMe).balance, CHANDA);
    }

    function testInteractionsWithdrawFundMe() public {
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assertEq(address(fundMe).balance, 0);
    }
}
