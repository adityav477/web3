// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DSCE} from "../../src/DSCEngine.sol";
import {DSC} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../../test/mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSC dsc;
    DSCE engine;

    ERC20Mock wEth;
    ERC20Mock wBtc;

    uint256 public constant MAX_DEPOSIT_SIZE = type(uint96).max;
    address[] public depositedUsersAddresses;

    constructor(DSC _dsc, DSCE _engine) {
        dsc = _dsc;
        engine = _engine;

        address[] memory acceptedTokenAddresses = engine
            .getAcceptedTokenAddresses();

        wEth = ERC20Mock(acceptedTokenAddresses[0]);
        wBtc = ERC20Mock(acceptedTokenAddresses[1]);
    }

    function depositCollateral(uint256 collateralSeed, uint256 amount) public {
        ERC20Mock collateral = getToken(collateralSeed);
        amount = bound(amount, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amount);
        collateral.approve(address(engine), amount);
        engine.depositCollateral(amount, address(collateral));
        vm.stopPrank();
        depositedUsersAddresses.push(msg.sender);
    }

    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        address sender = depositedUsersAddresses[
            collateralSeed % depositedUsersAddresses.length
        ];

        ERC20Mock collateral = getToken(collateralSeed);
        amountCollateral = bound(amountCollateral, 0, MAX_DEPOSIT_SIZE);

        if (amountCollateral == 0) {
            return;
        }

        vm.startPrank(sender);
        engine.redeemCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    function mintDSC(uint256 amountToBeMinted, uint256 addressSeed) external {
        address sender = depositedUsersAddresses[
            addressSeed % depositedUsersAddresses.length
        ];

        uint256 collateralValueInUsd = engine
            .getTotalCollateralValueForUserInUsd(msg.sender);

        uint256 maxDscThatCanBeMinted = (collateralValueInUsd * 70) / 100;

        amountToBeMinted = bound(amountToBeMinted, 1, maxDscThatCanBeMinted);
        if (amountToBeMinted == 0) return;

        vm.startPrank(sender);
        engine.mintDSC(amountToBeMinted);
        vm.stopPrank();
    }

    function getToken(uint256 collateralSeed) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return wEth;
        }
        return wBtc;
    }
}
