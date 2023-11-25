// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol';
import '@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@oz-upgradeable/access/OwnableUpgradeable.sol';
import '@oz-upgradeable/utils/PausableUpgradeable.sol';
import '@oz/proxy/ERC1967/ERC1967Proxy.sol';
import './VRFConsumerBaseV2Upgradeable.sol';
import './interfaces/ILuckySix.sol';

contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}

contract LuckySix is 
    ILuckySix,
    UUPSUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AutomationCompatibleInterface,
    VRFConsumerBaseV2Upgradeable
{
    /**
     * @dev Recorded numbers and jokers for each round are represented using the following
     *      packing blueprint, where the rightmost bit is the least significant bit:
     *
     * 255        246        240   210       204       198    6          0
     *  | -------- | -------- |     | ------- | ------- |     | -------- | 
     *  |  joker1  |  joker2  |     | number1 | number2 |     | number35 |
     *  | -------- | -------- |     | ------- | ------- |     | -------- |
     *  |          |          | ... |         |         | ... |          |
     *  |  6 bits  |  6 bits  |     |  6bits  |  6bits  |     |  6 bits  |
     *  | -------- | -------- |     | ------- | ------- |     | -------- |
     */
    mapping(uint256 => uint256) private packedJokersAndNumbersForRound;

    // Associating addresses with tickets played in a specific round.
    mapping(address => mapping(uint256 => Ticket[])) private players;

    /**
     * @dev Since the maximum number of 6-bit numbers that can be packed in 256bits is 42,
     *      the limitation here is that the `_NUMBER_OF_DRAWS` and `_NUMBER_OF_JOCKERS`
     *      can be 42. Also, the maximum number that can be packed in a 6-bit format is 63,
     *      which serves as the upper limit for `_MAXIMUM_NUMBER_DRAWN`.
     */
    uint256 private constant _NUMBER_OF_DRAWS = 35;
    uint256 private constant _NUMBER_OF_JOCKERS = 2;
    uint256 private constant _MAXIMUM_NUMBER_DRAWN = 48;

    uint256 private constant _BITPOS_JOCKERS = 246;
    uint256 private constant _BITMASK_0b111111 = 2 ** 6 - 1;

    // Public variables that are initialized within the `initializator` function
    uint256 public platformFee;
    uint256 public roundDuration;
    Round public roundInfo;
    LOTTERY_STATE public lotteryState;
    uint256[35] public bonusMultiplier;
    
    uint256 private lastVerifiedRandomNumber;
    uint256 private ownerBalance;

    // Chainlink 
    VRFCoordinatorV2Interface private COORDINATOR;
    uint64 private s_subscriptionId;
    uint256 private lastRequestId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    address private keeperAddress;

    modifier onlyKeeper {
        if(msg.sender != keeperAddress) revert UnauthorizedAccess();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        require(_NUMBER_OF_DRAWS + _NUMBER_OF_JOCKERS < _MAXIMUM_NUMBER_DRAWN);
        _disableInitializers();
    }

    // Constructor
    function initialize (
        uint64 subscriptionId,
        address vrfCoordinator,
        address keeperAddr
    ) 
    public 
    initializer
    {
        // Constructor for upgradable extensions
        __UUPSUpgradeable_init();
        __Pausable_init();
        __Ownable_init(msg.sender);
        __VRFConsumerBaseV2Upgradeable_init(vrfCoordinator);

        // Constructor body
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keeperAddress = keeperAddr;
        lotteryState = LOTTERY_STATE.CLOSED;

        // Initial contract values
        keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        callbackGasLimit = 100000;
        roundDuration = 600;
        platformFee = 0.01 ether;
        bonusMultiplier = [
            0, 0, 0, 0, 0, 10000, 7500, 5000, 
            2500, 1000, 500, 300, 200, 150, 100, 
            90, 80, 70, 60, 50, 40, 30, 25, 20, 
            15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
        ];
    }

    function openRound() public onlyKeeper {
        if(lotteryState != LOTTERY_STATE.CLOSED) revert LotteryNotClosed();
        lotteryState = LOTTERY_STATE.READY;
        roundInfo.isStarted = false;
        emit GameRoundOpened(roundInfo.numberOfRound);
    }

    function playTicket(uint256[6] memory combination) public payable {
        if(lotteryState != LOTTERY_STATE.READY && lotteryState != LOTTERY_STATE.STARTED) revert LotteryNotOpen();
        if(!checkIfValid(combination)) revert NotValidCombination(combination);
        if(msg.value <= platformFee) revert NotEnoughFunds(msg.value);

        if(!roundInfo.isStarted){
            lotteryState = LOTTERY_STATE.STARTED;
            roundInfo.timeStarted = uint64(block.timestamp);
            roundInfo.isStarted = true;
            emit GameStarted(roundInfo.numberOfRound);
        }

        players[msg.sender][roundInfo.numberOfRound].push(Ticket({ combination: combination, bet: msg.value - platformFee }));
        ownerBalance += platformFee;

        emit TicketBought(msg.sender, roundInfo.numberOfRound, combination);
    }

    function endRound() public onlyKeeper {
        if(lotteryState != LOTTERY_STATE.STARTED) revert LotteryNotStarted();
        if(block.timestamp <= roundInfo.timeStarted + roundDuration) revert LotteryNotEnded();

        lotteryState = LOTTERY_STATE.CALCULATING;
        lastRequestId = requestRandomNumber();
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

    function getPayoutForTicket(uint256 round, uint256 indexOfTicket) public {
        Ticket[] storage playerTickets = players[msg.sender][round];

        if(indexOfTicket >= playerTickets.length) revert InvalidTicket(round, indexOfTicket);
        if(playerTickets[indexOfTicket].bet == 0) revert TicketAlreadyCashed(round, indexOfTicket);

        // Calculate multiplier of last drawn number
        uint256 multiplier = getMultiplier(round, playerTickets[indexOfTicket].combination);

        if(multiplier == 0) revert TicketNotWinning(round, indexOfTicket);
        uint256 cashEarned = multiplier * playerTickets[indexOfTicket].bet;

        // If platform doesn't have enought balance give all to winning player
        uint256 balance = platformBalance();
        if(cashEarned > balance)
            cashEarned = balance;

        payable(msg.sender).transfer(cashEarned);

        // Ticket is invalid when bet equals 0
        playerTickets[indexOfTicket].bet = 0;
        emit TicketCashedOut(msg.sender, round, indexOfTicket, cashEarned);
    }

    function getMultiplier(uint256 round, uint256[6] memory ticketNumbers) private view returns (uint256) {
        uint256[] memory combination = unpackResultForRound(round);
        uint256 counter = 0;
        int256 index = -1;

        uint256 n = ticketNumbers.length;
        uint256 m = combination.length;
        for(uint256 i; i < n; ++i)
            for(uint256 j; j < m; ++j)
                if(ticketNumbers[i] == combination[j]){
                    counter++;
                    index = int256(j) > index ? int256(j) : index;
                }

        if(counter == 0)
            return 100;
        else if(counter == 6)
            return bonusMultiplier[uint256(index)];
        else 
            return 0;
    }

    // =============================================================
    //                        DRAWING NUMBERS
    // =============================================================

    /**
     * @dev Generate random numbers by drawing jokers first, then drawing numbers, and
     *      finally combine the results using bitwise operations to store the outcome
     *      in a single variable.
     */
    function drawNumbers() private {
        if(lotteryState != LOTTERY_STATE.DRAWING) revert LotteryNotDrawn();

        // Variable that will hold a combination of packed drawn numbers and jockers 
        uint256 drawnNumbersAndJokers;

        uint256[] memory randomNumbers = generateRandomNumbers();

        drawnNumbersAndJokers = drawAndPackJockers(randomNumbers) << _BITPOS_JOCKERS;
        drawnNumbersAndJokers |= drawAndPackNumbers(randomNumbers);

        packedJokersAndNumbersForRound[roundInfo.numberOfRound] = drawnNumbersAndJokers;

        lotteryState = LOTTERY_STATE.CLOSED;
        emit GameRoundEnded(roundInfo.numberOfRound++);
    }

    /**
     * @dev Generating a set of `_NUMBER_OF_DRAWS + _NUMBER_OF_JOCKERS` random numbers
     *      drawn from `lastVerifiedRandomNumber` to determine absolutely random positions
     *      for both jokers and regular numbers.
     */
    function generateRandomNumbers() private view returns (uint256[] memory) {
        uint256[] memory randomNumbers = new uint256[](_NUMBER_OF_DRAWS + _NUMBER_OF_JOCKERS);
        for (uint256 i; i < _NUMBER_OF_DRAWS + _NUMBER_OF_JOCKERS; ++i)
            randomNumbers[i] = uint256(keccak256(abi.encode(block.timestamp, lastVerifiedRandomNumber, i)));
        return randomNumbers;
    }

    /**
     * @dev Positions for the joker are limited to 0 through `_NUMBER_OF_DRAWS - 5`
     *      as winning combination is not possible in the initial 5 draws. Additionally,
     *      the second joker can have one less position than the first one.
     */
    function drawAndPackJockers(uint256[] memory randomNumbers) private pure returns (uint256 result) {
        result |= randomNumbers[0] % (_NUMBER_OF_DRAWS - 5);
        result <<= 6;
        result |= randomNumbers[1] % (_NUMBER_OF_DRAWS - 6);
    }

    /**
     * @dev Numbers are drawn independently of jokers, and the most recently drawn number is
     *      located in the lowest bit of the `packedJokersAndNumbersForRound` map.
     */
    function drawAndPackNumbers(uint256[] memory randomNumbers) private pure returns (uint256 result) {
        // Create a sequence of numbers from 1 to 48
        uint256[_MAXIMUM_NUMBER_DRAWN] memory allNumbers;
        for(uint256 i; i < _MAXIMUM_NUMBER_DRAWN; ++i)
            allNumbers[i] = i + 1;

        uint256 j = allNumbers.length - 1;
        for(uint256 i = 2; i < _NUMBER_OF_DRAWS + 2; ++i){
            uint256 indexOfChosenNumber = randomNumbers[i] % j;

            // Move the selected number to the end of the array [0, j] and decrease the value of j
            uint256 tmp = allNumbers[j];
            allNumbers[j] = allNumbers[indexOfChosenNumber];
            allNumbers[indexOfChosenNumber] = tmp;

            // Pack the drawn number in the result variable
            result |= allNumbers[j--];
            result <<= 6;
        }
        result >>= 6;
    }

    /**
     * @dev A function that unpacks drawn numbers for a given round and returns a tuple of jokers positions.
     */
    function unpackJockersForRound(uint256 n) public view returns (uint256, uint256) {
        uint256 packedResult = packedJokersAndNumbersForRound[n] >> _BITPOS_JOCKERS;

        uint256 joker2 = packedResult & _BITMASK_0b111111;
        uint256 joker1 = (packedResult >> 6) & _BITMASK_0b111111;

        return (joker1, joker2);
    }

    /**
     * @dev A function that unpacks drawn numbers for a given round and returns the drawn numbers 
     *      in the order they were drawn.
     */
    function unpackResultForRound(uint256 n) public view returns (uint256[] memory) {
        uint256 packedResult = packedJokersAndNumbersForRound[n];

        uint256[] memory result = new uint256[](_NUMBER_OF_DRAWS);
        uint256 tmp = _NUMBER_OF_DRAWS - 1;

        for(uint256 i; i < _NUMBER_OF_DRAWS; ++i)
            result[tmp - i] = (packedResult >> i * 6) & _BITMASK_0b111111;

        return result;
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

    function performUpkeep(bytes calldata /* performData */) onlyKeeper external override {
        // TODO: raspakuj perform data
        if(lotteryState == LOTTERY_STATE.CLOSED)
            openRound();
        else if(lotteryState == LOTTERY_STATE.STARTED && (block.timestamp > roundInfo.timeStarted + roundDuration))
            endRound();
        else if(lotteryState == LOTTERY_STATE.DRAWING)
            drawNumbers();
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

    function setRoundDuration(uint256 newDuration) public onlyOwner {
        roundDuration = newDuration;
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() payable external {}
}
