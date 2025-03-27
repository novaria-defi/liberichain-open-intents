// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IntentSettlement} from "../src/IntentSettlement.sol";

contract IntentSettlementScript is Script {
    IntentSettlement public intentSettlement;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        intentSettlement = new IntentSettlement();

        console.log("IntentSettlement deployed to:", address(intentSettlement));

        vm.stopBroadcast();
    }
}
