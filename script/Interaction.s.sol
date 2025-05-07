//here we manage the subscription creation and overcome from the error (invalidconsumer) in  testDontAllowPlayersToEnterWhileRaffleIsCalculating Test
//progarmatically way to get the sunscription id
//SPDX-Licence-Identifier:MIT;
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig, CodeContants } from "./HelperConfig.s.sol";

import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "test/mocks/LinkToken.sol";


contract CreateSubscription is Script{

    function CreateSubscriptionByConfig() public returns(uint256,address){
        HelperConfig helperconfig=new HelperConfig();
        address vrfCoodinator=helperconfig.getConfig().s_vrfCoordinator;
        (uint256 SubId,)=createSubscription(vrfCoodinator);
        return(SubId,vrfCoodinator);
   }
    
    function createSubscription(address vrfCoodinator) public returns(uint256,address ){
        console.log("creating subscription",block.chainid);
        vm.startBroadcast();
        //it is same as the subscription id which we get from the chainlink as it is programatically
        uint256 SubId=VRFCoordinatorV2_5Mock(vrfCoodinator).createSubscription();
        vm.stopBroadcast();
        console.log("subscription id",SubId);
        console.log(" plz update your subscriptionid in the HelperConfig.s.sol");
        return(SubId,vrfCoodinator);


    }

    
    function run() external{
         CreateSubscriptionByConfig();
    }
}
contract FundSubscription is Script,  CodeContants  {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperconfig=new HelperConfig();
        address vrfCoodinator=helperconfig.getConfig().s_vrfCoordinator;
        uint256 subscriptionId=helperconfig.getConfig().subscriptionId;
        address linktoken=helperconfig.getConfig().link;
        fundSubscription(vrfCoodinator,subscriptionId,linktoken);
    }
    function fundSubscription(address vrfCoodinator,uint256 subscriptionId,address linktoken) public {
        console.log("funding subscription",block.chainid);
        console.log("using vrfcoordinator",vrfCoodinator);
        console.log("on block chain id",block.chainid);
        if(block.chainid==Local_Chain_Id){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoodinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        }else{
            vm.startBroadcast();
            LinkToken(linktoken).transferAndCall(vrfCoodinator,FUND_AMOUNT,abi.encode(subscriptionId));//transferAndCall is a function in the LinkToken contract
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}