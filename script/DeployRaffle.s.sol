// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // Create subscription
            CreateSubscription createSubscriptionContract = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscriptionContract.createSubscription(config.vrfCoordinator);

            // Fund subscription
            FundSubscription fundSubscriptionContract = new FundSubscription();
            fundSubscriptionContract.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle({
            entranceFee: config.entranceFee,
            interval: config.interval,
            vrfCoordinator: config.vrfCoordinator,
            gasLane: config.gasLane,
            callbackGasLimit: config.callbackGasLimit,
            subscriptionId: config.subscriptionId
        });
        vm.stopBroadcast();

        AddConsumer addConsumerContract = new AddConsumer();
        addConsumerContract.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        return (raffle, helperConfig);
    }

    function run() external returns (Raffle, HelperConfig) {
        return deployContract();
    }
}
