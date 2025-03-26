// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IntentSettlement is Ownable {
    struct Intent {
        address user;
        address intentSender;
        address token;
        uint256 amount;
        uint256 sourceChainId;
        uint256 destinationChainId;
        uint256 deadline;
        uint256 minReceived;
        bytes32 intentId;
    }

    mapping(bytes32 => bool) public processedIntents;
    mapping(bytes32 => Intent) public intents;

    event IntentSubmitted(bytes32 indexed intentId, Intent intent);
    event IntentProcessed(bytes32 indexed intentId, address solver);
    event IntentCancelled(bytes32 indexed intentId);

    error InvalidAmount(uint256 amount);
    error InvalidDeadline(uint256 deadline);
    error IntentAlreadyProcessed(bytes32 intentId);
    error IntentExpired(bytes32 intentId);
    error InsufficientTokenReceived(address user, uint256 balance, uint256 minReceived);

    function submitSettlement(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _sourceChainId,
        uint256 _destinationChainId,
        uint256 _deadline,
        uint256 _minReceived
    ) external returns (bytes32 intentId) {
        if (_amount == 0) revert InvalidAmount(_amount);
        if (_deadline <= block.timestamp) revert InvalidDeadline(_deadline);

        intentId = keccak256(abi.encodePacked(
            _user, 
            _token, 
            _amount, 
            _sourceChainId, 
            _destinationChainId, 
            _deadline,
            block.timestamp
        ));

        Intent memory intent = Intent({
            user: _user,
            intentSender: msg.sender,
            token: _token,
            amount: _amount,
            sourceChainId: _sourceChainId,
            destinationChainId: _destinationChainId,
            deadline: _deadline,
            minReceived: _minReceived,
            intentId: intentId
        });

        intents[intentId] = intent;
        emit IntentSubmitted(intentId, intent);
    }

    function processIntent(bytes32 intentId) external {
        Intent storage intent = intents[intentId];

        if (processedIntents[intentId]) {
            revert IntentAlreadyProcessed(intentId);
        }

        if (block.timestamp > intent.deadline) {
            revert IntentExpired(intentId);
        }

        IERC20 token = IERC20(intent.token);
        if (token.balanceOf(intent.user) < intent.minReceived) {
            revert InsufficientTokenReceived(
                intent.user, 
                token.balanceOf(intent.user), 
                intent.minReceived
            );
        }

        processedIntents[intentId] = true;
        emit IntentProcessed(intentId, msg.sender);
    }

    function cancelIntent(bytes32 intentId) external {
        Intent storage intent = intents[intentId];
        require(msg.sender == intent.intentSender, "Only intent sender can cancel");

        if (processedIntents[intentId]) {
            revert IntentAlreadyProcessed(intentId);
        }

        processedIntents[intentId] = true;
        emit IntentCancelled(intentId);
    }

    function getIntentDetails(bytes32 intentId) external view returns (Intent memory) {
        return intents[intentId];
    }
}
