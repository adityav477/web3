// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;
import {Script} from "forge-std/Script.sol"; // confusion in the path of forge-std/Script.sol
import {Simplestorage} from "../src/Simplestorage.sol";

contract DeploySimplestorage is Script {
    function run() external returns (Simplestorage) {
        vm.startBroadcast();
        Simplestorage simplestorage = new Simplestorage();
        vm.stopBroadcast();
        return simplestorage;
    }
}
