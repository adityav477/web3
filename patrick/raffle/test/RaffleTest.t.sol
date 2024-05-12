// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /* Events */
    event RaffleEntered(address indexed player);

    /** State Variables */
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 s_timeInterval;
    uint256 s_raffleEntranceFees;
    address s_vrfCoordinator;
    bytes32 s_keyHash;
    uint64 s_subscriptionId;
    uint32 s_callbackGasLimit;
    address s_link;

    address PLAYER = makeAddr("player");
    uint256 PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            s_timeInterval,
            s_raffleEntranceFees,
            s_vrfCoordinator,
            s_keyHash,
            s_subscriptionId,
            s_callbackGasLimit,
            s_link,

        ) = helperConfig.actualNetworkConfig();

        vm.deal(PLAYER, PLAYER_BALANCE);
    }

    //raffle is open
    function testRaffleIsOpen() external {
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /* Enter raffle */
    function testRaffleReturnsForNotEnoughETH() external {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_sendMoreToEnterRaffle.selector);
        raffle.enterTheRaffle();
    }

    //players entered
    function testPlayerEntered() external {
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
        assert(raffle.getPlayerFromIndex(0) == PLAYER);
    }

    //player added event check
    function testPlayerEnteredEvent() external {
        vm.prank(PLAYER);
        vm.expectEmit(address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
    }

    //function to test revert if the contract is calculating we do this by passing a timestap using vm.warp
    /**
     * first we enter the raffle and set the time nterval to the passed state and call the performUpkeep
     *  this makes the rafffle state to calculating
     *  then we expect revert from the contract while trying to enter the contract */
    function testCantEnterRaffleWhileCalculating() external {
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
        vm.warp(block.timestamp + s_timeInterval + 1); //this sets the time interval accordign to our will (only works in forked or local blockchain)
        vm.roll(block.number + 1); //roll adds a new block to the local or forked blockchain
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        raffle.enterTheRaffle{value: 1 ether}();
    }

    ////////////////////////
    //////checkupKeep///////
    ///////////////////////
    function testCheckUpKeepReturnsFalseForNoBalance() external {
        //Arrange
        vm.warp(block.timestamp + s_timeInterval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep();

        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseForCalculatingState() external {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
        vm.warp(block.timestamp + s_timeInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep();

        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseForNoTimestamp() external {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep();

        //assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsTrueForRightParams() external {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
        vm.warp(block.timestamp + s_timeInterval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep();

        //Assert
        assert(upKeepNeeded);
    }

    modifier playerEnteredandTimePassed() {
        vm.prank(PLAYER);
        raffle.enterTheRaffle{value: 1 ether}();
        vm.warp(block.timestamp + s_timeInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

    //to skip the contracts using vrfmock when the chainId is sepolia cause the difference in 
    //actual vrc(onchain) and the mockvrf using here 
    modifier skipForForkSepolia() {
      if(block.chainid == 11155111){
        return;
      }
      _;
    }

    ///////////////////// ///
    //////perofrmUpKeep//////
    ///////////////////// ///

    function testPerformUpKeepWorksIfUpKeepIsTrue()
        external
        playerEnteredandTimePassed
    {
        raffle.performUpkeep("");
    }

    function testPerformUpKeeRevertsForFalseUpKeep() external {
        //Assert
        uint256 currentBalance = 0;
        uint256 players = 0;
        uint256 raffleState = 0; //cause in RaffleState we have open at the first place
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_NoUpkeep.selector,
                currentBalance,
                players,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }


    function testPerformUpKeepEmitsRequestId()
        external
        playerEnteredandTimePassed
    {
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState rState = raffle.getRaffleState();
        // console.log(uint256(requestId));

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    ////////////////////////
    // fulfilRandomWords //
    // /////////////////

    //fuzz test
    //for random requestId we get revert back
    function testFullFillRandomWordsFailsForRandomRequestId(
        uint256 randomRequestId
    ) external playerEnteredandTimePassed skipForForkSepolia{
        //Act/Assert

        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(s_vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFullFillRandomWordsFully()
        external
        playerEnteredandTimePassed
        skipForForkSepolia
    {
        //Act
        uint256 morePlayers = 6;
        uint256 startingNumber = 1;

        //adds more players to the raffle
        for (
            uint256 i = startingNumber;
            i < morePlayers + startingNumber;
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, PLAYER_BALANCE);
            raffle.enterTheRaffle{value: 1 ether}();
        }
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        // console.log("contract balance is ", address(raffle).balance);
        VRFCoordinatorV2Mock(s_vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // console.log(
        //     "winners balance after winnign ",
        //     raffle.getRecentWinnerBalance()
        // );

        //Assert
        //balance of contract is zero
        assert(address(raffle).balance == 0);
        assert(
            raffle.getRecentWinnerBalance() ==
                PLAYER_BALANCE -
                    1 ether +
                    ((morePlayers + startingNumber) * 1 ether)
        );
        assert(raffle.getPlayersLength() == 0);
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(previousTimeStamp < raffle.getLastTimeStamp());
    }
}
