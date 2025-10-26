// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Decentralized Lottery Contract
 * @author TacitusXI
 * @notice This contract implements a provably fair lottery system using Chainlink services
 * @dev Implements Chainlink VRF V2.5 for verifiable randomness and Chainlink Automation for automated draws
 * 
 * Key Features:
 * - Players enter by paying entrance fee
 * - Automated winner selection after time interval
 * - Verifiable random winner using Chainlink VRF
 * - Winner receives entire prize pool
 * - Gas optimized with custom errors
 */
contract Lottery is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Errors */
    /// @notice Thrown when upkeep is not needed
    /// @param currentBalance The current balance of the lottery
    /// @param numPlayers The current number of players
    /// @param lotteryState The current state of the lottery (0=OPEN, 1=CALCULATING)
    error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 lotteryState);
    
    /// @notice Thrown when prize transfer to winner fails
    error Lottery__TransferFailed();
    
    /// @notice Thrown when player doesn't send enough ETH to enter
    error Lottery__SendMoreToEnterLottery();
    
    /// @notice Thrown when trying to enter lottery while it's calculating winner
    error Lottery__LotteryNotOpen();

    /* Type declarations */
    /// @notice Represents the current state of the lottery
    /// @dev OPEN = accepting entries, CALCULATING = drawing winner
    enum LotteryState {
        OPEN,           // Lottery is accepting entries
        CALCULATING     // Lottery is calculating winner (awaiting VRF response)
    }

    /* State variables */
    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    LotteryState private s_lotteryState;

    /* Events */
    /// @notice Emitted when a VRF request for random winner is made
    /// @param requestId The ID of the VRF request
    event RequestedLotteryWinner(uint256 indexed requestId);
    
    /// @notice Emitted when a player enters the lottery
    /// @param player The address of the player who entered
    event LotteryEnter(address indexed player);
    
    /// @notice Emitted when a winner is picked and paid
    /// @param player The address of the winner
    event WinnerPicked(address indexed player);

    /* Functions */
    /**
     * @notice Initializes the lottery contract with Chainlink configuration
     * @param subscriptionId The Chainlink VRF subscription ID
     * @param gasLane The gas lane (key hash) for VRF request
     * @param interval The time interval between lottery draws in seconds
     * @param entranceFee The fee required to enter the lottery in wei
     * @param callbackGasLimit The gas limit for VRF callback function
     * @param vrfCoordinatorV2 The address of the Chainlink VRF Coordinator
     * @dev Sets lottery state to OPEN and records deployment timestamp
     */
    constructor(
        uint256 subscriptionId,
        bytes32 gasLane,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    /**
     * @notice Allows a player to enter the lottery by paying the entrance fee
     * @dev Adds the sender's address to the players array
     * @custom:requirements
     * - msg.value must be >= entrance fee
     * - Lottery must be in OPEN state
     * @custom:emits LotteryEnter when player successfully enters
     * @custom:reverts Lottery__SendMoreToEnterLottery if insufficient funds sent
     * @custom:reverts Lottery__LotteryNotOpen if lottery is calculating winner
     */
    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__SendMoreToEnterLottery();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__LotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    /**
     * @notice Checks if the contract needs upkeep (lottery draw)
     * @dev Called by Chainlink Automation nodes to determine if performUpkeep should be called
     * 
     * Upkeep is needed when ALL of the following are true:
     * 1. Time interval has passed since last draw
     * 2. Lottery is in OPEN state
     * 3. Contract has at least one player
     * 4. Contract has ETH balance (implicit: subscription funded with LINK)
     * 
     * @return upkeepNeeded Boolean indicating if upkeep is needed
     * @return performData Bytes data to pass to performUpkeep (empty in this implementation)
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Performs the upkeep (triggers lottery draw) when conditions are met
     * @dev Called by Chainlink Automation when checkUpkeep returns true
     * 
     * Process:
     * 1. Validates upkeep is needed
     * 2. Sets lottery state to CALCULATING
     * 3. Requests random words from Chainlink VRF
     * 4. Emits event with request ID
     * 
     * @custom:emits RequestedLotteryWinner with the VRF request ID
     * @custom:reverts Lottery__UpkeepNotNeeded if conditions not met
     * @custom:note Will revert if VRF subscription is not funded with LINK
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_lotteryState));
        }

        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedLotteryWinner(requestId);
    }

    /**
     * @notice Callback function called by Chainlink VRF with random words
     * @dev This function is called by the VRF Coordinator after random words are generated
     * 
     * Process:
     * 1. Uses modulo to pick winner index from players array
     * 2. Stores winner address
     * 3. Resets players array
     * 4. Sets state back to OPEN
     * 5. Updates timestamp
     * 6. Transfers entire balance to winner
     * 
     * @param randomWords Array of random values from Chainlink VRF (we use first value)
     * @custom:emits WinnerPicked with winner's address
     * @custom:reverts Lottery__TransferFailed if ETH transfer to winner fails
     * @custom:security Uses call instead of transfer to prevent reverting on gas changes
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        // Pick winner using modulo: randomWord % playersLength gives index 0 to playersLength-1
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    
    /**
     * @notice Returns the current state of the lottery
     * @return The current LotteryState (OPEN = 0, CALCULATING = 1)
     */
    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    /**
     * @notice Returns the number of random words requested from VRF
     * @return The number of random words (always 1 in this implementation)
     */
    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    /**
     * @notice Returns the number of block confirmations for VRF requests
     * @return The number of confirmations required (always 3 in this implementation)
     */
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    /**
     * @notice Returns the address of the most recent lottery winner
     * @return The address of the last winner (address(0) if no winner yet)
     */
    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    /**
     * @notice Returns the player address at a specific index
     * @param index The index in the players array
     * @return The address of the player at the specified index
     * @dev Will revert if index is out of bounds
     */
    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    /**
     * @notice Returns the timestamp of the last lottery draw
     * @return The block timestamp when the last winner was picked
     */
    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    /**
     * @notice Returns the time interval between lottery draws
     * @return The interval in seconds between lottery drawings
     */
    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    /**
     * @notice Returns the entrance fee required to enter the lottery
     * @return The entrance fee in wei
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    /**
     * @notice Returns the current number of players in the lottery
     * @return The total number of players who have entered
     */
    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}

