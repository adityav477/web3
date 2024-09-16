// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * In this contract we are going to implement a stable coin which
 * 1. Relative Stability = pegged to USD
 * 2. Stability Method - Algorithmic
 * 3. Collateral - exogenous
 *
 * This Will be only the contract to interact that is to mint and burn all the calculations and mechanism will be done by the DscEngine.sol
 */

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {console} from "forge-std/Test.sol";

// note - since erc20 burnable inherits erc20 we need to have erc20 in our constructor
contract DSC is ERC20Burnable, Ownable {
    /* Errors */
    error DSC__AmountCannotBeZeroOrNegative();
    error DSC__AmountGreaterThanBalance();
    error DSC__ReceiverCannotBeZeroAddress();

    /* Constants */ 
    address immutable i_owner;

    /* Constructor */
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {
      i_owner = msg.sender;
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        console.log("msg.sender is ",msg.sender);
        console.log("balance is ",balance);
        if (_amount <= 0) {
            revert DSC__AmountCannotBeZeroOrNegative();
        }

        if (_amount > balance) {
            revert DSC__AmountGreaterThanBalance();
        }

        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DSC__ReceiverCannotBeZeroAddress();
        }

        if (_amount <= 0) {
            revert DSC__AmountCannotBeZeroOrNegative();
        }

        _mint(_to, _amount);
        return true;
    }

    //getter functions 

  function getOwner() view external returns(address owner){
      return i_owner;
  }

}
