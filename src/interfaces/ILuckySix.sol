// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ILuckySix {

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    struct Ticket {
        uint256[6] combination;
        uint256 bet;
    }

    event LotteryStarted(uint256 numOfRound);
    event LotteryEnded(uint256 numOfRound);
    event TicketBought(address indexed player, uint256 numOfRound, uint256[6] combination);
    event TicketCashedOut(address indexed player, uint256 numOfRound, uint256 indexOfTicket, uint256 amount);
    event PlatformFeeChanged(uint256 newAmount);

    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId);
}