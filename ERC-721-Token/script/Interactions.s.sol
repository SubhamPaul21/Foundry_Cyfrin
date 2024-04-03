// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BasicNFT} from "../src/BasicNFT.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintBasicNFT is Script {
    string public constant SNOWY =
        "ipfs://QmTnRQN7ciqP12FTW4ccKG4S51VZEoQ7gDiifCG1yKziwN";

    function run() external {
        // Get the most recent deployment
        address contractAddress = DevOpsTools.get_most_recent_deployment(
            "BasicNFT",
            block.chainid
        );
        // Mint NFT using Deployed Contract
        mintNFTWithRecentDeployedContract(contractAddress);
    }

    function mintNFTWithRecentDeployedContract(address contractAddress) public {
        vm.startBroadcast();
        BasicNFT(contractAddress).mintNft(
            0xdb144f2Ec10d3F13222DD405cFA37B661C0b6e27,
            SNOWY
        );
        vm.stopBroadcast();
    }
}
