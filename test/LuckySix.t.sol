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
        uint256[6] memory winningCombination = [uint256(3), 4, 5, 8, 9, 10];
        uint256[6] memory losingCombination = [uint256(3), 4, 5, 8, 9, 14];

        vm.expectEmit(false, false, false, true, address(game));
        emit GameStarted(0);
        game.playTicket{ value: ticketBet }(winningCombination);
        game.playTicket{ value: ticketBet }(losingCombination);

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

    function test__playTicket() public {
        uint256[6] memory combination = [uint256(1), 2, 3, 4, 5, 49]; 

        // Expect revert when lottery has not started
        vm.expectRevert(abi.encodeWithSelector(LotteryNotOpen.selector));
        game.playTicket{ value: ticketBet }(combination);

        test__startCountdown();

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
        emit TicketBought(address(this), 0, combination);
        game.playTicket{ value: ticketBet }(combination);
    }

    function test__getPayoutForTicket() public {
        test__openRound2();

        // Expect emit when cashing out valid ticket
        vm.expectEmit(true, false, false, true, address(game));
        emit TicketCashedOut(address(this), 0, 0, 2 ether - 2*platformFee);
        game.getPayoutForTicket(0, 0);

        // Expect revert when double cashing out the same ticket
        vm.expectRevert(
            abi.encodeWithSelector(TicketAlreadyCashed.selector, 0, 0)
        );
        game.getPayoutForTicket(0, 0);

        // Expect revert when passing invalid round number
        uint256 invalidRoundNumber = 10000;
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTicket.selector, invalidRoundNumber, 0)
        );
        game.getPayoutForTicket(invalidRoundNumber, 0);

        // Expect revert when passing invalid ticket number
        uint256 invalidTicketNumber = 10000;
        vm.expectRevert(
            abi.encodeWithSelector(InvalidTicket.selector, 0, invalidTicketNumber)
        );
        game.getPayoutForTicket(0, invalidTicketNumber);

        // Expect revert when passing ticket that has not won
        vm.expectRevert(
            abi.encodeWithSelector(TicketNotWinning.selector, 0, 1)
        );
        game.getPayoutForTicket(0, 1);
    }
}
