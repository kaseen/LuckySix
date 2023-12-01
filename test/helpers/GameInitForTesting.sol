// SPDX-License-Identifier: Apache-2.0
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

    constructor() payable {
        mockVrfCoordinator = new MockVRFCoordinator();
        mockKeeper = new MockKeeper();

        deployGame(msg.value - 10 ether);
        mockKeeper.setLuckySixAddress(address(game));

        initGame();
    }

    receive() payable external {}

    function deployGame(uint256 balance) public {
        implementation = new LuckySix();
        proxy = new UUPSProxy(address(implementation), "");
        game = LuckySix(payable(address(proxy)));

        payable(address(game)).transfer(balance);

        game.initialize(address(mockVrfCoordinator), 0, 0);
        game.setKeeperAddress(address(mockKeeper));
    }

    function initGame() public {
        keeperCheck();          // READY
        game.playTicket{ value: ticketBet }([5, 6, 7, 8, 9, 18]);       // winning combination with index 6
        game.playTicket{ value: ticketBet }([2, 5, 6, 7, 29, 30]);      // combination with 2 jokers
        game.playTicket{ value: ticketBet }([1, 4, 10, 15, 16, 20]);    // combination with 0 matches
        game.playTicket{ value: ticketBet }([1, 2, 3, 4, 5, 6]);        // losing combination
        skip(game.roundDuration() + 1);
        keeperCheck();          // DRAWING
        keeperCheck();          // CLOSED
    }

    function keeperCheck() public {
        mockKeeper.checkUpkeep();
    }

    function getPayoutForTicket(uint256 round, uint256 index) public {
        game.getPayoutForTicket(round, index);
    }
}