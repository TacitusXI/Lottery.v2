// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Lottery} from "../../src/Lottery.sol";

/**
 * @title LotteryHandler
 * @notice Handler for stateful fuzz testing with constrained random calls
 * @dev Ensures only valid calls are made during invariant testing
 */
contract LotteryHandler is Test {
    Lottery public lottery;
    uint256 public entranceFee;
    
    uint256 public ghost_totalEntered;
    uint256 public ghost_totalEntries;

    constructor(Lottery _lottery, uint256 _entranceFee) {
        lottery = _lottery;
        entranceFee = _entranceFee;
    }

    /**
     * @notice Handler function for entering lottery
     * @dev Only enters when lottery is OPEN
     */
    function enterLottery(uint256 amount) public {
        // Bound amount between entrance fee and 100 ETH
        amount = bound(amount, entranceFee, 100 ether);
        
        // Only enter if lottery is OPEN
        if (lottery.getLotteryState() != Lottery.LotteryState.OPEN) {
            return;
        }

        // Create random player address
        address player = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, ghost_totalEntries)))));
        vm.deal(player, amount);
        
        vm.prank(player);
        try lottery.enterLottery{value: amount}() {
            ghost_totalEntered += amount;
            ghost_totalEntries++;
        } catch {
            // If entry fails, that's ok (might be calculating)
        }
    }

    /**
     * @notice Handler function for checking upkeep
     */
    function checkUpkeep() public view {
        lottery.checkUpkeep("");
    }
}

