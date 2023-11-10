// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';
import { ILuckySix } from 'src/interfaces/ILuckySix.sol';
import { MockVRFCoordinator } from './MockVRFCoordinator.sol';
import { Test } from 'forge-std/Test.sol';

contract LuckySixTest is Test, ILuckySix {

    LuckySix immutable game;
    MockVRFCoordinator immutable mockVrfCoordinator;
    uint256 platformFee;
    uint256 ticketBet = 1 ether;

    receive() payable external {}

    constructor() {
        mockVrfCoordinator = new MockVRFCoordinator();
        game = new LuckySix(0, address(mockVrfCoordinator), address(this));
    }

    function setUp() public {
        platformFee = game.platformFee();
    }

    function assertEq(LOTTERY_STATE a, LOTTERY_STATE b) internal virtual {
        assertEq(uint256(a), uint256(b));
    }

    function test__openRound() public {
        vm.expectEmit(false, false, false, true, address(game));
        emit GameRoundOpened(0);
        game.performUpkeep(hex"");

        assertEq(LOTTERY_STATE.READY, game.lotteryState());
    }

    function test__startCountdown() public {
        test__openRound();
        uint256[6] memory combination = [uint256(3), 4, 5, 8, 9, 11];

        vm.expectEmit(false, false, false, true, address(game));
        emit GameStarted(0);
        vm.expectEmit(true, false, false, true, address(game));
        emit TicketBought(address(this), 0, combination);
        game.playTicket{ value: ticketBet }(combination);

        assertEq(LOTTERY_STATE.STARTED, game.lotteryState());
    }

    function test__drawNumbers() public {
        test__startCountdown();
        skip(game.roundDuration() + 1);

        vm.expectEmit(false, false, false, true, address(game));
        emit GameRequestRandomNumber(0);
        game.performUpkeep(hex"");      
        
        assertEq(LOTTERY_STATE.DRAWING, game.lotteryState());
    }

    function test__endRound() public {
        test__drawNumbers();
        
        vm.expectEmit(false, false, false, true, address(game));
        emit GameRoundEnded(0);
        game.performUpkeep(hex"");

        assertEq(LOTTERY_STATE.CLOSED, game.lotteryState());
    }

    function test__openRound2() public {
        test__endRound();

        vm.expectEmit(false, false, false, true, address(game));
        emit GameRoundOpened(1);
        game.performUpkeep(hex"");

        assertEq(LOTTERY_STATE.READY, game.lotteryState());
    }

    function test__getPayoutForTicket() public {
        test__openRound2();

        vm.expectEmit(true, false, false, true, address(game));
        emit TicketCashedOut(address(this), 0, 0, 990000000000000000);
        game.getPayoutForTicket(0, 0);
    }
}