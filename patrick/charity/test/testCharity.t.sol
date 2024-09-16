// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DeployCharity} from "../script/DeployCharity.s.sol";
import {CharityDonation} from "../src/Charity.sol";
import {Test} from "forge-std/Test.sol";

contract TestCharityDonation is Test {
    CharityDonation charityDonation;

    function setUp() external {
        DeployCharity deployer = new DeployCharity();
        charityDonation = deployer.run();
    }

    function testisOwner() external view {
        address owner1 = charityDonation.getOwner();
        assertEq(owner1, address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    }
}
