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

    uint256 ticketBet = 1 ether;

    constructor() payable {
        mockVrfCoordinator = new MockVRFCoordinator();
        mockKeeper = new MockKeeper();

        deployGame();
        initGame();
    }

    receive() payable external {}

    function deployGame() public {
        implementation = new LuckySix();
        proxy = new UUPSProxy(address(implementation), "");
        game = LuckySix(address(proxy));

        game.initialize(0, address(mockVrfCoordinator), address(mockKeeper));
    }

    function initGame() public {
        keeperPerform();    // READY
        game.playTicket{ value: ticketBet }([uint256(3), 4, 5, 8, 9, 10]);  // winning combination
        game.playTicket{ value: ticketBet }([uint256(1), 2, 3, 4, 5, 6]);   // losing combination
        game.playTicket{ value: ticketBet }([uint256(1), 2, 3, 4, 5, 6]);   // losing combination
        skip(game.roundDuration() + 1);
        keeperPerform();    // DRAWING
        keeperPerform();    // CLOSED
    }

    function keeperPerform() public {
        mockKeeper.performUpkeep(address(game));
    }

    function getPayoutForTicket(uint256 round, uint256 index) public {
        game.getPayoutForTicket(round, index);
    }
}