// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';
import { ILuckySix } from 'src/interfaces/ILuckySix.sol';
import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { Test } from 'forge-std/Test.sol';

contract LotteryStateTest is Test, ILuckySix {

    GameInitForTesting setup;
    LuckySix game;
    uint256 ticketBet = 1 ether;

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        game = LuckySix(setup.game());
    }

    function assertEq(LOTTERY_STATE a, LOTTERY_STATE b) internal virtual {
        assertEq(uint256(a), uint256(b));
    }

    function test__openRound() public {
        vm.expectEmit(false, false, false, true);
        emit GameRoundOpened(1);
        setup.keeperPerform();

        assertEq(LOTTERY_STATE.READY, game.lotteryState());
    }

    function test__startCountdown() public {
        test__openRound();
        uint8[6] memory winningCombination = [3, 4, 5, 8, 9, 10];
        uint8[6] memory losingCombination = [3, 4, 5, 8, 9, 14];

        vm.expectEmit(false, false, false, true, address(game));
        emit GameStarted(1);
        game.playTicket{ value: ticketBet }(winningCombination);
        game.playTicket{ value: ticketBet }(losingCombination);

        assertEq(LOTTERY_STATE.STARTED, game.lotteryState());
    }

    function test__drawNumbers() public {
        test__startCountdown();
        skip(game.roundDuration() + 1);

        vm.expectEmit(false, false, false, true, address(game));
        emit GameRequestRandomNumber(0);
        setup.keeperPerform();      
        
        assertEq(LOTTERY_STATE.DRAWING, game.lotteryState());
    }

    function test__endRound() public {
        test__drawNumbers();
        
        vm.expectEmit(false, false, false, true, address(game));
        emit GameRoundEnded(1);
        setup.keeperPerform();

        assertEq(LOTTERY_STATE.CLOSED, game.lotteryState());
    }

    function test__openRound2() public {
        test__endRound();

        vm.expectEmit(false, false, false, true, address(game));
        emit GameRoundOpened(2);
        setup.keeperPerform();

        assertEq(LOTTERY_STATE.READY, game.lotteryState());
    }

}