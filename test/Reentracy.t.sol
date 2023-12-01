// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import { MockVRFCoordinator } from './helpers/MockVRFCoordinator.sol';
import { MockKeeper } from './helpers/MockKeeper.sol';
import { ERC1967Proxy } from '@oz/proxy/ERC1967/ERC1967Proxy.sol';
import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { LuckySix } from 'src/LuckySix.sol';
import { Test } from 'forge-std/Test.sol';

contract ReentracyTest is Test {

    MockVRFCoordinator immutable mockVrfCoordinator;
    MockKeeper immutable mockKeeper;

    LuckySix implementation;
    ERC1967Proxy proxy;
    LuckySix public game;

    uint256 public ticketBet = 0.1 ether;
    uint256 amountToReedeem;

    constructor() {
        mockVrfCoordinator = new MockVRFCoordinator();
        mockKeeper = new MockKeeper();
    }
    
    function setUp() public {
        // Deploy
        implementation = new LuckySix();
        proxy = new ERC1967Proxy(address(implementation), "");
        game = LuckySix(payable(address(proxy)));
        payable(address(game)).transfer(50 ether);
        game.initialize(address(mockVrfCoordinator), 0, 0);
        game.setKeeperAddress(address(mockKeeper));

        // Initialize game
        mockKeeper.setLuckySixAddress(address(game));
        mockKeeper.checkUpkeep();          // READY
        game.playTicket{ value: ticketBet }([5, 6, 7, 8, 9, 18]);
        skip(game.roundDuration() + 1);
        mockKeeper.checkUpkeep();          // DRAWING
        mockKeeper.checkUpkeep();          // CLOSED

        ticketBet = ticketBet - game.platformFee();
        amountToReedeem = ticketBet * 6;
    }

    /**
     * @dev A reentrancy attack would work if we were to comment out the `nonReentrant`
     *      modifier in the `getPayoutForTicket` function.
     */
    receive() payable external {
        if(address(game).balance > amountToReedeem){
            game.getPayoutForTicket(0, 0);          
        }
    }

    function test__ReentracyAttack() public payable {
        // Expect the contract to revert with `ReentrancyGuardReentrantCall`
        vm.expectRevert();
        game.getPayoutForTicket(0, 0);
    }

}