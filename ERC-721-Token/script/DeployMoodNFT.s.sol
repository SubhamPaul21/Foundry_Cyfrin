// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {MoodNFT} from "../src/MoodNFT.sol";

contract DeployMoodNFT is Script {
    MoodNFT s_moodNFT;

    function run() external returns (MoodNFT) {
        string memory happySvg = vm.readFile("./img/happy.svg");
        string memory sadSvg = vm.readFile("./img/sad.svg");

        vm.startBroadcast();
        s_moodNFT = new MoodNFT(
            msg.sender,
            svgToImageURI(happySvg),
            svgToImageURI(savSvg)
        );
        vm.stopBroadcast();
        return s_moodNFT;
    }

    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = string(
            Base64.encode(abi.encodePacked(svg))
        );

        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
}
