// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Interface} from "chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "chainlink/v0.8/shared/access/ConfirmedOwner.sol";

/// @title Lottery Game
/// @author Subham Paul
/// @notice This is the program/smart contract that will automatically handle the game logic and winner declaration.
/// @dev Implements Chainlink VRFv2
contract Lottery is Script, VRFConsumerBaseV2, ConfirmedOwner {
    error Lottery__NotEnoughETHSent();

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

    event EnteredLottery(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) ConfirmedOwner(msg.sender) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    // Function to enter the lottery game
    function enterLotteryGame() external payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughETHSent();
        }

        emit EnteredLottery(msg.sender);
        s_lotteryPlayers.push(payable(msg.sender));
    }

    // Function to pick random winner
    function pickWinner() external onlyOwner {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        // Will revert if subscription is not set and funded.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_OF_RANDOM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {}

    /** Getter Functions */
    function get_EntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
