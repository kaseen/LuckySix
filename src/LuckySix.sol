// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/ILuckySix.sol';

import 'forge-std/console.sol';

// TODO: Function that gets tickets played by msg.sender at round passed as argument

contract LuckySix is ILuckySix, VRFConsumerBaseV2, Ownable {

    uint256 public numOfRound;
    uint256 private lastVerifiedRandomNumber;

    uint256 constant NUMBER_OF_DRAWS = 35;
    uint256 constant MASK_00111111 = 2 ** 6 - 1;

    // Chainlink 
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint256 public lastRequestId;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 100000;

    // Keep track of current lotteryState
    LOTTERY_STATE public lotteryState;

    // Mapping address to tickets played in specific round
    mapping(address => mapping(uint256 => Ticket[])) private players;

    // Keep track of drawn numbers for each round
    mapping(uint256 => uint256) public drawnNumbers;

    uint256[] private bonusMultiplier = [
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
        lastRequestId = requestRandomNumber();
    }

    function requestRandomNumber() private onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            uint16(3),          // requestConfirmations
            callbackGasLimit,
            uint32(1)           // numWords
        );
        emit RequestSent(requestId);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER);
        require(lastRequestId == requestId);
        lastVerifiedRandomNumber = randomWords[0];
        emit RequestFulfilled(requestId);
    }

    function drawNumbers(uint256 randomNumber) private {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, 'Lottery has not ended');

        // Generate numbers 1-48
        uint256[48] memory allNumbers;
        for(uint256 i; i < 48; ++i)
            allNumbers[i] = i + 1;

        // Get NUMBER_OF_DRAWS random numbers from verified random number
        uint256[] memory randomNumbers = new uint256[](NUMBER_OF_DRAWS);
        for (uint256 i; i < NUMBER_OF_DRAWS; ++i)
            randomNumbers[i] = uint256(keccak256(abi.encode(block.timestamp, randomNumber, i)));

        // Draw numbers
        uint256 j = allNumbers.length - 1;
        uint256 result;
        for(uint256 i; i < NUMBER_OF_DRAWS; ++i){
            uint256 indexOfChosenNumber = randomNumbers[i] % j;

            // Swap drawn number to the end of array [0, j] and decrement j
            uint256 tmp = allNumbers[j];
            allNumbers[j] = allNumbers[indexOfChosenNumber];
            allNumbers[indexOfChosenNumber] = tmp;

            // Pack drawn number into result variable
            result |= allNumbers[j--];
            result <<= 6;
        }

        // Undo last shifting and save result
        result >>= 6;
        drawnNumbers[numOfRound] = result;

        lotteryState = LOTTERY_STATE.CLOSED;
        emit LotteryEnded(numOfRound);
    }

    function checkIfValid(uint256[6] memory combination) private pure returns(bool) {
        for(uint256 i; i < combination.length; ++i) {
            // Check if number is between 1 and 48
            if(combination[i] < 1 || combination[i] > 48)
                return false;

            // Check if number is unique
            for(uint256 j = i + 1; j < combination.length; ++j)
                if(combination[i] == combination[j])
                    return false;
        }
        return true;
    }

    function unpackResultForRound(uint n) public view returns(uint8[] memory) {
        uint8[] memory result = new uint8[](NUMBER_OF_DRAWS);
        uint256 tmp = NUMBER_OF_DRAWS - 1;
        uint256 packedResult = drawnNumbers[n];

        for(uint256 i; i < NUMBER_OF_DRAWS; ++i)
            result[tmp - i] = uint8((packedResult >> i * 6) & MASK_00111111);

        return result;
    }

    function withdraw(uint256 amount)
        public
        payable
        onlyOwner
    {
        payable(msg.sender).transfer(amount);
    }

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

    // TODO: For local testing
    function endLotteryForLocalTesting() public {
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        drawNumbers(69);
    }
}