// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

// Menandai kontrak sebagai abstract karena tidak semua fungsi diimplementasikan
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