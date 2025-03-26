// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IntentSender {
    address public settlementContract;
    
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 public constant LIBERICHAIN_CHAIN_ID = 1614990;

    mapping(bytes32 => uint256) public lockedTokens;

    event IntentSubmitted(
        bytes32 indexed intentId,
        address user,
        address token,
        uint256 amount,
        uint256 sourceChainId,
        uint32 destinationChainId,
        uint256 deadline,
        uint256 minReceived
    );

    error IntentExpired();
    error InvalidSourceChain();
    error InvalidMinReceived();
    error TransferFailed();

    constructor(address _settlementContract) {
        settlementContract = _settlementContract;
    }

    function submitIntent(
        address _token,
        uint256 _amount,
        uint256 _originChain,
        uint32 _destinationChainId,
        uint256 _deadline,
        uint256 _minReceived
    ) external returns (bytes32) {
        if (_deadline <= block.timestamp) revert IntentExpired();
        if (_minReceived == 0) revert InvalidMinReceived();
        
        // Transfer token dari user ke kontrak ini
        if (!IERC20(_token).transferFrom(msg.sender, address(this), _amount)) {
            revert TransferFailed();
        }

        // Buat intentId
        bytes32 intentId = keccak256(
            abi.encode(
                msg.sender,
                _token,
                _amount,
                _originChain,
                _destinationChainId,
                _deadline,
                _minReceived,
                block.timestamp
            )
        );

        // Simpan jumlah token yang terlock
        lockedTokens[intentId] = _amount;

        emit IntentSubmitted(
            intentId,
            msg.sender,
            _token,
            _amount,
            _originChain,
            _destinationChainId,
            _deadline,
            _minReceived
        );
        
        return intentId;
    }
}