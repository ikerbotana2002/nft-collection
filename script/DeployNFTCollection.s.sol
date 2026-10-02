// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFTCollection} from "../src/NFTCollection.sol";

contract DeployNFTCollection is Script {
    function run() external returns (NFTCollection nft) {
        vm.startBroadcast();

        nft = new NFTCollection();

        vm.stopBroadcast();
    }
}