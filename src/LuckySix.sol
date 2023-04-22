// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import 'forge-std/console.sol';

// TODO: Function that gets tickets played by msg.sender at round passed as argument

contract LuckySix is VRFConsumerBase, Ownable {

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
    mapping(uint256 => uint256[6]) public drawnNumbers;

    // Last verified random number
    uint256 private randomNumber;

    event LotteryStarted(uint256 numOfRound);
    event TickedBought(address indexed player, uint256 numOfRound, uint256[6] combination);




    bytes32 internal keyHash;
    uint256 internal fee;

    uint256[] internal _allNumbers;
    uint256[] internal _drawnNumbers;
    uint256[] internal bonusMultiplier = [
        0, 0, 0, 0, 0, 10000, 7500, 5000, 
        2500, 1000, 500, 300, 200, 150, 100, 
        90, 80, 70, 60, 50, 40, 30, 25, 20, 
        15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
    ];


    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyhash;
        fee = _fee;
        lotteryState = LOTTERY_STATE.CLOSED;
        numOfRound = 0;
    }

    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, 'Can\'t start!');
        // TODO
        delete(_drawnNumbers);
        delete(_allNumbers);
        delete(randomNumber);

        lotteryState = LOTTERY_STATE.OPEN;
        emit LotteryStarted(++numOfRound);
    }

    function enterLottery(uint256[6] memory combination) public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, 'Lottery not open!');
        require(checkIfValid(combination), 'Not valid combination');
        players[msg.sender][numOfRound].push(Ticket({ combination: combination, bet: msg.value }));

        emit TickedBought(msg.sender, numOfRound, combination);
    }

    function endLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.OPEN, 'Can\'t end!');
        // TODO
        //require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        //bytes32 requestId = requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER); requestId;
        randomNumber = randomness;
    }

    /*
    function payout()
        public
        payable
        onlyOwner
    {
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER);

        drawNumbers();

        for(uint i=0; i<listOfPlayers.length; i++){
            uint tmp = cashEarned(listOfPlayers[i]);
            // If contract don't have enought ETH transfer all to winner and end
            if(tmp >= address(this).balance){
                payable(listOfPlayers[i]).transfer(address(this).balance);
                break;
            }
            if(tmp > 0)
                payable(listOfPlayers[i]).transfer(tmp);
        }

        emptyMap();

        lotteryState = LOTTERY_STATE.CLOSED;
    }
    */

    // TODO: public -> private
    function drawNumbers() public onlyOwner {
        // TODO: da je lokalan niz _allNumber su ovoj fji
        // TODO LOCAL: require(randomNumber > 0, "random-not-found");
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER);
        // TODO: require(_drawnNumbers.length == 0); // drawNumbers() cannot be called more than once

        uint256[48] memory allNumbers;
        for(uint256 i = 0; i < 48; i++)
            allNumbers[i] = i + 1;

        // Get 35 randomNumbers from randomValue
        uint256[] memory randomNumbers = new uint256[](35);
        for (uint256 i = 0; i < 35; i++) {
            randomNumbers[i] = uint256(keccak256(abi.encode(block.timestamp, randomNumber, i)));
        }

        // TODO:
        for (uint256 i = 48; i != 13; i--) {
            uint256 n = randomNumbers[(i - 1) - 13] % i;
            // Push drawn number to list
            _drawnNumbers.push(allNumbers[n]);
            // Remove number we just added to _drawnNumbers from allNumbers
            allNumbers[n] = allNumbers[allNumbers.length - 1];
            //allNumbers = removeByIndex(n, allNumbers);
        }
    }

    /*
    function emptyMap()
        public
        onlyOwner
    {
        for(uint256 i=0; i<listOfPlayers.length; i++){
            deletePlayer(listOfPlayers[i]);
        }
        delete(listOfPlayers);
    }
    */

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

    function removeByIndex(uint256 index, uint256[] memory array)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory tmp = new uint256[](array.length - 1);
        for (uint256 i = 0; i < index; i++) {
            tmp[i] = array[i];
        }
        for (uint256 i = index + 1; i < array.length; i++) {
            tmp[i-1] = array[i];
        }
        return tmp;
    }

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

    function getLINKBalance()
        public
        view
        onlyOwner
        returns (uint256)
    {
        return LINK.balanceOf(address(this));
    }

    function get48()
        internal
        pure
        returns (uint256[48] memory numbers)
    {
        for (uint256 i = 0; i < 48; i++)
            numbers[i] = i + 1;
        return numbers;
    }

    function getDrawnNumbers()
        public
        view
        returns (uint256[] memory)
    {
        return _drawnNumbers;
    }

    /*
    function getListOfPlayers()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return listOfPlayers;
    }
    */
}