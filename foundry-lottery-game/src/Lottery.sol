// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

/// @title Lottery Game
/// @author Subham Paul
/// @notice This is the program/smart contract that will automatically handle the game logic and winner declaration.
/// @dev Implements Chainlink VRFv2
contract Lottery is Script {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    // Function to enter the lottery game
    function enterLotteryGame() external payable {}

    // Function to pick random winner
    function pickWinner() external {}

    /** Getter Functions */
    function get_EntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
