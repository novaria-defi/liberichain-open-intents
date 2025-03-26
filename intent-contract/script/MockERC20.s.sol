// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract MockERC20Script is Script {
    MockERC20 public mockERC20;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        mockERC20 = new MockERC20();
        console.log("MockERC20 crated at:", address(mockERC20));

        vm.stopBroadcast();
    }
}

// forge script MemeTokenScript --rpc-url https://arb-sepolia.g.alchemy.com/v2/czzNRTsjnAUcR9rlDQn3zCjhkd-IT8mo --broadcast --verify --etherscan-api-key EG19M428F61ZVNVJFFEQDNDRAKBGAF45RP