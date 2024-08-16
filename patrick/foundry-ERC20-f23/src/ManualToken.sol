// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ManualToken {
    mapping(address => uint256) private s_balances;

    /* Errors */
    error ManualToken_NotEnoughBalance();

    function name() public pure returns (string memory) {
        return "Manual Token";
    }

    function totalSupply() public pure returns (uint256) {
        return 100 ether;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return s_balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        uint256 previousBalanceofSender = balanceOf(msg.sender);
        uint256 previousBalanceofReceiver = balanceOf(_to);

        if (_amount > previousBalanceofSender) {
            revert ManualToken_NotEnoughBalance();
        }

        s_balances[msg.sender] = s_balances[msg.sender] - _amount;
        s_balances[_to] = s_balances[_to] + _amount;

        uint256 afterBalanceOfSender = balanceOf(msg.sender);
        uint256 afterBalanceOfReceiver = balanceOf(_to);

        bool success = (previousBalanceofSender - afterBalanceOfSender ==
            _amount) &&
            (afterBalanceOfReceiver - previousBalanceofReceiver == _amount);
        return success;
    }
}
