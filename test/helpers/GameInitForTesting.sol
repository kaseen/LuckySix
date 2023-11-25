// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { MockVRFCoordinator } from './MockVRFCoordinator.sol';
import { MockKeeper } from './MockKeeper.sol';
import { LuckySix, UUPSProxy } from 'src/LuckySix.sol';
import { Test } from 'forge-std/Test.sol';

contract GameInitForTesting is Test {

    MockVRFCoordinator immutable mockVrfCoordinator;
    MockKeeper immutable mockKeeper;

    LuckySix implementation;
    LuckySix public game;
    UUPSProxy proxy;

    uint256 public ticketBet = 0.1 ether;

    bytes4 public openRoundSelector = 0xe562dfd9;
    bytes4 public endRoundSelector = 0x749aa2d9;
    bytes4 public drawNumbersSelector = 0x676c902f;

    constructor() payable {
        mockVrfCoordinator = new MockVRFCoordinator();
        mockKeeper = new MockKeeper();

        deployGame(msg.value - 10 ether);
        initGame();
    }

    receive() payable external {}

    function deployGame(uint256 balance) public {
        implementation = new LuckySix();
        proxy = new UUPSProxy(address(implementation), "");
        game = LuckySix(payable(address(proxy)));

        payable(address(game)).transfer(balance);

        game.initialize(0, address(mockVrfCoordinator), address(mockKeeper));
    }

    function initGame() public {
        keeperPerform(openRoundSelector);       // READY
        game.playTicket{ value: ticketBet }([5, 6, 7, 8, 9, 18]);       // winning combination with index 6
        game.playTicket{ value: ticketBet }([2, 5, 6, 7, 29, 30]);      // combination with 2 jokers
        game.playTicket{ value: ticketBet }([1, 4, 10, 15, 16, 20]);    // combination with 0 matches
        game.playTicket{ value: ticketBet }([1, 2, 3, 4, 5, 6]);        // losing combination
        skip(game.roundDuration() + 1);
        keeperPerform(endRoundSelector);        // DRAWING
        keeperPerform(drawNumbersSelector);     // CLOSED
    }

    function keeperCheck() public view {
        mockKeeper.checkUpkeep(address(game));
    }

    function keeperPerform(bytes4 selector) public {
        mockKeeper.performUpkeep(address(game), selector);
    }

    function getPayoutForTicket(uint256 round, uint256 index) public {
        game.getPayoutForTicket(round, index);
    }
}