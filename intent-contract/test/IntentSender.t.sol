// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/IntentSender.sol";

contract MockMailbox {
    event Dispatch(
        address indexed sender,
        uint32 indexed destination,
        bytes32 indexed recipient,
        bytes message
    );

    function dispatch(uint32 _destination, bytes32 _recipient, bytes calldata _message) 
        external 
        payable 
        returns (bytes32) 
    {
        require(_destination != 0, "Invalid destination");
        require(_recipient != bytes32(0), "Invalid recipient");
        require(_message.length > 0, "Invalid message");

        emit Dispatch(msg.sender, _destination, _recipient, _message);
        return keccak256(abi.encode(msg.sender, _destination, _recipient, _message)); // Return dummy message ID
    }
}

contract IntentSenderTest is Test {
    IntentSender intentSender;
    MockMailbox mockMailbox;

    address user = address(0x123);
    address settlementContract = address(0x456);
    uint256 liberichainChainId = 9999;
    uint256 sourceChainId = block.chainid;

    function setUp() public {
        mockMailbox = new MockMailbox();
        intentSender = new IntentSender(address(mockMailbox), settlementContract, liberichainChainId);
    }

    function testSubmitIntentSuccess() public {
        uint256 fixedTimestamp = 1000000;
        vm.warp(fixedTimestamp);
    
        IntentSender.Intent memory intent = IntentSender.Intent({
            user: user,
            token: address(0xABC),
            amount: 1000,
            sourceChainId: sourceChainId,
            destinationChainId: liberichainChainId,
            deadline: fixedTimestamp + 1 days,
            minReceived: 900
        });
    
        bytes32 expectedIntentId = keccak256(abi.encode(intent, fixedTimestamp));
    
        vm.expectEmit(true, true, true, true);
        emit IntentSender.IntentSubmitted(expectedIntentId, intent);
    
        // Gunakan alamat IntentSender sebagai sender
        address intentSenderAddress = address(intentSender);
        vm.expectEmit(true, true, true, true);
        emit MockMailbox.Dispatch(
            intentSenderAddress, // Sesuaikan dengan alamat kontrak IntentSender
            uint32(liberichainChainId),
            intentSender.addressToBytes32(settlementContract),
            abi.encode(
                intent.user,
                intent.token,
                intent.amount,
                intent.sourceChainId,
                intent.destinationChainId,
                intent.deadline,
                intent.minReceived,
                expectedIntentId
            )
        );
    
        vm.prank(user);
        intentSender.submitIntent(intent);
    }

    function testSubmitIntentRevertsIfExpired() public {
        uint256 fixedTimestamp = 1000000;
        vm.warp(fixedTimestamp); // Sinkronkan timestamp untuk kontrak

        IntentSender.Intent memory intent = IntentSender.Intent({
            user: user,
            token: address(0xABC),
            amount: 1000,
            sourceChainId: sourceChainId,
            destinationChainId: liberichainChainId,
            deadline: fixedTimestamp - 1, // Intent sudah kedaluwarsa
            minReceived: 900
        });

        vm.prank(user);
        vm.expectRevert(IntentSender.IntentExpired.selector);
        intentSender.submitIntent(intent);
    }

    function testSubmitIntentRevertsIfInvalidSourceChain() public {
        uint256 fixedTimestamp = 1000000;
        vm.warp(fixedTimestamp); // Sinkronkan timestamp untuk kontrak

        IntentSender.Intent memory intent = IntentSender.Intent({
            user: user,
            token: address(0xABC),
            amount: 1000,
            sourceChainId: 12345, // Salah chain ID
            destinationChainId: liberichainChainId,
            deadline: fixedTimestamp + 1 days,
            minReceived: 900
        });

        vm.prank(user);
        vm.expectRevert(IntentSender.InvalidSourceChain.selector);
        intentSender.submitIntent(intent);
    }
}