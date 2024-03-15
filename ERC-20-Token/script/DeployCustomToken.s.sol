// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CustomToken} from "../src/CustomToken.sol";

contract DeployCustomToken is Script {
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    function run() external returns (CustomToken) {
        vm.startBroadcast();
        CustomToken ct = new CustomToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return ct;
    }
}
