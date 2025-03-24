// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

    address public owner;
    uint256 public constant MAX_TOTAL_SUPPLY = 10_000;

    constructor() ERC20("MockERC20", "MC20") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

}