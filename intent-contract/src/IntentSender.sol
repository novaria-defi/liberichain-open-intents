// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

contract IntentSender {
    IMailbox public mailbox;
    address public settlementContract;
    uint256 public liberichainChainId;

    event IntentSubmitted(bytes32 intentId, Intent intent);

    struct Intent {
        address user;
        address token;
        uint256 amount;
        uint256 sourceChainId;     // Arbitrum Sepolia
        uint256 destinationChainId;// Liberichain
        uint256 deadline;
        uint256 minReceived;
    }

    // Custom errors
    error IntentExpired();
    error InvalidSourceChain();

    constructor(address _mailbox, address _settlementContract, uint256 _liberichainChainId) {
        mailbox = IMailbox(_mailbox);
        settlementContract = _settlementContract;
        liberichainChainId = _liberichainChainId;
    }

    function submitIntent(Intent calldata intent) external {
        if (intent.deadline <= block.timestamp) {
            revert IntentExpired();
        }
        
        if (intent.sourceChainId != block.chainid) {
            revert InvalidSourceChain();
        }

        // Gunakan block.timestamp dalam perhitungan intentId
        bytes32 intentId = keccak256(abi.encode(intent, block.timestamp));
        
        // Emit event terlebih dahulu sebelum memanggil external function
        emit IntentSubmitted(intentId, intent);
        
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

        // Panggil mailbox.dispatch setelah event diemit
        mailbox.dispatch{value: 0}(uint32(liberichainChainId), addressToBytes32(settlementContract), message);
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}