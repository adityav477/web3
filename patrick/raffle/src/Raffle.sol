//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/** Imports */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {console} from "forge-std/console.sol";

// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/** Contracts */
contract Raffle is VRFConsumerBaseV2 {
    /** Errors */
    error Raffle_sendMoreToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_NoUpkeep(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /** Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** Immutable Variables */
    uint256 private immutable i_timeInterval;
    uint256 private immutable i_raffleEntranceFees;

    //chainlinVRF
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /** StateVariables */
    address payable[] private s_players;
    uint256 s_lastTimeStamp;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestIdEmitted(uint256 indexed requestId);

    /**  Functions */
    //constructors
    constructor(
        uint256 timeInterval,
        uint256 raffleEntranceFees,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(address(vrfCoordinator)) {
        i_timeInterval = timeInterval;
        i_raffleEntranceFees = raffleEntranceFees;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;

        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterTheRaffle() external payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        if (msg.value < i_raffleEntranceFees) {
            revert Raffle_sendMoreToEnterRaffle();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * Chainlink Automation - documentatoin
     */

    // CheckUpkeep
    /**
     * 1. Contract has balance
     * 2. The s_playes is not empty
     * 3. Enough Time has passed
     * 4. There is no pervious transaction going on i.e, the raffleState is opens
     */
    function checkUpkeep()
        public
        view
        returns (
            // bytes calldata /* checkData */
            bool upKeepNeeded,
            bytes memory /* performData */
        )
    {
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_timeInterval;
        bool contractBalance = address(this).balance > 0;
        bool playersCheck = s_players.length > 0;
        bool stateCheck = s_raffleState == RaffleState.OPEN;
        //when we explicitly declare the name of the return value then we need not to return it explicitly1
        upKeepNeeded = (timePassed &&
            contractBalance &&
            playersCheck &&
            stateCheck);
        //but here for redablility return explicitly
        return (upKeepNeeded, "0x0");
    }

    //previously pickTheWinner because of chainlinkAutomation we need to change the name to performUpkeep

    function performUpkeep(bytes calldata /* performDate */) external {
        (bool upkeepNeeded, ) = checkUpkeep();
        if (!upkeepNeeded) {
          console.log(address(this).balance);
            revert Raffle_NoUpkeep(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        //to set the raffle to CALCULATING because it takes time to get the num from chainlinkVRF
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestIdEmitted(requestId);
    }

    //for chainlikvrf refer documents
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        //we decide what happes with the random number sent by chainlink here
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
        // @dev thi sis done becasue
        s_recentWinner = winner;
        //@dev this opens the raffle again after the winner has been chosen
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);
    }

    /* GETTER FUNCTIONS */

    //to check the getRaffleState
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    //to get the s_players based on the index
    function getPlayerFromIndex(
        uint256 indexOfPlayer
    ) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinnerBalance() external view returns (uint256) {
        return address(s_recentWinner).balance;
    }

    function getPlayersLength() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
