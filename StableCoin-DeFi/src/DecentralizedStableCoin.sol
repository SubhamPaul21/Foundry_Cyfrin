// SPDX-License-Identifier: MIT

/** Version */
pragma solidity ^0.8.18;

/** Imports*/
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/** Errors */
error DecentralizedStableCoin__AmountMustBeMoreThanZero();
error DecentralizedStableCoin__BurnAmountExceedsBalance();
error DecentralizedStableCoin__NotZeroAddress();

/** Interfaces */

/** Libraries */

/** Contracts */

/**
 * @title DecentralizedStableCoin
 * @author Subham Paul
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic
 * Relative Stability: Pegged to USD
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the ERC20 implementation of our stablecoin system.
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    /** Variables */
    /** Events */
    /** Modifiers */

    /** Constructor */
    constructor(
        address _owner
    ) ERC20("DecentralizedStableCoin", "DSC") Ownable(_owner) {}

    /** Receive Function */
    /** Fallback Function */
    /** External Functions */
    function mint(
        address _account,
        uint256 _value
    ) external onlyOwner returns (bool) {
        if (_account == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if (_value <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }

        _mint(_account, _value);
        return true;
    }

    /** Public Functions */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }
    /** Internal Functions */
    /** Private Functions */
    /** View Functions */
    /** Pure Functions */
}
