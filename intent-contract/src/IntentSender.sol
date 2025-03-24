// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

contract IntentSender {
    IMailbox public mailbox;
    address public settlementContract;
    
    // Hardcoded chain IDs
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant LIBERICHAIN_CHAIN_ID = 1614990;

    event IntentSubmitted(bytes32 indexed intentId, Intent intent);

    struct Intent {
        address user;
        address token;
        uint256 amount;
        uint32 sourceChainId;     // Arbitrum Sepolia
        uint32 destinationChainId; // Liberichain
        uint256 deadline;
        uint256 minReceived;
    }

    // Custom errors
    error IntentExpired();
    error InvalidSourceChain();
    error InvalidMinReceived();

    constructor(address _mailbox, address _settlementContract) {
        mailbox = IMailbox(_mailbox);
        settlementContract = _settlementContract;
    }

    function submitIntent(Intent calldata intent) external {
        // Validate intent expiration
        if (intent.deadline <= block.timestamp) {
            revert IntentExpired();
        }
        
        if (intent.sourceChainId != ARBITRUM_SEPOLIA_CHAIN_ID) {
            revert InvalidSourceChain();
        }

        if (intent.minReceived == 0) {
            revert InvalidMinReceived();
        }

        // Generate intentId using keccak256, based on intent data (not block.timestamp)
        bytes32 intentId = keccak256(abi.encode(intent.user, intent.token, intent.amount, intent.sourceChainId, intent.destinationChainId, intent.deadline, intent.minReceived));

        // Emit event to signal the intent submission
        emit IntentSubmitted(intentId, intent);

        // Prepare message to send
        bytes memory message = abi.encode(
            intent.user,
            intent.token,
            intent.amount,
            intent.sourceChainId,
            intent.destinationChainId,
            intent.deadline,
            intent.minReceived,
            intentId
        );

        // Dispatch the message to the mailbox (hardcoded to LIBERICHAIN_CHAIN_ID)
        mailbox.dispatch{value: 0}(uint32(LIBERICHAIN_CHAIN_ID), addressToBytes32(settlementContract), message);
    }

    // Utility function to convert address to bytes32
    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
