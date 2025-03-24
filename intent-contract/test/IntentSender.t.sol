// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console, Test} from "forge-std/Test.sol";
import {IntentSender} from "../src/IntentSender.sol";
import {MockMailbox} from "../src/mocks/MockMailbox.sol";

contract IntentSenderTest is Test {
    IntentSender public intentSender;
    MockMailbox public mockMailbox;
    uint32 public liberichainChainId = 1614990;
    uint32 public arbitrumSepoliaChainId = 421614;
    
    // Test data
    address public settlementContract = address(0x789);
    address public user = address(0x123);
    address public token = address(0x456);
    uint256 public amount = 1000;
    uint256 public minReceived = 500;
    uint256 public deadline = block.timestamp + 1 days; // Set to 1 day in the future

    function setUp() public {
        // Deploy MockMailbox and IntentSender contracts
        mockMailbox = new MockMailbox();
        settlementContract = address(0x789); // Settlement contract address

        intentSender = new IntentSender(address(mockMailbox), settlementContract);
    }

    function testSubmitIntentSuccess() public {
        IntentSender.Intent memory validIntent = IntentSender.Intent({
            user: user,
            token: token,
            amount: amount,
            sourceChainId: arbitrumSepoliaChainId,
            destinationChainId: liberichainChainId,
            deadline: deadline,
            minReceived: minReceived
        });

        // Call submitIntent with valid data
        vm.expectEmit(true, true, true, true);
        emit IntentSender.IntentSubmitted(
            keccak256(abi.encode(validIntent.user, validIntent.token, validIntent.amount, validIntent.sourceChainId, validIntent.destinationChainId, validIntent.deadline, validIntent.minReceived)),
            validIntent
        );

        intentSender.submitIntent(validIntent);
    }

    function testSubmitIntentRevertsIfExpired() public {
        uint256 fixedTimestamp = 1000000;
        vm.warp(fixedTimestamp); // Sinkronkan timestamp untuk kontrak

        IntentSender.Intent memory intent = IntentSender.Intent({
            user: user,
            token: address(0xABC),
            amount: 1000,
            sourceChainId: arbitrumSepoliaChainId,
            destinationChainId: liberichainChainId,
            deadline: fixedTimestamp - 1, // Intent sudah kedaluwarsa
            minReceived: 900
        });

        vm.prank(user);
        vm.expectRevert(IntentSender.IntentExpired.selector);
        intentSender.submitIntent(intent);
    }
    function testSubmitIntentRevertsIfInvalidSourceChain() public {
        uint32 invalidSourceChainId = 123456; // Invalid source chain ID
        IntentSender.Intent memory invalidIntent = IntentSender.Intent({
            user: user,
            token: token,
            amount: amount,
            sourceChainId: invalidSourceChainId,
            destinationChainId: liberichainChainId,
            deadline: deadline,
            minReceived: minReceived
        });

        // Expect the InvalidSourceChain revert
        vm.expectRevert(IntentSender.InvalidSourceChain.selector);

        // Call submitIntent with invalid source chain ID
        intentSender.submitIntent(invalidIntent);
    }
}
