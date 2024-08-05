// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Raffle is VRFConsumerBaseV2 {
    /** Errors */
    error Raffle_NotEnoughEth();
    error Raffle_TransferToWinnerFailed();
    error Raffle_raffleNotOpen();
    error Raffle_UpKeepFailed(
        uint256 contractBalance,
        uint256 playersLenght,
        uint256 raffleState
    );

    /** enums */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** Immutable */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;

    //VRF
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private i_callbackGasLimit;

    /** Storage */
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestIdEmitted(uint256 indexed requestId);

    //VRF
    uint16 REQUEST_CONFIRMATIONS = 3;
    uint32 NUM_WORDS = 1;

    constructor(
        uint256 entranceFee,
        uint256 timeInterval,
        address vrfCoordinatorAddress,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorAddress) {
        i_entranceFee = entranceFee;
        i_interval = timeInterval;
        s_lastTimeStamp = block.timestamp;

        //vrf
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
        s_raffleState = RaffleState.OPEN;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_raffleNotOpen();
        }
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEth();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep()
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        //if enough time has passed
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool playersLength = s_players.length > 0;
        bool balanceContract = address(this).balance > 0;
        bool raffleState = s_raffleState == RaffleState.OPEN;

        upkeepNeeded = (timePassed &&
            playersLength &&
            balanceContract &&
            raffleState);

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep();

        if (!upkeepNeeded) {
            revert Raffle_UpKeepFailed(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

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

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferToWinnerFailed();
        }
        s_players = new address payable[](0);

        emit PickedWinner(winner);
    }

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 indexNumber) external view returns (address) {
        return s_players[indexNumber];
    }

    function getPlayersLength() external view returns (uint256) {
        return s_players.length;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getRecentWinnerBalance() external view returns (uint256) {
        return address(s_recentWinner).balance;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
