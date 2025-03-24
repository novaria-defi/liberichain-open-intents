// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IntentSender} from "../src/IntentSender.sol";

contract IntentSenderScript is Script {
    IntentSender public intentSender;
    address mailboxAddress = 0x1Db8fD89970B6FcBbbC50658b8DA2C272DfDcB57;
    address intentSettlement = 0x54059294b42a9D438C84B8844916d403e982dcF6;
    uint256 chainId = 1614990;

    function setUp() public {}

    function run() public {
        // Mulai siaran transaksi
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        intentSender = new IntentSender(mailboxAddress, intentSettlement, chainId);

        console.log("IntentSender deployed to:", address(intentSender));

        vm.stopBroadcast();
    }
}
