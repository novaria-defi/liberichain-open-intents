// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IntentSender} from "../src/IntentSender.sol";

contract IntentSenderScript is Script {
    IntentSender public intentSender;
    address mailboxAddress = 0xA88206Cf611f4c48EaE7234Fa2A5f7476F320b32;
    address intentSettlement = 0xb992451a28ef4b9C920a98c7f10aAF0f799B79f2;

    function setUp() public {}

    function run() public {
        // Mulai siaran transaksi
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        intentSender = new IntentSender(mailboxAddress, intentSettlement);

        console.log("IntentSender deployed to:", address(intentSender));

        vm.stopBroadcast();
    }
}
