// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {BasicNft} from "../../src/BasicNft.sol";
import {DeployBasicNft} from "../../script/DeployBasicNft.s.sol";

contract TestBasicNft is Test {
    BasicNft public basicNft;
    address public USER = makeAddr("user");
    string public constant PUG =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function setUp() external {
        DeployBasicNft deployer = new DeployBasicNft();
        basicNft = deployer.run();
    }

    /* 
    the string is the array of the bytes now we need to turn the arry of bytes in a byte and then we turn the 
    bytes in byte32 that is a hash it with the help of keccak256 whch turns the bytes to bytes32 now we can compare 
    cause we cannot compare the arrays directly either we need to use the for loop or we can do the keccak256 to compare 
      */

    function testName() external view {
        string memory currentName = "DAWGGY";
        string memory actualName = basicNft.name();

        assertEq(
            keccak256(abi.encode(currentName)),
            keccak256(abi.encode(actualName))
        );
    }

    function testMintFunction() external {
        vm.prank(USER);
        basicNft.mintNft(PUG);

        assertEq(basicNft.balanceOf(USER), 1);
        assertEq(
            keccak256(abi.encode(basicNft.tokenURI(0))),
            keccak256(abi.encode(PUG))
        );
    }
}
