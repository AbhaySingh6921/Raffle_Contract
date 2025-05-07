//SPDX -License-Identifier: MIT
pragma solidity ^0.8.19;


import{Script} from "forge-std/Script.sol";
import{Raffle} from "../src/Raffle.sol";
import{HelperConfig} from "./HelperConfig.s.sol";
import{CreateSubscription} from "./Interaction.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployContract();
    }

    function deployContract() public  returns (Raffle, HelperConfig) {
        // Implementation will go here
        HelperConfig helperconfig=new HelperConfig();
        //if local network=>deploy mock=>get local config
        HelperConfig.NetworkConfig memory config=helperconfig.getConfig();

        //-------substription creation-------
        if(config.subscriptionId==0){
            //create subscription
            CreateSubscription create_subscription=new CreateSubscription();//here CreateSubscription=>contract name and createSubscription=>function name
            (config.subscriptionId,config.s_vrfCoordinator)=create_subscription.createSubscription(config.s_vrfCoordinator);

            //fund it!
        }

        vm.startBroadcast();
        Raffle raffle=new Raffle(config.entranceFee,
        config.interval,
        config.s_vrfCoordinator,
        config.gasLane,
        config.subscriptionId,
        config.callBackGasLimit);
        vm.stopBroadcast();
        return (raffle,helperconfig);
    }
}