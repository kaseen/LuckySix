// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';
import { ILuckySix } from 'src/interfaces/ILuckySix.sol';
import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { Test } from 'forge-std/Test.sol';

contract TicketTest is Test, ILuckySix {

    GameInitForTesting setup;
    LuckySix game;
    uint256 ticketBet = 1 ether;

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        game = LuckySix(setup.game());
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
        // Expect emit when cashing out valid ticket
        vm.expectEmit(true, false, false, true, address(game));
        emit TicketCashedOut(address(setup), 0, 0, game.platformBalance());
        setup.getPayoutForTicket(0, 0);

        // Expect revert when double cashing out the same ticket
        vm.expectRevert(
            abi.encodeWithSelector(TicketAlreadyCashed.selector, 0, 0)
        );
        setup.getPayoutForTicket(0, 0);

        // Expect revert when passing invalid round number
        uint256 invalidRoundNumber = 10000;
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTicket.selector, invalidRoundNumber, 0)
        );
        setup.getPayoutForTicket(invalidRoundNumber, 0);

        // Expect revert when passing invalid ticket number
        uint256 invalidTicketNumber = 10000;
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTicket.selector, 0, invalidTicketNumber)
        );
        setup.getPayoutForTicket(0, invalidTicketNumber);

        // Expect revert when passing ticket that has not won
        vm.expectRevert(
            abi.encodeWithSelector(TicketNotWinning.selector, 0, 1)
        );
        setup.getPayoutForTicket(0, 1);
    }

}