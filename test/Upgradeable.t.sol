// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import { ERC1967Utils, ERC1967Proxy } from '@oz/proxy/ERC1967/ERC1967Proxy.sol';
import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { LuckySix, ILuckySix } from 'src/LuckySix.sol';
import { Test } from 'forge-std/Test.sol';

contract LuckySixV2 is LuckySix {
    uint256 public newVariable;

    // Reinitialize version v2 with reinitializer(2)
    function initializeV2(uint256 _newVariable) reinitializer(2) public {
        newVariable = _newVariable;
    }

    function getNewVariable() public view returns (uint256) {
        return newVariable;
    }
}

contract UpgradeableTest is Test {

    LuckySix gameV1;
    LuckySixV2 gameV2;
    ERC1967Proxy proxy;
    
    GameInitForTesting setup;
    uint256 ticketBet;

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        gameV1 = setup.game();
        proxy = setup.proxy();
        ticketBet = setup.ticketBet() - gameV1.platformFee();
    }

    // Used to measure deployment cost of LuckySix contract
    function test__deployV1() public {
        LuckySix implementation = new LuckySix();
        ERC1967Proxy uups = new ERC1967Proxy(address(implementation), "");
        LuckySix game = LuckySix(payable(address(uups)));
        game.initialize(address(this), 0, 0);
    }

    function test__upgrade() public {
        LuckySixV2 implementationV2 = new LuckySixV2();

        vm.prank(address(setup));

        // Expect `Upgraded` when upgrading contract
        vm.expectEmit(true, false, false, true, address(proxy));
        emit ERC1967Utils.Upgraded(address(implementationV2));
        gameV1.upgradeToAndCall(address(implementationV2), "");

        // Rewrap the proxy and initialize
        gameV2 = LuckySixV2(payable(address(proxy)));
        gameV2.initializeV2(1234);
        
        assertEq(gameV2.platformFee(), 0.01 ether);
        assertEq(gameV2.getNewVariable(), 1234);
    }

    function test__getPayoutForTicketUpgradable() public {
        test__upgrade();

        uint256 balanceBefore = address(setup).balance;

        uint256 ROUND_NUMBER = setup.SETUP_ROUND_NUMBER();
        uint256 WINNING_TICKET_INDEX = setup.WINNING_TICKET_INDEX();
        uint256 WINNING_TICKET_MUTLIPLIER = setup.WINNING_TICKET_MUTLIPLIER();

        vm.startPrank(address(setup));

        // Expect `TicketCashedOut` when cashing out valid ticket with WINNING_TICKET_MUTLIPLIER_INDEX
        vm.expectEmit(true, false, false, true, address(gameV2));
        emit ILuckySix.TicketCashedOut(address(setup), ROUND_NUMBER, WINNING_TICKET_INDEX, ticketBet * WINNING_TICKET_MUTLIPLIER);
        gameV2.getPayoutForTicket(setup.SETUP_ROUND_NUMBER(), setup.WINNING_TICKET_INDEX());
        
        // Ensure that the balance is correct after redeeming the prize.
        assertEq(balanceBefore + ticketBet * setup.WINNING_TICKET_MUTLIPLIER(), address(setup).balance);

        vm.stopPrank();
    }
}