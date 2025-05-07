/* here we can not add cumsumer address */



//SPDX License-Indentifier-MIT;
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import  {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import{HelperConfig} from "../../script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";

contract TestRaffle is Test {
    Raffle public  raffle;
    HelperConfig  public helperconfig;
    address public Player=makeAddr("player");
    uint256 public STARTING_PLAYER_BALANCE=10 ether;
    uint256 entranceFee;
    uint256 interval;
    address s_vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callBackGasLimit;
   

    /**
     * @dev Sets up the test environment by deploying the Raffle contract and initializing configuration parameters.
     */
    function setUp() public {
        // Deploys the Raffle contract and retrieves the Raffle and HelperConfig instances.
        
        DeployRaffle Deployer = new DeployRaffle();
        (raffle, helperconfig) = Deployer.deployContract(); // deployContract returns the Raffle and HelperConfig instances.

        // Retrieves the network configuration from the HelperConfig instance.
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();

        // Initializes the entrance fee for the raffle from the configuration.
        entranceFee = config.entranceFee;
        interval = config.interval;
        s_vrfCoordinator = config.s_vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callBackGasLimit = config.callBackGasLimit;
         vm.deal(Player,STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesIsOpen()  view public {
        assert(raffle.getRafflestatus() == Raffle.raffle_Status.open);//raffle is instance of Raffle contract
    }
    function testGetConfigByChainId() public {
        HelperConfig.NetworkConfig memory config = helperconfig.getConfigByChainId(block.chainid);

        console.log("VRF Coordinator Address:", config.s_vrfCoordinator);
        console.log("Entrance Fee:", config.entranceFee);
        console.log("Interval:", config.interval);

        assert(config.s_vrfCoordinator != address(0));
        assert(config.entranceFee > 0);
        assert(config.interval > 0);
    }
    function testPlayerThatEnterWithoutEnoughFunds() public{
        /*format=> arrange ,act,assert*/
        //arrange
        vm.prank(Player);//pranking the raffle with player address having 0 ether
        //act,assert
        vm.expectRevert(Raffle.SendMoreEth.selector);//below code must be expect the error
        raffle.EnterRaffle();

    }
    function testPlayerRecordWhenTheyEnterRaffle() public{
        //arrange
        vm.prank(Player);
        //act
        raffle.EnterRaffle{value: entranceFee}();
        //assert
        address PlayerRecord=raffle.getPlayers(0);//getPlayers(0) returns=>0 index of player array
        assert(PlayerRecord==Player);
        //this all give the error of outoffund bcz enterancefee is 1e16=>0.01 ether and we require >0.01 ether so adding vm.deal() in setu`p function
    }
    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        raffle.EnterRaffle{value: entranceFee}();
        vm.prank(Player);
        vm.warp(block.timestamp + interval + 1);//used to set the timestamp
        vm.roll(block.number + 1);//used to set the block number
        raffle.performUpkeep("");

        // Act / Assert
        vm.expectRevert(Raffle.raffle_raffleIsNotOpen.selector);
        vm.prank(Player);
        raffle.EnterRaffle{value: entranceFee}();

    }
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        //arrarnge 
        vm.warp(block.timestamp + interval +1);//for incraesing the time
        vm.roll(block.number + 1);//for incerasing the number of blocks
        //Act
        (bool upkeepNeeded,)=raffle.checkUpkeep("");
        //assert
        assert(!upkeepNeeded);
    }
    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        //arrange
        vm.prank(Player);
        raffle.EnterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");
        //Act
        (bool upkeepNeeded,)=raffle.checkUpkeep("");
        //assert
        assert(!upkeepNeeded);



    }
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public{
        //arrange
        vm.prank(Player);
        raffle.EnterRaffle{value:entranceFee}();
        //Account
        (bool upkeepNeeded,)=raffle.checkUpkeep("");
        //assert
        assert(!upkeepNeeded);

    } function testCheckUpkeepReturnsTrueWhenParametersGood() public{
        //arrange 
        vm.prank(Player);
        raffle.EnterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        //Act
        (bool upkeepNeeded,)=raffle.checkUpkeep("");
        //assert
        assert(upkeepNeeded);
    }

    function  testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()public{
        //arrange
        vm.prank(Player);
        raffle.EnterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        //act/assert
        raffle.performUpkeep("");

    }
    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public{
        //arrange
        uint256 currbalance=0;
        uint playerno=0;
        Raffle.raffle_Status rstate = raffle.getRafflestatus();
        vm.warp(block.timestamp+interval+1);
        //act/assert

        /* this use when you have a more parameter in custom error
          vm.expectRevert(
           abi.encodeWithSelector(CustomError.selector, 1, 2));
        */

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector,currbalance,playerno,rstate));
        raffle.performUpkeep("");
        
    }


}