// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {CreateSubscription} from "../../script/Interactions.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "chainlink/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract LotteryTest is Test {
    event EnteredLottery(address indexed player);

    address public PLAYER = makeAddr("Bob");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    Lottery private lottery;
    HelperConfig private helperConfig;
    uint256 private entranceFee;
    uint256 private interval;
    address private vrfCoordinator;
    bytes32 private gasLane;
    uint64 private subscriptionId;
    uint32 private callbackGasLimit;
    address private link;

    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            subscriptionId = new CreateSubscription().createSubscription(
                vrfCoordinator
            );
        }

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function test_LotteryStateInitializesWithOpenState() public view {
        assert(lottery.get_LotteryState() == Lottery.LotteryState.OPEN);
    }

    function test_RevertsWhenPlayerDoesNotSendEnoughMoney() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(Lottery.Lottery__NotEnoughETHSent.selector);
        lottery.enterLotteryGame();
        vm.stopPrank();
    }

    function test_PlayerAddedToPoolAfterEnteringGame() public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        assert(lottery.get_Player(0) == PLAYER);
        vm.stopPrank();
    }

    function test_EmitsEventOnEntrance() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false);
        emit EnteredLottery(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.stopPrank();
    }

    function test_CannotEnterGameWhenCalculatingWinner() public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__LotteryNotOpen.selector);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.stopPrank();
    }

    /////////////////////////
    // checkUpkeep         //
    /////////////////////////

    function test_CheckUpKeepFailsIfNoBalanceSent() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upKeepNeeded, ) = lottery.checkUpkeep("");

        assert(!upKeepNeeded);
    }

    function test_CheckUpKeepFailsIfNoPlayers() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upKeepNeeded, ) = lottery.checkUpkeep("");

        assert(!upKeepNeeded);
    }

    function test_CheckUpKeepFailsIfLotteryStateNotOpen() public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
        Lottery.LotteryState lotteryState = lottery.get_LotteryState();
        vm.stopPrank();

        (bool upKeepNeeded, ) = lottery.checkUpkeep("");

        assert(lotteryState == Lottery.LotteryState.CALCULATING);
        assert(!upKeepNeeded);
    }

    function test_CheckUpKeepFailsIfTimeNotOver() public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.stopPrank();

        (bool upKeepNeeded, ) = lottery.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    function test_CheckUpKeepWorksWhenParametersAreGood() public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();

        (bool upKeepNeeded, ) = lottery.checkUpkeep("");
        assert(upKeepNeeded);
    }

    /////////////////////////
    // performUpKeep       //
    /////////////////////////

    function test_PerformUpKeepOnlyRunsWhenCheckUpKeepIsTrue() public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        lottery.performUpkeep("");
        vm.stopPrank();
    }

    function test_PerformUpKeepRevertsWhenCheckUpKeepIsFalse() public {
        uint256 balance = 0;
        uint256 players = 0;
        uint8 lotteryState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery__UpKeepNotNeeded.selector,
                balance,
                players,
                lotteryState
            )
        );
        lottery.performUpkeep("");
    }

    function test_PerformUpKeepUpdatesLotteryStateAndEmitsRequestIdEvent()
        public
    {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.recordLogs();
        lottery.performUpkeep("");
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId) > 0);
        assert(uint256(lottery.get_LotteryState()) == 1);
    }

      //////////////////////////
     // fullfillRandomWords  //
    //////////////////////////

    function test_FulfillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestID
    ) public {
        vm.startPrank(PLAYER);
        lottery.enterLotteryGame{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();

        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestID,
            address(lottery)
        );
    }
}
