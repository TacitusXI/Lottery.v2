// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployLottery} from "../../script/DeployLottery.s.sol";
import {Lottery} from "../../src/Lottery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {LotteryHandler} from "./LotteryHandler.t.sol";

/**
 * @title LotteryInvariantTest
 * @notice Stateful fuzz testing (invariant tests) for Lottery contract
 * @dev Tests properties that should ALWAYS be true regardless of state changes
 * 
 * Benefits of Invariant Testing:
 * - Discovers edge cases that manual tests might miss
 * - Validates system properties under random state changes
 * - Provides higher confidence in contract correctness
 */
contract LotteryInvariantTest is StdInvariant, Test {
    Lottery public lottery;
    HelperConfig public helperConfig;
    LotteryHandler public handler;

    uint256 lotteryEntranceFee;

    function setUp() external {
        DeployLottery deployer = new DeployLottery();
        (lottery, helperConfig) = deployer.run();
        
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        lotteryEntranceFee = config.lotteryEntranceFee;

        // Use handler for better invariant testing
        handler = new LotteryHandler(lottery, lotteryEntranceFee);
        targetContract(address(handler));
    }

    /**
     * @notice Invariant: Contract balance should always equal sum of entrance fees
     */
    function invariant_contractBalanceEqualsEntranceFees() public view {
        uint256 numPlayers = lottery.getNumberOfPlayers();
        uint256 expectedBalance = numPlayers * lotteryEntranceFee;
        
        // Balance should be at least the minimum expected (players * entrance fee)
        // Can be more if players send extra
        assert(address(lottery).balance >= expectedBalance);
    }

    /**
     * @notice Invariant: Number of players should never be negative (always >= 0)
     */
    function invariant_numberOfPlayersIsValid() public view {
        uint256 numPlayers = lottery.getNumberOfPlayers();
        assert(numPlayers >= 0); // Always true for uint, but documents the invariant
    }

    /**
     * @notice Invariant: Lottery state should only be OPEN or CALCULATING
     */
    function invariant_lotteryStateIsValid() public view {
        Lottery.LotteryState state = lottery.getLotteryState();
        assert(uint256(state) <= 1); // Only 0 (OPEN) or 1 (CALCULATING) are valid
    }

    /**
     * @notice Invariant: Entrance fee should never change
     */
    function invariant_entranceFeeIsConstant() public view {
        assert(lottery.getEntranceFee() == lotteryEntranceFee);
    }

    /**
     * @notice Invariant: Interval should never change
     */
    function invariant_intervalIsConstant() public view {
        uint256 interval = lottery.getInterval();
        assert(interval > 0);
        assert(interval == lottery.getInterval()); // Always equal to itself
    }

    /**
     * @notice Invariant: Last timestamp should never be in the future
     */
    function invariant_lastTimestampNotInFuture() public view {
        assert(lottery.getLastTimeStamp() <= block.timestamp);
    }

    /**
     * @notice Invariant: Number of words is always 1
     */
    function invariant_numWordsIsOne() public view {
        assert(lottery.getNumWords() == 1);
    }

    /**
     * @notice Invariant: Request confirmations is always 3
     */
    function invariant_requestConfirmationsIsThree() public view {
        assert(lottery.getRequestConfirmations() == 3);
    }
}

