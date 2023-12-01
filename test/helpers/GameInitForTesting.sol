// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import { ERC1967Proxy } from '@oz/proxy/ERC1967/ERC1967Proxy.sol';
import { MockVRFCoordinator } from './MockVRFCoordinator.sol';
import { MockKeeper } from './MockKeeper.sol';
import { LuckySix } from 'src/LuckySix.sol';
import { Test } from 'forge-std/Test.sol';

contract GameInitForTesting is Test {

    MockVRFCoordinator immutable mockVrfCoordinator;
    MockKeeper immutable mockKeeper;

    LuckySix implementation;
    LuckySix public game;
    ERC1967Proxy public proxy;

    uint256 public ticketBet = 0.1 ether;

    uint256 public SETUP_ROUND_NUMBER = 0;
    uint256 public WINNING_TICKET_INDEX = 0;
    uint256 public WINNING_TICKET_MUTLIPLIER = 6;

    /**
     * @dev Initialize mock contracts for Chainlink services and deploy the game, ensuring
     *      all necessary components are properly set up for functioning.
     */
    constructor() payable {
        mockVrfCoordinator = new MockVRFCoordinator();
        mockKeeper = new MockKeeper();

        deployGame(msg.value - 10 ether);
        mockKeeper.setLuckySixAddress(address(game));

        initGame();
    }

    receive() payable external {}

    /**
     * @dev Deploy the implementation code and proxy contract, associate the game with the
     *      proxy address, and proceed to initialize the game.
     */
    function deployGame(uint256 balance) public {
        implementation = new LuckySix();
        proxy = new ERC1967Proxy(address(implementation), "");
        game = LuckySix(payable(address(proxy)));

        payable(address(game)).transfer(balance);

        game.initialize(address(mockVrfCoordinator), 0, 0);
        game.setKeeperAddress(address(mockKeeper));
    }

    /**
     * @dev Initialize the game so that the first round is completed, and the ticket with
     *      the index `WINNING_TICKET_INDEX` can redeem the prize.
     */
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