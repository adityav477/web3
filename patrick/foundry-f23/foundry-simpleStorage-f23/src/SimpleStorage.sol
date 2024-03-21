// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleStorage {
    uint256 public favouriteNumber;

    function addFavouriteNumber(uint256 favouriteNumber1) public {
        favouriteNumber = favouriteNumber1;
    }
}
