// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {CustomToken} from "../src/CustomToken.sol";
import {DeployCustomToken} from "../script/DeployCustomToken.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestCustomToken is Test {
    CustomToken public customToken;
    DeployCustomToken public deployer;

    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployCustomToken();
        customToken = deployer.run();
    }

    // Ensure that the token is deployed with the correct name, symbol, and initial supply.
    function test_InitialDeployment() public view {
        assert(
            keccak256(abi.encodePacked(customToken.name())) ==
                keccak256(abi.encodePacked("Custom Token"))
        );
        assert(
            keccak256(abi.encodePacked(customToken.symbol())) ==
                keccak256(abi.encodePacked("CT"))
        );
        assert(customToken.totalSupply() == deployer.INITIAL_SUPPLY());
        assert(customToken.balanceOf(msg.sender) == deployer.INITIAL_SUPPLY());
    }

    function test_DeployerCanTransferBalanceToOthers()
        public
        transferredStartingBalanceToBob
    {
        // Assert
        assert(
            customToken.balanceOf(msg.sender) ==
                deployer.INITIAL_SUPPLY() - STARTING_BALANCE
        );
        assert(customToken.balanceOf(bob) == STARTING_BALANCE);
    }

    function test_TokenAllowanceWorks() public transferredStartingBalanceToBob {
        // Arrange
        uint256 INITIAL_ALLOWANCE = 5 ether;
        uint256 TRANSFER_AMOUNT = 3 ether;

        // Act
        vm.startPrank(bob);
        customToken.approve(alice, INITIAL_ALLOWANCE);
        vm.stopPrank();

        vm.startPrank(alice);
        customToken.transferFrom(bob, alice, TRANSFER_AMOUNT);
        vm.stopPrank();

        // Assert
        assert(customToken.balanceOf(alice) == TRANSFER_AMOUNT);
        assert(
            customToken.balanceOf(bob) == STARTING_BALANCE - TRANSFER_AMOUNT
        );
    }

    // Verify that Transfer events are emitted correctly when tokens are transferred.
    function test_TransferEvent() public transferredStartingBalanceToBob {
        uint256 amount = 5 ether;
        vm.startPrank(bob);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(bob, alice, amount);
        customToken.transfer(alice, amount);
        vm.stopPrank();
    }

    // Ensure that Approval events are emitted correctly when allowance is approved.
    function test_ApprovalEvent() public transferredStartingBalanceToBob {
        uint256 allowance = 10 ether;
        vm.startPrank(bob);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(bob, alice, allowance);
        customToken.approve(alice, allowance);
        vm.stopPrank();
    }

    // Verify Transfer events when transferFrom is used.
    function test_TransferFromEvent() public transferredStartingBalanceToBob {
        uint256 initialAllowance = 10 ether;
        uint256 transferAmount = 5 ether;

        vm.startPrank(bob);
        customToken.approve(alice, initialAllowance);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(bob, alice, transferAmount);
        customToken.transferFrom(bob, alice, transferAmount);
        vm.stopPrank();
    }

    // Ensure that trying to transfer more tokens than the sender has results in an error.
    function test_InsufficientBalance() public transferredStartingBalanceToBob {
        uint256 balance = customToken.balanceOf(bob);
        uint256 amountToSend = balance + 1;

        vm.startPrank(bob);
        vm.expectRevert();
        customToken.transfer(alice, amountToSend);
        vm.stopPrank();
    }

    modifier transferredStartingBalanceToBob() {
        vm.startPrank(msg.sender);
        customToken.transfer(bob, STARTING_BALANCE);
        vm.stopPrank();
        _;
    }
}
