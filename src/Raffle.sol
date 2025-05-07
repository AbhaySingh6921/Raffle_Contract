//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
/**
 * @title Raffle
 * @author Abhay singh
 * @notice  this contract creating a sample raffle
 * @dev  impleamnetation  chainlink VRFv2.5
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


contract Raffle is VRFConsumerBaseV2Plus{
    //----------error handling-----
    error SendMoreEth();
    error raffle_transfer_failed();//trafering fail in case of winner is not able to recieve the money
    error raffle_raffleIsNotOpen();//during the picking of winner if raffle is  open
    error Raffle__UpkeepNotNeeded( uint256 balance,uint256 playLength,uint256 raffleStatus);//here we give the paramter so decribe the deveoper what cause  the error

    //-----------raffle variables--------------
    uint256 private immutable i_EntranceFee;
   uint256 private immutable i_interval;
    address[] private s_players;
    uint256 private s_LastTimeStamp;
    address payable private s_recentWinner;
    raffle_Status private s_raffleStatus;

    // ---------------Chainlink VRF variables--------------
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_SubscriptionId;
    uint256 private immutable i_callbackGasLimit;
    uint16 private constant  Request_Confirmations=3;
    uint32 private constant Num_Words=1;

    //-----------enum---------
    //use during the choosing of winner no,one should enter the raffle
    //tract the status of the raffle
    enum raffle_Status{
        open,//0
        calculating   //1 //when we are picking the winner
    }

     //---------------events--------------------
     event RaffleEntered(address indexed player); //line code=> means => we can filter the event by player address
     event  pickedWinner(address winner) ;     
    


    //so this is our constructor but VRFConsumerBaseV2Plus have seperate constructor so we have to call it
    constructor(uint256  EntranceFee, 
    uint256 interval,
    address s_vrfCoordinator,
    bytes32 gasLane,
    uint256 subscriptionId,
    uint32 callbackGasLimit) 
     VRFConsumerBaseV2Plus(s_vrfCoordinator) {
        i_interval=interval;
        s_LastTimeStamp=block.timestamp;//block.timestamp is a global variable  its indictae when contract mined
        i_EntranceFee=EntranceFee;
        i_keyHash=gasLane;
        i_SubscriptionId=subscriptionId;
        i_callbackGasLimit=callbackGasLimit;
        //by default rafffle is open
        s_raffleStatus=raffle_Status.open;//or we can use 0


    }
    //-----------chainlink automation function----------------
    //checkUpkeep and performUpkeep
    /**
 * @dev This is the function that the Chainlink Keeper nodes call
 * they look for `upkeepNeeded` to return True.
 * the following should be true for this to return true:
 * 1. The time interval has passed between raffle runs.
 * 2. The lottery is open.
 * 3. The contract has ETH.
 * 4. There are players registered.
 * 5. Implicity, your subscription is funded with LINK.
 */
// automation the  contract
//this function continue check that the upkeepNeeded is true or not if true then it will call performUpkeep
function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
    bool isOpen = s_raffleStatus == raffle_Status.open;
    bool timePassed = ((block.timestamp - s_LastTimeStamp) >= i_interval);
    bool hasPlayers = s_players.length > 0;
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
    return (upkeepNeeded, "0x0");//0x0 =0;

}
    

    
    function EnterRaffle() public payable{////why payable? bcz we are taking money from user
            //require(msg.value>=i_entrancefee,"not enough eth for sending");//here error in form of string take a lot of gas so we use 
            // require(msg.value>=i_EntranceFee, SendMoreEth());not supported by this solidity  version 
            if(msg.value< i_EntranceFee){
                revert SendMoreEth();
            }// here it take a lot of time  so we use and it is most gas effecient
            
            s_players.push(payable(msg.sender)); // Add sender address to players array
            if(s_raffleStatus!=raffle_Status.open){
                revert raffle_raffleIsNotOpen();
            }
            
            //1. mkae migration easier
            //2. make front end "indexing"  easier

            emit RaffleEntered(msg.sender);//means
    }   
        

       //1.pick a random number
       //2. use a random number to pick the player
       //3.be automatcally called 
    function  performUpkeep(bytes calldata /* performData */) external{
            //is there enough time  pass to pick a winner=>use block.timestamp
        if(block.timestamp-s_LastTimeStamp<i_interval){
            revert("not enough time has passed");

        }
            //perforupkeep  run only run if checkupkeep is true
            (bool upkeepNeeded, ) = checkUpkeep("");
          // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleStatus));//here given why the error is occured -->through the parameter
        }
            //make the status calcuting while we are picking the winner
            s_raffleStatus=raffle_Status.calculating;
            
            //get the random number=>using=>chainlink VRF
            //blockchain is the derterministic(give same output for same input .cann't produced random number)
            //-----------------chainlink  random  VRF----------------
            //request a random number
            VRFV2PlusClient.RandomWordsRequest memory request= VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_SubscriptionId,
                requestConfirmations: Request_Confirmations,
                callbackGasLimit: uint32(i_callbackGasLimit),
                numWords: Num_Words,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))

            }
            ); 
            uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

            
    


    

        function fulfillRandomWords(uint256 /*requestId */, uint256[] calldata randomWords) internal virtual override {
            //here we will get the random number
            //pick a winner
            uint256 indexOfWinner=randomWords[0]%s_players.length;
            address payable winner = payable(s_players[indexOfWinner]);
            s_recentWinner=winner;
            //---------After the winner is picked---------------

            //reopen the raffle
            s_raffleStatus=raffle_Status.open;

            //empty the players array
            s_players=new address payable[](0);
            
            //update the last timestamp,bring back to the current  present time

            //sending all the  contract money to the winner
            (bool success, ) = winner.call{value: address(this).balance}("");
            if(!success){
                revert raffle_transfer_failed();
            }
            //emit the event
            emit pickedWinner(winner);

        }
       //getter function
        function GetEntranceFee() external view returns(uint256){
            return i_EntranceFee;
        }
        function  getRafflestatus()external view  returns(raffle_Status){
            return s_raffleStatus;
        }

        function getPlayers(uint256 IndexOfPlayer)external  view returns(address){
            return s_players[IndexOfPlayer];
        }
}