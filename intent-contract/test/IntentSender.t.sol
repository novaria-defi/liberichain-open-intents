// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {IntentSender} from "../src/IntentSender.sol";

contract IntentSenderTest is Test {
    IntentSender public intentSender;
    MockERC20 public mockToken;
    address public user = address(1);
    address public settlementContract = address(2);

    function setUp() public {
        mockToken = new MockERC20();
        intentSender = new IntentSender(settlementContract);

        mockToken.mint(user, 1000 * 10**18);
        vm.prank(user);
        mockToken.approve(address(intentSender), 1000 * 10**18);
    }

    function testSubmitIntent_LocksTokens() public {
        uint256 amount = 100 * 10**18;
        uint256 originChain = intentSender.ARBITRUM_SEPOLIA_CHAIN_ID();
        uint32 destinationChain = 1614990;
        uint256 deadline = block.timestamp + 1 days;
        uint256 minReceived = 50 * 10**18;

        vm.prank(user);
        bytes32 intentId = intentSender.submitIntent(
            address(mockToken),
            amount,
            originChain,
            destinationChain,
            deadline,
            minReceived
        );

        assertEq(mockToken.balanceOf(address(intentSender)), amount, "MockToken should be locked in contract");
        assertEq(intentSender.lockedTokens(intentId), amount, "Locked amount should match the submitted amount");
    }

    function testSubmitIntent_RevertsOnExpiredDeadline() public {
        uint256 amount = 100 * 10**18;
        uint256 originChain = intentSender.ARBITRUM_SEPOLIA_CHAIN_ID();
        uint32 destinationChain = 1614990;
        uint256 deadline = block.timestamp - 1;
        uint256 minReceived = 50 * 10**18;

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IntentSender.IntentExpired.selector));
        intentSender.submitIntent(
            address(mockToken),
            amount,
            originChain,
            destinationChain,
            deadline,
            minReceived
        );
    }

    function testSubmitIntent_RevertsOnZeroMinReceived() public {
        uint256 amount = 100 * 10**18;
        uint256 originChain = intentSender.ARBITRUM_SEPOLIA_CHAIN_ID();
        uint32 destinationChain = 1614990;
        uint256 deadline = block.timestamp + 1 days;

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IntentSender.InvalidMinReceived.selector));
        intentSender.submitIntent(
            address(mockToken),
            amount,
            originChain,
            destinationChain,
            deadline,
            0
        );
    }
}