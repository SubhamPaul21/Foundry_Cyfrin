// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Custom Token", "CT") {
        _mint(msg.sender, initialSupply);
    }
}
