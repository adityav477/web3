// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DSC} from "../../src/DecentralizedStableCoin.sol";
import {DSCE} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    //events

    DeployDSC deployer;
    DSC dsc;
    DSCE engine;
    HelperConfig helper;
    address wEthPriceFeedAddress;
    address wBtcPriceFeedAddress;
    address wEthAddress;
    address wBtcAddress;

    address USER = makeAddr("user");
    address USER1 = makeAddr("user1");

    uint256 constant STARTING_USER_BALANCE = 100 ether;
    uint256 constant COLLATERAL_DEPOSIT = 10 ether;
    uint256 constant amountToBeMinted = 14000;
    uint256 constant amountToBeBurned = 10000;
    int256 constant newPriceOfEther = 1998 * 1e8;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, helper) = deployer.run();
        (
            wEthPriceFeedAddress,
            wBtcPriceFeedAddress,
            wEthAddress,
            wBtcAddress,

        ) = helper.actualNetworkConfig();

        ERC20Mock(wEthAddress).mint(USER, 100 ether);
        ERC20Mock(wEthAddress).mint(USER1, 100 ether);
        ERC20Mock(wBtcAddress).mint(USER, 100 ether);
        ERC20Mock(wBtcAddress).mint(USER1, 100 ether);
    }

    ///////////////////////
    //Modifier //
    ///////////////////////

    // deposit the engine with 10 ether
    modifier depositCollateralForUser() {
        vm.startPrank(USER);
        ERC20Mock(wEthAddress).approve(address(engine), COLLATERAL_DEPOSIT);
        engine.depositCollateral(COLLATERAL_DEPOSIT, wEthAddress);
        vm.stopPrank();
        _;
    }

    modifier depositCollateralAndMintDSCForUser1() {
        vm.startPrank(USER1);

        //we did that so that when the value of the eth fals in our test then it doesn't affects the healthfactor of the user1
        ERC20Mock(wEthAddress).approve(
            address(engine),
            COLLATERAL_DEPOSIT + 10 ether
        );
        engine.depositCollateral(COLLATERAL_DEPOSIT + 10 ether, wEthAddress);
        engine.mintDSC(amountToBeMinted);
        _;
    }

    ///////////////////////
    // constructor tests //
    ///////////////////////

    address[] tokenAddresses;
    address[] priceFeedToTokenAddresses;

    function testConstructorRevertsForUnEqualtokenAndPriceFeedAddresses()
        external
    {
        tokenAddresses.push(wEthAddress);
        priceFeedToTokenAddresses = [
            wEthPriceFeedAddress,
            wBtcPriceFeedAddress
        ];

        vm.expectRevert(
            DSCE.DSCE__collateralTokensNotMatchPriceFeedAddresses.selector
        );
        new DSCE(tokenAddresses, priceFeedToTokenAddresses, address(dsc));
    }

    function testDSCERevertsForZeroAddress() external {
        tokenAddresses = [wEthAddress, wBtcAddress];
        priceFeedToTokenAddresses = [
            wEthPriceFeedAddress,
            wBtcPriceFeedAddress
        ];

        vm.expectRevert(DSCE.DSCE__dscAddressNotValid.selector);
        new DSCE(tokenAddresses, priceFeedToTokenAddresses, address(0));
    }

    ///////////////////////
    //Deposit Collateral //
    //////////////////////

    function testUserCollateralDeposited() external depositCollateralForUser {
        uint256 totalCollateralForUserInUsd = engine
            .getTotalCollateralValueForUserInUsd(USER);
        // console.log("getTotalCollateralValueForUserInUsd " , totalCollateralForUserInUsd);
        uint256 totalCollateralToken = engine.getTokenEquivalentToAmount(
            wEthAddress,
            totalCollateralForUserInUsd
        );
        // console.log("totalCollateralValueInUsd ", totalCollateralToken);

        assertEq(totalCollateralToken, COLLATERAL_DEPOSIT);
    }

    // getTotalCollateralValueForUserInUsd 2000
    // totalCollateralValueInUsd 1,000,000,000,000,000,000

    ///////////////
    // Mint DSc ///
    ///////////////

    function testMintingDSC() external depositCollateralForUser {
        uint256 totalCollateralForUserInUsd = engine
            .getTotalCollateralValueForUserInUsd(USER);
        uint256 dscThatCanBeMinted = (totalCollateralForUserInUsd * 70) / 100;

        console.log(totalCollateralForUserInUsd);
        console.log(dscThatCanBeMinted);
        vm.prank(USER);
        engine.mintDSC(dscThatCanBeMinted);

        assertEq(engine.getDSCMintedByUser(USER), dscThatCanBeMinted);
    }

    function testRevertsForZeroMintingAmount() external {
        vm.expectRevert(DSCE.DSCE__NotEnoughAmount.selector);
        engine.mintDSC(0);
    }

    function testRevertsForNoCollateral() external {
        vm.prank(USER);
        vm.expectRevert(DSCE.DSCE__ZeroCollateralDeposited.selector);
        engine.mintDSC(10);
    }

    function testRevertsForWrongHealthFactor()
        external
        depositCollateralForUser
    {
        uint256 totalCollateralValueInUsd = engine
            .getTotalCollateralValueForUserInUsd(USER);
        uint256 dscThatCanBeMinted = (totalCollateralValueInUsd * 70) / 100;
        // console.log("totalCollateralValueInUsd is ",totalCollateralValueInUsd);
        // console.log("dscThatCanBeMinted is ",dscThatCanBeMinted);
        vm.prank(USER);
        vm.expectRevert(DSCE.DSCE__ThreshholdCollateralNotMaintained.selector);
        engine.mintDSC(dscThatCanBeMinted + 1);
    }

    function testDepostiCollateralAndMintDSC() external {
        vm.startPrank(USER);
        ERC20Mock(wEthAddress).approve(address(engine), COLLATERAL_DEPOSIT);
        engine.depositCollateral(COLLATERAL_DEPOSIT, wEthAddress);
        vm.stopPrank();
        uint256 totalCollateralForUserInUsd = engine
            .getTotalCollateralValueForUserInUsd(USER);
        uint256 dscThatCanBeMinted = (totalCollateralForUserInUsd * 70) / 100;

        console.log(totalCollateralForUserInUsd);
        console.log(dscThatCanBeMinted);
        vm.prank(USER);
        engine.mintDSC(dscThatCanBeMinted);
    }

    ////////////////////////////
    // Burn DSC ?///////////////
    ////////////////////////////

    function testRevertsIfTryToBurnMoreThanMintedDSC()
        external
        depositCollateralForUser
    {
        vm.startPrank(USER);
        engine.mintDSC(100);

        vm.expectRevert(DSCE.DSCE__NotEnoughDSC.selector);
        engine.burnDSC(200);
        vm.stopPrank();
    }

    function testRevertsForBurningZeroDSC() external {
        vm.expectRevert(DSCE.DSCE__NotEnoughAmount.selector);
        engine.burnDSC(0);
    }

    function testBurnDSC() external depositCollateralForUser {
        vm.startPrank(USER);
        engine.mintDSC(amountToBeMinted);

        // the erc20 of dsc takes engine as msg.sender and since it has not minted thus we approve engine on behalf of user to send and manage transactions
        dsc.approve(address(engine), amountToBeMinted);
        engine.burnDSC(amountToBeBurned);
        assertEq(engine.getDSCMintedByUser(USER), 4000);
        vm.stopPrank();
    }

    /////////////////////////
    // Redeem Collatera ////
    /////////////////////////

    /* NOTE:
     * total collateral in eth is 10 ether and the value of 10 ether is whose value will be 10 * 2000 = $20,000
     * and the total minting that can be done is 14000 dsc cause 1 dsc = $1
     * now if we redeem 2 ether than the value of collateral will 8 eth = $16,000 thus
     * the maximum dsc that we can mint without hurting the healthfactor is 0.70 * 16000 = $ 11,200
     */
    function testRedeemCollateral() external depositCollateralForUser {
        vm.startPrank(USER);
        engine.mintDSC(11200);

        engine.redeemCollateral(wEthAddress, 2 ether);

        uint256 userCollateral = engine.getAmountOfTokenForUser(
            wEthAddress,
            USER
        );
        uint256 expectedUserCollateral = 8 ether; // 10 - 2 ether = 8 ether

        assertEq(userCollateral, expectedUserCollateral);
        vm.stopPrank();
    }

    function testRedeemCollateralRevertsIfHealthFactorFailsAfterRedemption()
        external
        depositCollateralForUser
    {
        vm.startPrank(USER);
        engine.mintDSC(11200);

        vm.expectRevert(DSCE.DSCE__ThreshholdCollateralNotMaintained.selector);
        engine.redeemCollateral(wEthAddress, 3 ether);
        vm.stopPrank();
    }

    ////////////////////
    // RedeemAndBurn //
    ////////////////////

    /*
     * we redeem 8 ether which has value of $ 16000 ether and thus the amount of dsc
     * that needs to be burned to redeem the 8 ether without affecting the healthfactor is
     * 70% of $16000 is $11200
     */
    function testRedeemAndBurnDSC() external depositCollateralForUser {
        vm.startPrank(USER);
        engine.mintDSC(amountToBeMinted);

        // console.log("dsc.balanceOf[user] is ", dsc.balanceOf(USER));

        dsc.approve(address(engine), amountToBeMinted);

        engine.redeemCollateralAndBurnDSC(wEthAddress, 8 ether, 11200);

        assertEq(engine.getAmountOfTokenForUser(wEthAddress, USER), 2 ether);
        vm.stopPrank();
    }

    function testRedeemAndBurnRevertsForRedeemingCollateralThatAffectsTheHealthFactor()
        external
        depositCollateralForUser
    {
        vm.startPrank(USER);
        engine.mintDSC(amountToBeMinted);

        dsc.approve(address(engine), amountToBeMinted);

        vm.expectRevert(DSCE.DSCE__ThreshholdCollateralNotMaintained.selector);
        engine.redeemCollateralAndBurnDSC(wEthAddress, 9 ether, 11200);
        vm.stopPrank();
    }

    ////////////////////////
    // HealthFactor tests //
    ////////////////////////

    function testHealthFactorIsCorrect() external depositCollateralForUser {
        vm.startPrank(USER);
        engine.mintDSC(amountToBeMinted);

        assertEq(engine.getHealthFactor(USER), 70 * 1e18);
        vm.stopPrank();
    }

    function testHealthFactorRevertsZeroForNoDSCMinted()
        external
        depositCollateralForUser
    {
        vm.startPrank(USER);
        assertEq(engine.getHealthFactor(USER), 0);
        vm.stopPrank();
    }

    /////////////////////////////
    // Transofromer functions //
    /////////////////////////////

    function testGetValueUsd() external view {
        // console.log("wEthAddress",address(wEthAddress));

        uint256 actualBalance = engine.getUsdValue(wEthAddress, 2 * 1e18);
        // console.log("actualBalance ",actualBalance);
        uint256 expectedBalance = 4000;

        assertEq(actualBalance, expectedBalance);
    }

    function testDepositValueRevertsForZeroCollateral() external {
        // @dev: we need the engine to have some ether in his account
        // vm.prank(USER);
        // ERC20Mock(wEthAddress).approve(address(engine),10 ether);
        // console.log("balance of dsce engine is ",address(engine).balance);

        vm.prank(address(engine));
        vm.expectRevert(DSC.DSC__AmountCannotBeZeroOrNegative.selector);
        dsc.mint(USER, 0);
    }

    function testGetTokenBasedOnAmount() external view {
        uint256 getEthAmount = engine.getTokenEquivalentToAmount(
            wEthAddress,
            2000
        );
        uint256 expectedEthAmount = 1 ether;
        console.log("getEthAmount is ", getEthAmount);
        console.log("expectedEthAmount is ", expectedEthAmount);
        console.log("10e18 is ", uint256(10e18));
        assertEq(getEthAmount, expectedEthAmount);
    }

    //getEthAmount 10,000,000,000,000,000,000
    //expectedEthAmount 1,000,000,000,000,000,000
    //10e18 is 10,000,000,000,000,000,000

    /////////////////////////
    //Liquidation Tests /////
    /////////////////////////

    function testCantLiquidateHealthyUsers()
        external
        depositCollateralForUser
        depositCollateralAndMintDSCForUser1
    {
        vm.startPrank(USER);
        engine.mintDSC(amountToBeMinted);
        vm.stopPrank();

        vm.startPrank(USER1);
        ERC20Mock(wEthAddress).approve(address(engine), COLLATERAL_DEPOSIT);
        engine.depositCollateral(COLLATERAL_DEPOSIT, wEthAddress);
        engine.mintDSC(amountToBeMinted);

        vm.expectRevert(DSCE.DSCE__HealthFactorofUserIsFine.selector);
        engine.liquidate(wEthAddress, address(USER), amountToBeMinted);
        vm.stopPrank();
    }

    function testLiquidatesUnHealthyUsers()
        external
        depositCollateralForUser
        depositCollateralAndMintDSCForUser1
    {
        vm.startPrank(USER);
        engine.mintDSC(amountToBeMinted);
        console.log("healthfactor before ", engine.getHealthFactor(USER)); //  70,000,000,000,000,000,000
        vm.stopPrank();

        MockV3Aggregator(wEthPriceFeedAddress).updateAnswer(newPriceOfEther);
        vm.startPrank(USER1);
        dsc.approve(address(engine), amountToBeMinted);
        engine.liquidate(wEthAddress, address(USER), amountToBeMinted);
        console.log("healthFactor after is ", engine.getHealthFactor(USER)); // 70,070,070,070,070,070,000
        vm.stopPrank();
    }
}
