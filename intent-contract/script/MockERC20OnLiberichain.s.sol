// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20OnLiberichain} from "../src/mocks/MockERC20OnLiberichain.sol";

contract MockERC20OnLiberichainScript is Script {
    MockERC20OnLiberichain public mockERC20OnLiberichain;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        mockERC20OnLiberichain = new MockERC20OnLiberichain();
        console.log("MockERC20 crated at:", address(mockERC20OnLiberichain));

        vm.stopBroadcast();
    }
}

// forge script MockERC20OnLiberichainScript --rpc-url http://127.0.0.1:8547