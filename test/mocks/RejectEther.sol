// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RejectEther
 * @notice Mock contract that rejects all ETH transfers
 * @dev Used for testing transfer failure scenarios
 */
contract RejectEther {
    // Reject all ETH transfers by reverting in receive
    receive() external payable {
        revert("RejectEther: I don't want your money!");
    }
}

