// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IntentSettlement} from "../src/IntentSettlement.sol";
import {MockMailbox} from "../src/mocks/MockMailbox.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract IntentSettlementTest is Test {
    IntentSettlement public intentSettlement;
    address public mailbox;
    address public solver;
    address public user;
    address public token;
    bytes32 public intentId;
    uint32 public arbitrumSepoliaChainId = 421614;
    uint32 public liberichainChainId = 1614990;
    
    uint256 public amount = 1000;
    uint256 public minReceived = 500;
    uint256 public expiredDeadline;
    
    // Deploy the contract before each test
    function setUp() public {
        mailbox = address(new MockMailbox());
        intentSettlement = new IntentSettlement(mailbox);
        solver = address(0xBEEF);
        user = address(0xDeadBeef);
        token = address(new MockERC20()); // Use your MockERC20 contract
        
        expiredDeadline = block.timestamp - 1; // Expired deadline (1 second ago)
        
        // Set up a mock token for the test
        MockERC20(token).mint(user, amount);
        
        IntentSettlement.Intent memory intent = IntentSettlement.Intent({
            user: user,
            token: token,
            amount: amount,
            sourceChainId: arbitrumSepoliaChainId,
            destinationChainId: liberichainChainId,
            deadline: block.timestamp + 1000,  // 1000 seconds from now
            minReceived: minReceived
        });
        
        intentId = keccak256(abi.encodePacked(user, token, amount, block.timestamp, intent.sourceChainId, intent.destinationChainId));
        
        // Simulate the handle function with the intent
        vm.prank(mailbox);  // Simulate that mailbox is calling handle
        intentSettlement.handle(arbitrumSepoliaChainId, intentId, abi.encode(intent, intentId));
    }

    // Test if intent is settled (fulfilled)
    function testIntentSettlementStatus() public {
        // Ensure the intent is initially not settled
        assertFalse(intentSettlement.fulfilledIntents(intentId), "Intent should not be settled initially");
        
        // Fulfill the intent
        vm.prank(mailbox); // Simulate that mailbox is fulfilling the intent
        intentSettlement.fulfillIntent(intentId, solver);
        
        // Verify that the intent is now fulfilled (settled)
        assertTrue(intentSettlement.fulfilledIntents(intentId), "Intent should be settled after fulfillIntent call");
    }
}