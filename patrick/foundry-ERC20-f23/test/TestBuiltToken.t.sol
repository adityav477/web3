// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BuiltToken} from "../src/BuiltToken.sol";
import {DeployBuiltToken} from "../script/DeployBuiltToken.s.sol";

contract TestBuiltToken is Test {
    BuiltToken builtToken;

    address add1 = makeAddr("address 1");
    address add2 = makeAddr("address 2");

    uint256 constant AMOUNT = 1 ether;
    uint256 constant INITIAL_BALANCE = 10 ether;

    function setUp() external {
        DeployBuiltToken deploy = new DeployBuiltToken();
        builtToken = deploy.run();

        vm.prank(msg.sender);
        builtToken.transfer(add1, INITIAL_BALANCE);
    }

    function testAdd1Balance() external {
        vm.prank(add1);
        builtToken.transfer(add2, AMOUNT);
        assertEq(builtToken.balanceOf(add2), AMOUNT);
        assertEq(builtToken.balanceOf(add1), INITIAL_BALANCE - AMOUNT);
    }

    function testAllowances() external {
        vm.prank(add1);
        builtToken.approve(add2, AMOUNT);

        vm.prank(add2);
        builtToken.transferFrom(add1, add2, AMOUNT);
    }

    function testRevertsForAmountGreaterThanInitialSupply() external {
        vm.prank(msg.sender);
        vm.expectRevert();
        builtToken.transfer(add1, 1001 ether);
    }

    function testAllowanceRevertsForAmountGreaterThanAllowedAmount() external {
        vm.prank(add1);
        builtToken.transfer(add2, AMOUNT);

        vm.prank(add2);
        vm.expectRevert();
        builtToken.transferFrom(add1, add2, AMOUNT + 1);
    }
}
