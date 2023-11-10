// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol';
import '@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/ILuckySix.sol';

contract LuckySix is ILuckySix, VRFConsumerBaseV2, Ownable, AutomationCompatibleInterface {

    Round public roundInfo;
    uint256 public platformFee = 0.01 ether;
    uint256 private lastVerifiedRandomNumber;
    uint256 private ownerBalance;

    uint256 constant NUMBER_OF_DRAWS = 35;
    uint256 constant MASK_0b111111 = 2 ** 6 - 1;

    uint256 public roundDuration = 600;     // TODO: DAO

    // Chainlink 
    VRFCoordinatorV2Interface private COORDINATOR;
    uint64 private s_subscriptionId;
    uint256 private lastRequestId;
    bytes32 private keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 private callbackGasLimit = 100000;
    address private keeperAddress;

    // Keep track of current lotteryState
    LOTTERY_STATE public lotteryState;

    // Mapping address to tickets played in specific round
    mapping(address => mapping(uint256 => Ticket[])) private players;

    // Keep track of drawn numbers for each round
    mapping(uint256 => uint256) private drawnNumbers;

    modifier onlyKeeper {
        require(msg.sender == keeperAddress, 'Caller is not keeper.');
        _;
    }

    uint256[] public bonusMultiplier = [
        0, 0, 0, 0, 0, 10000, 7500, 5000, 
        2500, 1000, 500, 300, 200, 150, 100, 
        90, 80, 70, 60, 50, 40, 30, 25, 20, 
        15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
    ];

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        address keeperAddr
    )   
    VRFConsumerBaseV2(vrfCoordinator) 
    Ownable(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keeperAddress = keeperAddr;
        lotteryState = LOTTERY_STATE.CLOSED;
        roundInfo.numberOfRound = 0;
        roundInfo.isStarted = false;
    }

    function openRound() public onlyKeeper {
        require(lotteryState == LOTTERY_STATE.CLOSED, 'Can\'t start!');
        lotteryState = LOTTERY_STATE.READY;
        roundInfo.isStarted = false;
        emit GameRoundOpened(roundInfo.numberOfRound);
    }

    function playTicket(uint256[6] memory combination) public payable {
        require(lotteryState == LOTTERY_STATE.READY || lotteryState == LOTTERY_STATE.STARTED, 'Lottery not open!');
        require(checkIfValid(combination), 'Not valid combination.');
        require(msg.value > platformFee, 'Not enough funds.');

        if(!roundInfo.isStarted){
            lotteryState = LOTTERY_STATE.STARTED;
            roundInfo.isStarted = true;
            roundInfo.timeStarted = block.timestamp;
            emit GameStarted(roundInfo.numberOfRound);
        }

        players[msg.sender][roundInfo.numberOfRound].push(Ticket({ combination: combination, bet: msg.value - platformFee }));
        ownerBalance += platformFee;

        emit TicketBought(msg.sender, roundInfo.numberOfRound, combination);
    }

    function endRound() public onlyKeeper {
        require(lotteryState == LOTTERY_STATE.STARTED, 'Can\'t end!');
        require(block.timestamp > roundInfo.timeStarted + roundDuration, 'Lottery has not ended.');
        lotteryState = LOTTERY_STATE.CALCULATING;
        lastRequestId = requestRandomNumber();
    }

    function drawNumbers(uint256 randomNumber) private {
        require(lotteryState == LOTTERY_STATE.DRAWING, 'Randomness not fulfilled.');

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
        drawnNumbers[roundInfo.numberOfRound] = result;

        lotteryState = LOTTERY_STATE.CLOSED;
        emit GameRoundEnded(roundInfo.numberOfRound++);
    }

    function checkIfValid(uint256[6] memory combination) private pure returns (bool) {
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

    function unpackResultForRound(uint256 n) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](NUMBER_OF_DRAWS);
        uint256 tmp = NUMBER_OF_DRAWS - 1;
        uint256 packedResult = drawnNumbers[n];

        for(uint256 i; i < NUMBER_OF_DRAWS; ++i)
            result[tmp - i] = (packedResult >> i * 6) & MASK_0b111111;

        return result;
    }

    function getPayoutForTicket(uint256 round, uint256 indexOfTicket) public {
        require(players[msg.sender][round][indexOfTicket].bet > 0, 'Ticket already cashed out.');
        require(round < roundInfo.numberOfRound, 'Invalid round number.');

        // Calculate index of last drawn number
        uint256 index = returnIndexOfLastDrawnNumber(round, players[msg.sender][round][indexOfTicket].combination);

        require(index < (NUMBER_OF_DRAWS - 1), 'Ticket not valid.');
        uint256 cashEarned = bonusMultiplier[index] * players[msg.sender][round][indexOfTicket].bet;

        // If platform doesn't have enought balance give all to winning player
        uint256 balance = platformBalance();
        if(cashEarned > balance)
            cashEarned = balance;

        payable(msg.sender).transfer(cashEarned);

        // Ticket is invalid when bet equals 0
        players[msg.sender][round][indexOfTicket].bet = 0;
        emit TicketCashedOut(msg.sender, round, indexOfTicket, cashEarned);
    }

    function returnIndexOfLastDrawnNumber(uint256 round, uint256[6] memory ticketNumbers) private view returns (uint256) {
        uint256[] memory combination = unpackResultForRound(round);
        uint256 counter = 0;
        int256 index = -1;

        for (uint256 i; i < ticketNumbers.length; ++i)
            for (uint256 j; j < combination.length; ++j)
                if (ticketNumbers[i] == combination[j]){
                    counter++;
                    index = int256(j) > index ? int256(j) : index;
                }

        // Return anything more than NUMBER_OF_DRAWS-1 if not valid, return 100 for example
        return (counter == 6 ? uint256(index) : 100);
    }

    // =============================================================
    //                         CHAINLINK
    // =============================================================

    function requestRandomNumber() private onlyKeeper returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            uint16(3),          // requestConfirmations
            callbackGasLimit,
            uint32(1)           // numWords
        );
        emit GameRequestRandomNumber(requestId);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING);
        require(lastRequestId == requestId);
        lotteryState = LOTTERY_STATE.DRAWING;
        lastVerifiedRandomNumber = randomWords[0];
        emit GameRandomNumberFulfilled(requestId);
    }

    function checkUpkeep(bytes calldata /* checkData */)
    external
    view
    override
    returns(bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false; performData;
        if(lotteryState == LOTTERY_STATE.CLOSED)
            upkeepNeeded = true;
        else if(lotteryState == LOTTERY_STATE.STARTED && (block.timestamp > roundInfo.timeStarted + roundDuration))
            upkeepNeeded = true;
        else if(lotteryState == LOTTERY_STATE.DRAWING)
            upkeepNeeded = true;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // TODO: raspakuj perform data
        require(msg.sender == keeperAddress);
        if(lotteryState == LOTTERY_STATE.CLOSED)
            openRound();
        else if(lotteryState == LOTTERY_STATE.STARTED && (block.timestamp > roundInfo.timeStarted + roundDuration))
            endRound();
        else if(lotteryState == LOTTERY_STATE.DRAWING)
            drawNumbers(lastVerifiedRandomNumber);
    }

    function setKeeperAddress(address newAddress) external onlyOwner {
        keeperAddress = newAddress;
    }

    // =============================================================
    //                            OTHER
    // =============================================================

    function platformBalance() public view returns (uint256) {
        return address(this).balance - ownerBalance;
    }

    function getTicketsForRound(uint256 n) public view returns(Ticket[] memory) {
        return players[msg.sender][n];
    }

    function withdrawPlatformFee() public payable onlyOwner {
        platformFee = 0;
        payable(msg.sender).transfer(platformFee);
    }

    function setPlatformFee(uint256 amount) public onlyOwner {
        platformFee = amount;
        emit PlatformFeeChanged(amount);
    }

    function setRoundDuration(uint256 newDuration) public onlyKeeper {
        roundDuration = newDuration;
    } 
}