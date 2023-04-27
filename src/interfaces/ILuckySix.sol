// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ILuckySix {

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    struct Ticket{
        uint256[6] combination;
        uint256 bet;
    }

    event LotteryStarted(uint256 numOfRound);
    event LotteryEnded(uint256 numOfRound);
    event TickedBought(address indexed player, uint256 numOfRound, uint256[6] combination);

    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId);

}