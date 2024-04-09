// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {Test} from "forge-std/Test.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin dsc;

    address owner = makeAddr("Owner");

    function setUp() public {
        // owner = msg.sender;
        dsc = new DecentralizedStableCoin(owner);
    }

    function test_InitialSupplyIsZero() public view {
        uint256 expectedSupply = 0;
        assertEq(
            dsc.totalSupply(),
            expectedSupply,
            "Initial supply should be zero"
        );
    }

    function test_MintFunction() public {
        vm.prank(owner);
        address account = address(owner);
        uint256 amount = 100;

        bool result = dsc.mint(account, amount);

        assertTrue(result, "Minting should be successful");
        assertEq(
            dsc.balanceOf(account),
            amount,
            "Account balance should be equal to minted amount"
        );
    }

    function test_MintRequiresNonZeroAddress() public {
        address account = address(0);
        uint256 amount = 100;

        (bool success, ) = address(dsc).call(
            abi.encodeWithSignature("mint(address,uint256)", account, amount)
        );

        assertFalse(success, "Minting should fail with zero address");
    }

    function test_MintRequiresPositiveAmount() public {
        address account = address(0x1);
        uint256 amount = 0;

        (bool success, ) = address(dsc).call(
            abi.encodeWithSignature("mint(address,uint256)", account, amount)
        );

        assertFalse(success, "Minting should fail with zero amount");
    }

    function test_BurnFunction() public {
        vm.startPrank(owner);
        uint256 initialSupply = 1000;
        uint256 burnAmount = 100;
        dsc.mint(owner, initialSupply);

        dsc.burn(burnAmount);

        vm.stopPrank();
        assertEq(
            dsc.balanceOf(owner),
            initialSupply - burnAmount,
            "Owner balance should decrease after burning"
        );
        assertEq(
            dsc.totalSupply(),
            initialSupply - burnAmount,
            "Total supply should decrease after burning"
        );
    }

    function test_BurnRequiresPositiveAmount() public {
        uint256 burnAmount = 0;

        (bool success, ) = address(dsc).call(
            abi.encodeWithSignature("burn(uint256)", burnAmount)
        );

        assertFalse(success, "Burning should fail with zero amount");
    }

    function test_BurnRequiresSufficientBalance() public {
        vm.startPrank(owner);
        uint256 initialSupply = 100;
        uint256 burnAmount = 200;
        dsc.mint(owner, initialSupply);
        vm.stopPrank();

        (bool success, ) = address(dsc).call(
            abi.encodeWithSignature("burn(uint256)", burnAmount)
        );

        assertFalse(success, "Burning should fail if amount exceeds balance");
    }
}
