// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    address public owner;
    uint256 public constant MAX_TOTAL_SUPPLY = 10_000_000_000 * 10**18; // Perbaikan di sini

    constructor() ERC20("Meme Token", "MT") {
        owner = msg.sender;
        _mint(owner, MAX_TOTAL_SUPPLY);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
