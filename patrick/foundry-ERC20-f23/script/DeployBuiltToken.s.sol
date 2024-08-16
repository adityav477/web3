// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {BuiltToken} from "../src/BuiltToken.sol";

contract DeployBuiltToken is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns (BuiltToken) {
        vm.startBroadcast();
        BuiltToken builtToken = new BuiltToken(INITIAL_SUPPLY);
        vm.stopBroadcast();

        return builtToken;
    }
}
