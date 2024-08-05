// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract RaffleTest is Test {
    /* Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 timeInterval;
    address vrfCoordinatorAddress;
    uint64 subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    address link;

    address PLAYER = makeAddr("player");

    uint256 constant INITIAL_BALANCE = 10 ether;
    uint256 constant ENTER_AMOUNT = 0.25 ether;

    /* Modifieres */
    modifier participate() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTER_AMOUNT}();
        _;
    }

    modifier participatedAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTER_AMOUNT}();
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.run();
        (
            entranceFee,
            timeInterval,
            vrfCoordinatorAddress,
            subscriptionId,
            keyHash,
            callbackGasLimit,
            link
        ) = helperConfig.realNetworkConfig();

        vm.deal(PLAYER, INITIAL_BALANCE);
    }

    function testRaffleStateisOpen() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRejectsForNotEnoughEth() external {
        vm.prank(PLAYER);
        vm.expectRevert();
        raffle.enterRaffle();
    }

    function testPlayersArrayGetsUpdatedForSinglePlayer() external participate {
        vm.prank(PLAYER);
        assertEq(raffle.getPlayers(0), PLAYER);
    }

    function testRaffleRevertsOnCalculatingState() external participate {
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 2);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_raffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTER_AMOUNT}();
    }

    function testEnteredRaffleEventGetsEmitted() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: ENTER_AMOUNT}();
    }

    /* UpKeep */
    function testUpkeepNeededFailsForNoTimePassed() external participate {
        (bool upKeep, ) = raffle.checkUpkeep();
        assertEq(upKeep, false);
    }

    function testUpkeepNeededFailsForNoPlayer() external {
        vm.prank(PLAYER);
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        (bool upKeep, ) = raffle.checkUpkeep();
        assertEq(upKeep, false);
    }

    function testUpKeepNeededFailsForCalculatingState() external participate {
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upKeepNeeded, ) = raffle.checkUpkeep();
        assert(!upKeepNeeded);
    }

    /* performUpkeep */
    function testPerformUpKeepRevertsForFalseUpKeep() external {
        uint256 balance = 0;
        uint256 playersArrayLength = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpKeepFailed.selector,
                balance,
                playersArrayLength,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    //redundant only to use for getting logs fromt he emitted events
    function testPerformrUpKeepEmitsRequestId()
        external
        participatedAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();
        assert(recordedLogs[1].topics[1] > 0);
        assert(uint256(raffle.getRaffleState()) == 1);
    }

    /* fulfillRandomWords */
    function testFulFillRandomWordsForRandomRequestIdsFuzzyTest(
        uint256 randomRequestIds
    ) external participatedAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorAddress).fulfillRandomWords(
            randomRequestIds,
            address(raffle)
        );
    }

    function testTimePassedWinnerPickedPrizeTransfered()
        external
        participatedAndTimePassed
    {
        for (uint256 i = 1; i <= 5; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, INITIAL_BALANCE);
            raffle.enterRaffle{value: ENTER_AMOUNT}();
        }

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        console.log("requqestId is ", uint256(requestId));

        VRFCoordinatorV2Mock(vrfCoordinatorAddress).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        console.log("ENTER_AMOUNT", (ENTER_AMOUNT * 5) + INITIAL_BALANCE);
        console.log("winner balance is ", raffle.getRecentWinnerBalance());

        assert(address(raffle).balance == 0);
        assertEq(
            raffle.getRecentWinnerBalance(),
            (ENTER_AMOUNT * 5) + INITIAL_BALANCE
        );
        assertEq(raffle.getPlayersLength(), 0);
        assertEq(uint256(raffle.getRaffleState()), 0);
        assert(raffle.getLastTimeStamp() > previousTimeStamp);
    }
}
