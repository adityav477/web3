// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Simplestorage} from "./Simplestorage.sol";
contract AddSimplestorage is Simplestorage {
    //override- to override the store function which has "virtual" keyword on the store function in Siplestorage.sol
    function store (uint256 _number) public override {
        myfavouritenumber = _number + 5;
    }
}
