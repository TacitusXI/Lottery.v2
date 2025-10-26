// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Lottery} from "../src/Lottery.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

/**
 * @title DeployLottery
 * @notice Deployment script for the Lottery contract
 * @dev Automates the complete deployment process including:
 * - Network configuration
 * - VRF subscription creation and funding
 * - Contract deployment
 * - Consumer registration
 */
contract DeployLottery is Script {
    /**
     * @notice Main deployment function that handles the entire lottery setup
     * @dev Deployment process:
     * 1. Load network-specific configuration
     * 2. Create VRF subscription if not exists
     * 3. Fund subscription with LINK
     * 4. Deploy Lottery contract
     * 5. Register contract as VRF consumer
     * 
     * @return lottery The deployed Lottery contract instance
     * @return helperConfig The HelperConfig instance used for deployment
     * 
     * @custom:network-support Supports Anvil (local), Sepolia, Polygon Amoy, and Ethereum Mainnet
     * @custom:automation Automatically handles subscription creation and funding
     */
    function run() external returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Create and fund VRF subscription if it doesn't exist
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) =
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );

            helperConfig.setConfig(block.chainid, config);
        }

        // Deploy Lottery contract
        vm.startBroadcast(config.account);
        Lottery lottery = new Lottery(
            config.subscriptionId,
            config.gasLane,
            config.automationUpdateInterval,
            config.lotteryEntranceFee,
            config.callbackGasLimit,
            config.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();

        // Register Lottery as VRF consumer
        addConsumer.addConsumer(address(lottery), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);
        return (lottery, helperConfig);
    }
}

