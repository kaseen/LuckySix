// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { LuckySix, ILuckySix } from 'src/LuckySix.sol';
import { Test } from 'forge-std/Test.sol';

contract TicketTest is Test {

    GameInitForTesting setup;
    LuckySix game;
    uint256 ticketBet;

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        game = setup.game();

        ticketBet = setup.ticketBet() - game.platformFee();
    }

    function test__playTicket() public {
        uint8[6] memory combination = [1, 2, 3, 4, 5, 49]; 

        // Expect `LotteryNotOpen` when lottery has not started
        vm.expectRevert(abi.encodeWithSelector(ILuckySix.LotteryNotOpen.selector));
        game.playTicket{ value: ticketBet }(combination);

        setup.keeperCheck();

        // Expect `NotValidCombination` on invalid combination
        vm.expectRevert(
            abi.encodeWithSelector(ILuckySix.NotValidCombination.selector, combination)
        );
        game.playTicket{ value: ticketBet }(combination);

        // Expect `NotEnoughFunds` when msg.value is lower than platform fee
        combination[5] = 48;
        uint256 invalidTicketBet = 1 gwei;
        vm.expectRevert(
            abi.encodeWithSelector(ILuckySix.NotEnoughFunds.selector, invalidTicketBet)
        );
        game.playTicket{ value: invalidTicketBet }(combination);

        // Expect `TicketBought` when everything is correct
        vm.expectEmit(true, false, false, true, address(game));
        emit ILuckySix.TicketBought(address(this), 1, combination);
        game.playTicket{ value: ticketBet }(combination);
    }

    function test__getPayoutForTicket() public {
        uint256 ROUND_NUMBER = setup.SETUP_ROUND_NUMBER();
        uint256 WINNING_TICKET_INDEX = setup.WINNING_TICKET_INDEX();
        uint256 WINNING_TICKET_INDEX_WITH_JOKERS = 1;
        uint256 NO_MATCHES_TICKET_INDEX = 2;
        uint256 LOSING_TICKET_INDEX = 3;
        uint256 WINNING_TICKET_MUTLIPLIER = setup.WINNING_TICKET_MUTLIPLIER();
        uint256 invalidRoundNumber = 10000;
        uint256 invalidTicketNumber = 10000;

        // Expect `TicketCashedOut` when cashing out valid ticket with WINNING_TICKET_MUTLIPLIER_INDEX
        vm.expectEmit(true, false, false, true, address(game));
        emit ILuckySix.TicketCashedOut(address(setup), ROUND_NUMBER, WINNING_TICKET_INDEX, ticketBet * WINNING_TICKET_MUTLIPLIER);
        setup.getPayoutForTicket(ROUND_NUMBER, WINNING_TICKET_INDEX);

        // Expect `TicketCashedOut` when cashing out ticket with 2 jokers
        vm.expectEmit(true, false, false, true, address(game));
        emit ILuckySix.TicketCashedOut(address(setup), ROUND_NUMBER, WINNING_TICKET_INDEX_WITH_JOKERS, 4 * ticketBet * WINNING_TICKET_MUTLIPLIER);
        setup.getPayoutForTicket(ROUND_NUMBER, WINNING_TICKET_INDEX_WITH_JOKERS);

        // Expect `TicketCashedOut` when cashing out ticket with 0 matches
        vm.expectEmit(true, false, false, true, address(game));
        emit ILuckySix.TicketCashedOut(address(setup), ROUND_NUMBER, NO_MATCHES_TICKET_INDEX, ticketBet * 100);
        setup.getPayoutForTicket(ROUND_NUMBER, NO_MATCHES_TICKET_INDEX);

        // Expect `TicketAlreadyCashed` when double cashing out the same ticket
        vm.expectRevert(
            abi.encodeWithSelector(ILuckySix.TicketAlreadyCashed.selector, ROUND_NUMBER, WINNING_TICKET_INDEX)
        );
        setup.getPayoutForTicket(ROUND_NUMBER, WINNING_TICKET_INDEX);

        // Expect `InvalidTicket` when passing invalid round number
        vm.expectRevert(
            abi.encodeWithSelector(ILuckySix.InvalidTicket.selector, invalidRoundNumber, WINNING_TICKET_INDEX)
        );
        setup.getPayoutForTicket(invalidRoundNumber, WINNING_TICKET_INDEX);

        // Expect `InvalidTicket` when passing invalid ticket number
        vm.expectRevert(
            abi.encodeWithSelector(ILuckySix.InvalidTicket.selector, ROUND_NUMBER, invalidTicketNumber)
        );
        setup.getPayoutForTicket(ROUND_NUMBER, invalidTicketNumber);

        // Expect `TicketNotWinning` when passing ticket that has not won
        vm.expectRevert(
            abi.encodeWithSelector(ILuckySix.TicketNotWinning.selector, ROUND_NUMBER, LOSING_TICKET_INDEX)
        );
        setup.getPayoutForTicket(ROUND_NUMBER, LOSING_TICKET_INDEX);
    }

}