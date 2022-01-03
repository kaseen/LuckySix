// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckySix is VRFConsumerBase, Ownable {

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public _randomResult;

    uint256[] internal _allNumbers;
    uint256[] internal _drawnNumbers;
    uint256[] internal xBonus = [0, 0, 0, 0, 0, 10000, 7500, 5000, 2500, 1000, 500, 300, 200, 150, 100, 90, 80, 70, 60, 50, 40, 30, 25, 20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

    mapping(address => Ticket[]) internal players;
    address[] internal listOfPlayers;

    struct Ticket{
        uint256[6] combination;
        uint256 bet;
    }

    enum LOTTERY_STATE{
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyhash;
        fee = _fee;
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function startLottery()
        public
        onlyOwner
    {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start!");
        delete(_drawnNumbers);
        delete(_allNumbers);
        delete(_randomResult);
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function enterLottery(uint256[6] memory _combination)
        public
        payable
    {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery not open!");
        require(checkIfValid(_combination) == true, "Not valid combination");
        players[msg.sender].push(Ticket({combination: _combination, bet: msg.value}));
        // Tracking players entered to empty map at the end of lottery
        bool insert = true;
        for(uint i=0; i<listOfPlayers.length; i++)
            if(listOfPlayers[i] == msg.sender){
                insert = false;
                break;
            }
        if(insert)
            listOfPlayers.push(msg.sender);
    }

    function endLottery()
        public
        onlyOwner
    {
        require(lottery_state == LOTTERY_STATE.OPEN, "Can't end!");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER);
        _randomResult = randomness;
    }

    function payout()
        public
        payable
        onlyOwner
    {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER);

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

        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function drawNumbers()
        internal
        onlyOwner
    {
        // TODO: da je lokalan niz _allNumber su ovoj fji
        // TODO LOCAL: require(_randomResult > 0, "random-not-found");
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER);
        require(_drawnNumbers.length == 0); // drawNumbers() cannot be called more than once
        
        _allNumbers = get48();
        uint256 n = 35;

        // Get 35 randomNumbers from randomValue
        uint256[] memory randomNumbers = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            randomNumbers[i] = uint256(keccak256(abi.encode(_randomResult, i)));
        }

        for (uint256 i = 48; i != 13; i--) {
            n = randomNumbers[(i - 1) - 13] % i;
            // Push drawn number to list
            _drawnNumbers.push(_allNumbers[n]);
            // Remove number we just added to _drawnNumbers from _allNumbers
            _allNumbers = removeByIndex(n, _allNumbers);
        }
    }

    function emptyMap()
        public
        onlyOwner
    {
        for(uint256 i=0; i<listOfPlayers.length; i++){
            deletePlayer(listOfPlayers[i]);
        }
        delete(listOfPlayers);
    }

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
            // If Ticket[i] won lottery, he gained xBonus[i] * Ticket[i].bet
            if(x != -1)
                sum += xBonus[uint(x)] * players[player][i].bet;
        }
        return sum;
    }

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

    function checkIfValid(uint256[6] memory _combination)
        internal
        pure 
        returns(bool)
    {
        for(uint256 i=0; i<_combination.length; i++){
            // Check if number is between 1 and 48
            if(_combination[i] < 1 || _combination[i] > 48)
                return false;

            // Check if number is unique
            for(uint256 j=i+1; j<_combination.length; j++){
                if(_combination[i] == _combination[j])
                    return false;
            }
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

    function getListOfPlayers()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return listOfPlayers;
    }
}
