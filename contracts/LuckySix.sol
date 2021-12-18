// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract LuckySix is VRFConsumerBase {
    // TODO: LuckySix is Ownable

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public _randomResult;

    uint256[] internal _allNumbers;
    uint256[] public _drawnNumbers;
    uint256[] public xBonus = [0, 0, 0, 0, 0, 10000, 7500, 5000, 2500, 1000, 500, 300, 200, 150, 100, 90, 80, 70, 60, 50, 40, 30, 25, 20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

    mapping(address => Ticket[]) public players;

    struct Ticket{
        uint256[6] combination;
        uint256 bet;
    }

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyhash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyhash;
        fee = _fee;
    }

    function getRandomNumber()
        public
        returns (bytes32 requestId)
    {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        // TODO: require(randomness > 0, "random-not-found");
        _randomResult = randomness;
    }

    function enterLottery(uint256[6] memory _combination, uint256 _bet)
        public
        payable
    {
        players[msg.sender].push(Ticket({combination: _combination, bet: _bet}));
    }

    function drawNumbers() public {
        // TODO: prvo da je _randomResult>0
        // TODO: SAMO JEDNOM SME DA SE POZOVE
        // TODO: da je lokalan niz _allNumber su ovoj fji

        // set _allNumbers to [1, 2, 3, ..., 48]
        _allNumbers = get48();
        uint256 n = 35;

        // get 35 randomNumbers from randomValue
        uint256[] memory randomNumbers = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            randomNumbers[i] = uint256(keccak256(abi.encode(_randomResult, i)));
        }

        for (uint256 i = 48; i != 13; i--) {
            // n is now index of number to pick from _allNumbers list
            n = randomNumbers[(i - 1) - 13] % i;
            // push drawn number to list
            _drawnNumbers.push(_allNumbers[n]);
            // remove number we just added to _drawnNumbers from _allNumbers
            _allNumbers = removeByIndex(n, _allNumbers);
        }
    }

    function cashEarned(address player)
        public
        view
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
            tmp[i - 1] = array[i];
        }
        return tmp;
    }

    function returnIndexOfLastDrawnNumber(uint256[6] memory numbers)
        public
        view
        returns (int256)
    {
        // TODO: mora prvo da su izvuceni brojevi
        // TODO: mora da su memory numbers 6 broja
        // TODO: mora da su brojevi izmedju 1 i 48
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

    function getTickets(address player)
        public
        view
        returns(Ticket[] memory)
    {
        return players[player];
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
}
