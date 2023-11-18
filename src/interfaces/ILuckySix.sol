// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ILuckySix {

    enum LOTTERY_STATE {
        READY,                  // GameOpened
        STARTED,                // GameStarted
        CALCULATING,            // GameRequestRandomNumber
        DRAWING,                // GameRandomNumberFulfilled
        CLOSED                  // GameRoundEnded
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

    event GameRoundOpened(uint256);
    event GameStarted(uint256);
    event GameRequestRandomNumber(uint256);
    event GameRandomNumberFulfilled(uint256);
    event GameRoundEnded(uint256);

    event TicketBought(address indexed player, uint256 numOfRound, uint256[6] combination);
    event TicketCashedOut(address indexed player, uint256 numOfRound, uint256 indexOfTicket, uint256 amount);
    event PlatformFeeChanged(uint256 newAmount);

    error LotteryNotClosed();
    error LotteryNotOpen();
    error LotteryNotStarted();
    error LotteryNotEnded();
    error LotteryNotDrawn();
    
    error UnauthorizedAccess();
    error NotValidCombination(uint256[6]);
    error NotEnoughFunds(uint256);
    error InvalidTicket(uint256, uint256);
    error TicketAlreadyCashed(uint256, uint256);
    error TicketNotWinning(uint256, uint256);
}
