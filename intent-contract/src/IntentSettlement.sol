// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IntentSettlement is Ownable {
    // Struktur Intent yang diperluas
    struct Intent {
        address user;           // Pengguna yang membuat intent
        address intentSender;   // Alamat kontrak/wallet yang mengirim intent
        address token;          // Token yang di-transfer
        uint256 amount;         // Jumlah token
        uint256 sourceChainId;  // Chain asal
        uint256 destinationChainId; // Chain tujuan
        uint256 deadline;       // Batas waktu intent
        uint256 minReceived;    // Jumlah minimal yang harus diterima
        bytes32 intentId;       // ID unik intent
    }

    // Mapping untuk melacak intent yang sudah diproses
    mapping(bytes32 => bool) public processedIntents;
    mapping(bytes32 => Intent) public intents;

    // Event untuk melacak status intent
    event IntentSubmitted(bytes32 indexed intentId, Intent intent);
    event IntentProcessed(bytes32 indexed intentId, address solver);
    event IntentCancelled(bytes32 indexed intentId);

    // Custom Errors
    error InvalidAmount(uint256 amount);
    error InvalidDeadline(uint256 deadline);
    error IntentAlreadyProcessed(bytes32 intentId);
    error IntentExpired(bytes32 intentId);
    error InsufficientTokenReceived(address user, uint256 balance, uint256 minReceived);

    /**
     * @notice Submit intent untuk cross-chain transfer
     * @param _user Alamat pengguna akhir
     * @param _token Alamat token
     * @param _amount Jumlah token
     * @param _sourceChainId Chain asal
     * @param _destinationChainId Chain tujuan
     * @param _deadline Batas waktu intent
     * @param _minReceived Jumlah minimal token yang diterima
     * @return intentId ID unik untuk intent
     */
    function submitSettlement(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _sourceChainId,
        uint256 _destinationChainId,
        uint256 _deadline,
        uint256 _minReceived
    ) external returns (bytes32 intentId) {
        // Validasi input
        if (_amount == 0) revert InvalidAmount(_amount);
        if (_deadline <= block.timestamp) revert InvalidDeadline(_deadline);

        // Generate intentId
        intentId = keccak256(abi.encodePacked(
            _user, 
            _token, 
            _amount, 
            _sourceChainId, 
            _destinationChainId, 
            _deadline,
            block.timestamp
        ));

        // Buat intent
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

        // Simpan intent
        intents[intentId] = intent;

        // Emit event
        emit IntentSubmitted(intentId, intent);

        return intentId;
    }

    /**
     * @notice Proses intent setelah cross-chain transfer
     * @param intentId ID intent yang akan diproses
     */
    function processIntent(bytes32 intentId) external {
        // Ambil intent dari storage
        Intent storage intent = intents[intentId];

        // Validasi intent belum diproses
        if (processedIntents[intentId]) {
            revert IntentAlreadyProcessed(intentId);
        }

        // Validasi deadline
        if (block.timestamp > intent.deadline) {
            revert IntentExpired(intentId);
        }

        // Validasi token diterima minimal sesuai yang diharapkan
        IERC20 token = IERC20(intent.token);
        if (token.balanceOf(intent.user) < intent.minReceived) {
            revert InsufficientTokenReceived(
                intent.user, 
                token.balanceOf(intent.user), 
                intent.minReceived
            );
        }

        // Tandai intent sebagai diproses
        processedIntents[intentId] = true;

        // Emit event
        emit IntentProcessed(intentId, msg.sender);
    }

    /**
     * @notice Batalkan intent jika tidak dapat diproses
     * @param intentId ID intent yang akan dibatalkan
     */
    function cancelIntent(bytes32 intentId) external {
        // Ambil intent dari storage
        Intent storage intent = intents[intentId];

        // Validasi bahwa pemanggil adalah intent sender asli
        require(msg.sender == intent.intentSender, "Only intent sender can cancel");

        // Validasi intent belum diproses
        if (processedIntents[intentId]) {
            revert IntentAlreadyProcessed(intentId);
        }

        // Tandai intent sebagai diproses untuk mencegah pengulangan
        processedIntents[intentId] = true;

        // Emit event
        emit IntentCancelled(intentId);
    }

    /**
     * @notice Dapatkan detail intent
     * @param intentId ID intent yang dicari
     * @return Detail intent yang diminta
     */
    function getIntentDetails(bytes32 intentId) external view returns (Intent memory) {
        return intents[intentId];
    }
}