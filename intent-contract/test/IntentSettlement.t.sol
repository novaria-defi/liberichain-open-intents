// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/IntentSettlement.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract IntentSettlementTest is Test {
    IntentSettlement public intentSettlement;
    MockERC20 public mockToken;
    
    address public mailbox = address(0x123);
    address public user = address(0x456);
    address public solver = address(0x789);

    uint256 public amount = 1000;
    uint256 public deadline = block.timestamp + 1 days;
    uint256 public minReceived = 500;
    uint256 public sourceChainId = 1;
    uint256 public destinationChainId = 2;
    bytes32 public intentId = keccak256("testIntent");

    function setUp() public {
        intentSettlement = new IntentSettlement(mailbox);
        mockToken = new MockERC20();
    }

    function testHandleRevertsIfNotMailbox() public {
        bytes memory message = abi.encode(
            IntentSettlement.Intent(user, address(mockToken), amount, sourceChainId, destinationChainId, deadline, minReceived),
            intentId
        );
    
        vm.prank(address(0x111)); // Bukan mailbox
        vm.expectRevert(abi.encodeWithSelector(IntentSettlement.OnlyMailboxCanCall.selector, address(0x111)));
        intentSettlement.handle(1614990, bytes32(0), message);
    }
    

    function testHandleRevertsIfIntentAlreadyFulfilled() public {
        bytes32 intentId = keccak256("fulfilledIntent");
    
        IntentSettlement.Intent memory intent = IntentSettlement.Intent(
            user, address(mockToken), amount, sourceChainId, destinationChainId, block.timestamp + 1 days, minReceived
        );
    
        bytes memory message = abi.encode(intent, intentId);
    
        vm.prank(mailbox);
        intentSettlement.handle(1614990, bytes32(0), message);
    
        // Pastikan user punya cukup token untuk fulfill intent
        mockToken.mint(user, amount);
        vm.prank(user);
        mockToken.approve(address(intentSettlement), amount);
    
        // Fulfill intent pertama kali
        intentSettlement.fulfillIntent(intentId, solver);
    
        // Coba handle intent yang sudah terpenuhi
        vm.prank(mailbox);
        vm.expectRevert(abi.encodeWithSelector(IntentSettlement.IntentAlreadyFulfilled.selector, intentId));
        intentSettlement.handle(1614990, bytes32(0), message);
    }    
    

    function testFulfillIntentRevertsIfExpired() public {
        bytes32 intentId = keccak256("expiredIntent");
    
        IntentSettlement.Intent memory expiredIntent = IntentSettlement.Intent(
            user, address(mockToken), amount, sourceChainId, destinationChainId, block.timestamp, minReceived
        );
    
        bytes memory message = abi.encode(expiredIntent, intentId);
        
        vm.prank(mailbox);
        intentSettlement.handle(1614990, bytes32(0), message);
    
        // Warp waktu agar intent benar-benar expired
        vm.warp(block.timestamp + 2 days);
    
        // Tangkap error dengan selector yang benar
        vm.expectRevert(abi.encodeWithSelector(IntentSettlement.IntentExpired.selector, intentId));
        intentSettlement.fulfillIntent(intentId, solver);
    }
    
    

    function testFulfillIntentRevertsIfInsufficientTokenReceived() public {
        bytes memory message = abi.encode(
            IntentSettlement.Intent(user, address(mockToken), amount, sourceChainId, destinationChainId, deadline, minReceived),
            intentId
        );
    
        vm.prank(mailbox);
        intentSettlement.handle(1614990, bytes32(0), message);
    
        // Tidak memberikan cukup token
        mockToken.mint(user, 100);
        vm.prank(user);
        mockToken.approve(address(intentSettlement), 100);
    
        vm.expectRevert(
            abi.encodeWithSelector(IntentSettlement.InsufficientTokenReceived.selector, user, 100, minReceived)
        );
        intentSettlement.fulfillIntent(intentId, solver);
    }
    

    function testFulfillIntentSuccess() public {
        bytes32 validIntentId = keccak256("validIntent");

        IntentSettlement.Intent memory validIntent = IntentSettlement.Intent(
            user, address(mockToken), amount, sourceChainId, destinationChainId, deadline, minReceived
        );

        bytes memory message = abi.encode(validIntent, validIntentId);

        vm.prank(mailbox);
        intentSettlement.handle(1614990, bytes32(0), message);

        // Mint token ke user dan approve
        mockToken.mint(user, 1000);
        vm.prank(user);
        mockToken.approve(address(intentSettlement), 1000);

        vm.expectEmit(true, true, true, true);
        emit IntentSettlement.IntentFulfilled(validIntentId, solver);
        intentSettlement.fulfillIntent(validIntentId, solver);
    }
}
