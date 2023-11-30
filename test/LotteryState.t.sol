// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { LuckySix } from 'src/LuckySix.sol';
import { ILuckySix } from 'src/interfaces/ILuckySix.sol';
import { IMockKeeper } from './helpers/MockKeeper.sol';
import { Test } from 'forge-std/Test.sol';

contract LotteryStateTest is Test {

    GameInitForTesting setup;
    LuckySix game;
    uint256 ticketBet = 1 ether;

    enum LOTTERY_STATE { READY, STARTED, CALCULATING, DRAWING, CLOSED }

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        game = LuckySix(setup.game());
    }

    function assertEq(LOTTERY_STATE a, LOTTERY_STATE b) internal virtual {
        assertEq(uint256(a), uint256(b));
    }

    function test__openRound() public {
        vm.expectEmit(false, false, false, true);
        emit ILuckySix.GameRoundOpened(1);
        setup.keeperCheck();

        assertEq(uint256(LOTTERY_STATE.READY), uint256(game.lotteryState()));
    }

    function test__startCountdown() public {
        test__openRound();
        uint8[6] memory winningCombination = [3, 4, 5, 8, 9, 10];
        uint8[6] memory losingCombination = [3, 4, 5, 8, 9, 14];

        vm.expectEmit(false, false, false, true, address(game));
        emit ILuckySix.GameStarted(1);
        game.playTicket{ value: ticketBet }(winningCombination);
        game.playTicket{ value: ticketBet }(losingCombination);

        assertEq(uint256(LOTTERY_STATE.STARTED), uint256(game.lotteryState()));
    }

    function test__drawNumbers() public {
        test__startCountdown();

        vm.expectRevert(abi.encodeWithSelector(IMockKeeper.UpkeepNotNeeded.selector));
        setup.keeperCheck();

        skip(game.roundDuration() + 1);

        vm.expectEmit(false, false, false, true, address(game));
        emit ILuckySix.GameRequestRandomNumber(0);
        setup.keeperCheck();

        assertEq(uint256(LOTTERY_STATE.DRAWING), uint256(game.lotteryState()));
    }

    function test__endRound() public {
        test__drawNumbers();
        
        vm.expectEmit(false, false, false, true, address(game));
        emit ILuckySix.GameRoundEnded(1);
        setup.keeperCheck();

        assertEq(uint256(LOTTERY_STATE.CLOSED), uint256(game.lotteryState()));
    }

    function test__openRound2() public {
        test__endRound();

        vm.expectEmit(false, false, false, true, address(game));
        emit ILuckySix.GameRoundOpened(2);
        setup.keeperCheck();

        assertEq(uint256(LOTTERY_STATE.READY), uint256(game.lotteryState()));
    }

}