// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';
import { ILuckySix } from 'src/interfaces/ILuckySix.sol';
import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { Test } from 'forge-std/Test.sol';

contract TicketTest is Test, ILuckySix {

    GameInitForTesting setup;
    LuckySix game;
    uint256 ticketBet;

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        game = LuckySix(setup.game());

        ticketBet = setup.ticketBet() - game.platformFee();
    }

    function test__playTicket() public {
        uint256[6] memory combination = [uint256(1), 2, 3, 4, 5, 49]; 

        // Expect revert when lottery has not started
        vm.expectRevert(abi.encodeWithSelector(LotteryNotOpen.selector));
        game.playTicket{ value: ticketBet }(combination);

        setup.keeperPerform();

        // Expect revert on invalid combination
        vm.expectRevert(
            abi.encodeWithSelector(NotValidCombination.selector, combination)
        );
        game.playTicket{ value: ticketBet }(combination);

        // Expect revert when msg.value is lower than platform fee
        combination[5] = 48;
        uint256 invalidTicketBet = 1 gwei;
        vm.expectRevert(
            abi.encodeWithSelector(NotEnoughFunds.selector, invalidTicketBet)
        );
        game.playTicket{ value: invalidTicketBet }(combination);

        // Expect emit when everything is correct
        vm.expectEmit(true, false, false, true, address(game));
        emit TicketBought(address(this), 1, combination);
        game.playTicket{ value: ticketBet }(combination);
    }

    function test__getPayoutForTicket() public {
        uint256 ROUND_NUMBER = 0;
        uint256 WINNING_TICKET_INDEX = 0;
        uint256 NO_MATCHES_TICKET_INDEX = 1;
        uint256 LOSING_TICKET_INDEX = 2;
        uint256 WINNING_TICKET_MUTLIPLIER_INDEX = 6;
        uint256 invalidRoundNumber = 10000;
        uint256 invalidTicketNumber = 10000;

        // Expect emit when cashing out valid ticket with WINNING_TICKET_MUTLIPLIER_INDEX
        vm.expectEmit(true, false, false, true, address(game));
        emit TicketCashedOut(address(setup), ROUND_NUMBER, WINNING_TICKET_INDEX, ticketBet * WINNING_TICKET_MUTLIPLIER_INDEX);
        setup.getPayoutForTicket(ROUND_NUMBER, WINNING_TICKET_INDEX);

        // Expect emit when cashing out ticket with 0 matches
        vm.expectEmit(true, false, false, true, address(game));
        emit TicketCashedOut(address(setup), ROUND_NUMBER, NO_MATCHES_TICKET_INDEX, ticketBet * 100);
        setup.getPayoutForTicket(ROUND_NUMBER, NO_MATCHES_TICKET_INDEX);

        // Expect revert when double cashing out the same ticket
        vm.expectRevert(
            abi.encodeWithSelector(TicketAlreadyCashed.selector, ROUND_NUMBER, WINNING_TICKET_INDEX)
        );
        setup.getPayoutForTicket(ROUND_NUMBER, WINNING_TICKET_INDEX);

        // Expect revert when passing invalid round number
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTicket.selector, invalidRoundNumber, WINNING_TICKET_INDEX)
        );
        setup.getPayoutForTicket(invalidRoundNumber, WINNING_TICKET_INDEX);

        // Expect revert when passing invalid ticket number
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTicket.selector, ROUND_NUMBER, invalidTicketNumber)
        );
        setup.getPayoutForTicket(ROUND_NUMBER, invalidTicketNumber);

        // Expect revert when passing ticket that has not won
        vm.expectRevert(
            abi.encodeWithSelector(TicketNotWinning.selector, ROUND_NUMBER, LOSING_TICKET_INDEX)
        );
        setup.getPayoutForTicket(ROUND_NUMBER, LOSING_TICKET_INDEX);
    }

}