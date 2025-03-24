// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IntentSettlement is IMessageRecipient {
    address public mailbox;
    mapping(bytes32 => Intent) public intents;
    mapping(bytes32 => bool) public fulfilledIntents;
    
    error InvalidOriginChain(uint32 origin);
    error IntentAlreadyFulfilled(bytes32 intentId);
    error IntentExpired(bytes32 intentId);
    error InsufficientTokenReceived(address user, uint256 balance, uint256 minReceived);
    error OnlyMailboxCanCall(address caller);

    event IntentFulfilled(bytes32 intentId, address solver);

    struct Intent {
        address user;
        address token;
        uint256 amount;
        uint256 sourceChainId;
        uint256 destinationChainId;
        uint256 deadline;
        uint256 minReceived;
    }

    constructor(address _mailbox) {
        mailbox = _mailbox; // Simpan address mailbox
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable {
        if (msg.sender != mailbox) {
            revert OnlyMailboxCanCall(msg.sender);
        }
        
        // Verifikasi asal jaringan (Arbitrum Sepolia atau LiberiChain)
        if (_origin != 1614990) {
            revert InvalidOriginChain(_origin); // ID chain LiberiChain
        }

        // Mendekode intent dan ID intent
        (Intent memory intent, bytes32 intentId) = abi.decode(_message, (Intent, bytes32));

        // Pastikan intent belum dipenuhi
        if (fulfilledIntents[intentId]) {
            revert IntentAlreadyFulfilled(intentId);
        }

        // Menyimpan intent untuk pemrosesan lebih lanjut
        intents[intentId] = intent;
    }

    function fulfillIntent(bytes32 intentId, address solver) external {
        Intent memory intent = intents[intentId];

        // Cek apakah intent sudah kadaluarsa
        if (intent.deadline <= block.timestamp) {
            revert IntentExpired(intentId);
        }

        // Pastikan intent belum dipenuhi
        if (fulfilledIntents[intentId]) {
            revert IntentAlreadyFulfilled(intentId);
        }

        IERC20 token = IERC20(intent.token);

        // Cek apakah penerima memiliki token yang cukup
        if (token.balanceOf(intent.user) < intent.minReceived) {
            revert InsufficientTokenReceived(intent.user, token.balanceOf(intent.user), intent.minReceived);
        }

        fulfilledIntents[intentId] = true;

        emit IntentFulfilled(intentId, solver);
    }
}
