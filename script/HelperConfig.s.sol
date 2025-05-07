// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import{Script} from "forge-std/Script.sol";
import{DeployRaffle} from "./DeployRaffle.s.sol";
import {console} from "forge-std/console.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";


import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeContants {//abstract=> this contract can not be deployed but use as inherient
   uint256 public constant Sepoila_Eth_Id=1115511;
   uint256 public  constant Local_Chain_Id=31337;
   /* VRF Mock Values */
   uint96 public constant MOCK_BASE_FEE = 0.25 ether;
   uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
   int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is  CodeContants,Script{
    error Not_ValidNetwork();

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address s_vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callBackGasLimit;
        address link;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public NetworkConfigMap;

    constructor(){
        NetworkConfigMap[Sepoila_Eth_Id]=getSepoilaEthConf();
    }

    function getSepoilaEthConf() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee:0.01 ether,
            interval: 30,
            s_vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,//from doc
            gasLane:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B000000000000000000000000,//from doc
            subscriptionId: 0,
            callBackGasLimit:500000,
            link:0x779877A7B0D9E8603169DdbD7836e478b4624789

        });
    }
    function getLocalEthConfig()public pure  returns(NetworkConfig memory){
        return NetworkConfig({
                entranceFee:0.01 ether,
                interval:30,
                s_vrfCoordinator:address(0),
                gasLane:"",
                subscriptionId:0,
                callBackGasLimit:500000,
                link:address(0)
        });
    }
    //functiom to get which network am using currently
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        chainId = block.chainid;
        if (NetworkConfigMap[chainId].s_vrfCoordinator != address(0)) {
            return NetworkConfigMap[chainId];
        } else if (chainId == Local_Chain_Id) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert Not_ValidNetwork();
        }
    }
    function  getConfig() public returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }
    
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (localNetworkConfig.s_vrfCoordinator != address(0)) {
            // If it's not 0, it means local network config has already been set and we return the existing localNetworkConfig
            return localNetworkConfig;
        } else {
            localNetworkConfig = getLocalEthConfig();

            vm.startBroadcast();
            // Deploy the VRFCoordinatorV2_5Mock contract with mock values
             /**
                 * @dev This contract is a mock implementation used for testing purposes.
                 * It simulates the behavior of a real contract to provide a controlled environment
                 * for testing and development. The mock contract allows developers to test their
                 * code without relying on external dependencies or real-world data.
                 */
            VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK,
               
                MOCK_WEI_PER_UNIT_LINK
            );
            LinkToken linkToken=new LinkToken();
            vm.stopBroadcast();

            localNetworkConfig = NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds
                s_vrfCoordinator: address(vrfCoordinatorMock),
                // gasLane value doesn't matter.
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                callBackGasLimit: 500_000,
                link:address(linkToken)
            });

            return localNetworkConfig;
    }
}

    
    
}

