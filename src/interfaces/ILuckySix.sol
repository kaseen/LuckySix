// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ILuckySix {

    enum LOTTERY_STATE {
        READY,
        STARTED,
        CALCULATING,
        DRAWING_NUMBERS,
        CLOSED
    }

    struct Round {
        uint256 numberOfRound;
        uint256 timeStarted;
        bool isStarted;
    }

    struct Ticket {
        uint256[6] combination;
        uint256 bet;
    }

    event RoundStarted(uint256 numOfRound);
    event CountdownStarted(uint256 numOfRound);
    event RequestForRandomNumberSent(uint256 requestId);
    event RandomNumberFulfilled(uint256 requestId);
    event RoundEnded(uint256 numOfRound);
    event TicketBought(address indexed player, uint256 numOfRound, uint256[6] combination);
    event TicketCashedOut(address indexed player, uint256 numOfRound, uint256 indexOfTicket, uint256 amount);
    event PlatformFeeChanged(uint256 newAmount);
}