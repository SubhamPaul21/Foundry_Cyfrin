// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/v0.8/vrf/VRFConsumerBaseV2.sol";

/// @title Lottery Game
/// @author Subham Paul
/// @notice This is the program/smart contract that will automatically handle the game logic and winner declaration.
/// @dev Implements Chainlink VRFv2
contract Lottery is VRFConsumerBaseV2 {
    error Lottery__NotEnoughETHSent();
    error Lottery__TransferFailed();
    error Lottery__LotteryNotOpen();
    error Lottery__UpKeepNotNeeded(uint256, uint256, uint8);

    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /** @dev Variable to set the minimum number of confirmation blocks on VRF requests */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    /** @dev Variable to set the number of random values we want to fetch */
    uint32 private constant NUM_OF_RANDOM_WORDS = 1;

    /** @dev Variable to set the entrance fee for the lottery game */
    uint256 private immutable i_entranceFee;
    /** @dev Variable to store the interval in seconds */
    uint256 private immutable i_interval;
    /** @dev Variable to store the VRF Coordinator instance for Sepolia Testnet */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    /** @dev Variable to store the Gas lane to use */
    bytes32 private immutable i_gasLane;
    /** @dev Variable to store the VRF Subscription ID */
    uint64 private immutable i_subscriptionId;
    /** @dev Variable to store the Call back Gas Limit */
    uint32 private immutable i_callbackGasLimit;
    /** @dev Variable to store the lottery players in a dynamic array */
    address payable[] private s_lotteryPlayers;
    /** @dev Variable to store the last time stamp */
    uint256 private s_lastTimeStamp;
    /** @dev Variable to store the recent winner's address */
    address private s_recentWinner;
    /** @dev Variable to store the current Lottery State */
    LotteryState private s_lotteryState;

    event EnteredLottery(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_lotteryState = LotteryState.OPEN;
    }

    // Function to enter the lottery game
    function enterLotteryGame() external payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughETHSent();
        }

        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }

        emit EnteredLottery(msg.sender);
        s_lotteryPlayers.push(payable(msg.sender));
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_lotteryPlayers.length;
        address payable winner = s_lotteryPlayers[indexOfWinner];
        s_recentWinner = winner;
        // Set lottery state back to OPEN for players to enter the game
        s_lotteryState = LotteryState.OPEN;
        // Reset the lottery players list for initiating new game
        s_lotteryPlayers = new address payable[](0);
        // Set the last time stamp to current time for new lottery game calculations
        s_lastTimeStamp = block.timestamp;
        // Send the lottery winning amount to random chosen winner
        (bool sent, ) = winner.call{value: address(this).balance}("");
        if (!sent) {
            revert Lottery__TransferFailed();
        }
        emit PickedWinner(winner);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded =
            ((block.timestamp - s_lastTimeStamp) >= i_interval) &&
            (s_lotteryState == LotteryState.OPEN) &&
            (s_lotteryPlayers.length > 0) &&
            (address(this).balance > 0);
        return (upkeepNeeded, "0x0");
    }

    // Function to pick random winner
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                s_lotteryPlayers.length,
                uint8(s_lotteryState)
            );
        }

        s_lotteryState = LotteryState.CALCULATING;
        // Will revert if subscription is not set and funded.
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_OF_RANDOM_WORDS
        );
    }

    /** Getter Functions */
    function get_EntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function get_LotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    function get_Player(uint256 playerIndex) external view returns (address) {
        return s_lotteryPlayers[playerIndex];
    }
}
