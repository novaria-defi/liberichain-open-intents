// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IntentSettlement} from "../src/IntentSettlement.sol";

contract IntentSettlementScript is Script {
    IntentSettlement public intentSettlement;

    function setUp() public {}

    function run() public {
        // Mulai siaran transaksi
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        intentSettlement = new IntentSettlement(0xA88206Cf611f4c48EaE7234Fa2A5f7476F320b32);

        console.log("IntentSettlement deployed to:", address(intentSettlement));

        vm.stopBroadcast();
    }
}
// forge script IntentSettlementScript --rpc-url http://127.0.0.1:8547 --broadcast