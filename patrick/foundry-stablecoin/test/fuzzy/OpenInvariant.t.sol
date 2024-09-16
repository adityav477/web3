// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DSCE} from "../../src/DSCEngine.sol";
import {DSC} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DSC dsc;
    DSCE engine;
    HelperConfig helper;
    address wEth;
    address wBtc;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, engine, helper) = deployer.run();
        (, , wEth, wBtc, ) = helper.actualNetworkConfig();

        Handler handler = new Handler(dsc, engine);

        targetContract(address(handler));
    }

    function invariant_TotalCollateralShouldBeGreaterThanTotalMintedDSC()
        external
        view
    {
        uint256 totalMintedDSC = dsc.totalSupply();

        uint256 totalWethDeposited = ERC20Mock(wEth).balanceOf(address(engine));
        uint256 totalBtcDeposted = ERC20Mock(wBtc).balanceOf(address(engine));

        uint256 totalWethDepositedInUsd = engine.getUsdValue(
            wEth,
            totalWethDeposited
        );
        uint256 totalBtcDepostedInUsd = engine.getUsdValue(
            wBtc,
            totalBtcDeposted
        );

        assert(
            totalWethDepositedInUsd + totalBtcDepostedInUsd >= totalMintedDSC
        );
    }
}
