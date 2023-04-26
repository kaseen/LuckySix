// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import 'forge-std/console.sol';

// TODO: Function that gets tickets played by msg.sender at round passed as argument
// TODO: Pack 35 drawn numbers into single uint256 (lesser gas cost)

contract LuckySix is VRFConsumerBaseV2, Ownable {

    enum LOTTERY_STATE{
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    struct Ticket{
        uint256[6] combination;
        uint256 bet;
    }

    uint256 public numOfRound;

    // Keep track of current lotteryState
    LOTTERY_STATE public lotteryState;

    // Mapping address to tickets played in specific round
    mapping(address => mapping(uint256 => Ticket[])) private players;

    // Keep track of drawn numbers for each round
    mapping(uint256 => uint256[35]) public drawnNumbers;

    event LotteryStarted(uint256 numOfRound);
    event LotteryEnded(uint256 numOfRound);
    event TickedBought(address indexed player, uint256 numOfRound, uint256[6] combination);

    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId);

    uint256[] internal bonusMultiplier = [
        0, 0, 0, 0, 0, 10000, 7500, 5000, 
        2500, 1000, 500, 300, 200, 150, 100, 
        90, 80, 70, 60, 50, 40, 30, 25, 20, 
        15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
    ];


    constructor(
        uint64 subscriptionId,
        address vrfCoordinator
    ) VRFConsumerBaseV2 (vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        lotteryState = LOTTERY_STATE.CLOSED;

        s_subscriptionId = subscriptionId;
        numOfRound = 0;
    }

    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, 'Can\'t start!');
        lotteryState = LOTTERY_STATE.OPEN;
        emit LotteryStarted(++numOfRound);
    }

    function enterLottery(uint256[6] memory combination) public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, 'Lottery not open!');
        require(checkIfValid(combination), 'Not valid combination');
        require(msg.value != 0);
        players[msg.sender][numOfRound].push(Ticket({ combination: combination, bet: msg.value }));

        emit TickedBought(msg.sender, numOfRound, combination);
    }

    function endLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, 'Can\'t end!');
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        //lastRequestIdSent = requestRandomness(keyHash, fee);
    }

    uint256 public randomNumber2 = 105;
    function drawNumbers(uint256 randomNumber) private {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, 'Lottery has not ended');

        // Generate numbers 1-48
        uint256[48] memory allNumbers;
        for(uint256 i = 0; i < 48; i++)
            allNumbers[i] = i + 1;

        // Get 35 randomNumbers from randomValue
        uint256[] memory randomNumbers = new uint256[](35);
        for (uint256 i = 0; i < 35; i++)
            randomNumbers[i] = uint256(keccak256(abi.encode(block.timestamp, randomNumber, i)));

        // Draw numbers
        uint256 j = allNumbers.length - 1;
        for(uint256 i = 0; i < randomNumbers.length; i++){
            uint256 indexOfChosenNumber = randomNumbers[i] % j;

            // Swap drawn number to the end of array [0, j] and decrement j
            uint256 tmp = allNumbers[j];
            allNumbers[j] = allNumbers[indexOfChosenNumber];
            allNumbers[indexOfChosenNumber] = tmp;

            drawnNumbers[numOfRound][i] = allNumbers[j--];
        }
    }

    function checkIfValid(uint256[6] memory combination) private pure returns(bool) {
        for(uint256 i = 0; i < combination.length; i++) {
            // Check if number is between 1 and 48
            if(combination[i] < 1 || combination[i] > 48)
                return false;

            // Check if number is unique
            for(uint256 j = i + 1; j < combination.length; j++)
                if(combination[i] == combination[j])
                    return false;
        }
        return true;
    }

    function withdraw(uint256 amount)
        public
        payable
        onlyOwner
    {
        payable(msg.sender).transfer(amount);
    }

    function donate()
        public
        payable
    {}

    function getETHBalance()
        public
        view
        onlyOwner
        returns(uint256)
    {
        return address(this).balance;
    }

    // ------------------------------------------------------------

   struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256 randomNumber;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            randomNumber: 0,
            exists: true
    
        });
        lastRequestId = requestId;
        emit RequestSent(requestId);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "Request not found");
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER);
        //require(lastRequestIdSent == requestId);
        lotteryState = LOTTERY_STATE.CLOSED;

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomNumber = _randomWords[0];
        //drawNumbers(_randomWords[0]);
        emit RequestFulfilled(_requestId);
    }

    // ------------------------------------------------------------

    // TODO: For local testing
    /*
    function localTest() public {
        fulfillRandomness('0x', 123);
    }*/


    /*function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER);
        //require(lastRequestIdSent == requestId);
        drawNumbers(randomness);
        lotteryState = LOTTERY_STATE.CLOSED;

        emit LotteryEnded(numOfRound);
    }*/

    /*
    function deletePlayer(address x)
        internal
    {
        // Delete all Tickets of given address
        Ticket[] storage tickets = players[x];
        for(uint256 i=0; i<tickets.length; i++){
                delete(tickets[i].combination);
                delete(tickets[i].bet);
        }
        // Delete player from map
        delete(players[x]);
    }
    */

    /*
    function cashEarned(address player)
        internal
        returns(uint256)
    {
        // How many tickets players bought
        uint256 n = players[player].length;
        uint256 sum = 0;
        int256 x;
        for(uint i=0; i<n; i++){
            x = returnIndexOfLastDrawnNumber(players[player][i].combination);
            // If Ticket[i] won lottery, he gained bonusMultiplier[i] * Ticket[i].bet
            if(x != -1)
                sum += bonusMultiplier[uint(x)] * players[player][i].bet;
        }
        return sum;
    }
    */

    /*
    function returnIndexOfLastDrawnNumber(uint256[6] memory numbers)
        internal
        view
        returns (int256)
    {
        uint256 counter = 0;
        int256 index = -1;
        for (uint256 i = 0; i < numbers.length; i++) {
            for (uint256 j = 0; j < _drawnNumbers.length; j++) {
                if (numbers[i] == _drawnNumbers[j]) {
                    counter++;
                    index = int256(j) > index ? int256(j) : index;
                }
            }
        }
        return (counter == 6 ? index : -1);
    }
    */

    /*
    function getDrawnNumbers()
        public
        view
        returns (uint256[] memory)
    {
        return _drawnNumbers;
    }
    */
}