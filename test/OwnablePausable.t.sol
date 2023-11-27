// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import '@oz-upgradeable/access/OwnableUpgradeable.sol';
import '@oz-upgradeable/utils/PausableUpgradeable.sol';

import { GameInitForTesting } from './helpers/GameInitForTesting.sol';
import { LuckySix } from 'src/LuckySix.sol';
import { IMockKeeper } from './helpers/MockKeeper.sol';
import { Test } from 'forge-std/Test.sol';

contract OwnablePausableTest is Test {
    
    GameInitForTesting setup;
    LuckySix game;

    function setUp() public {
        setup = (new GameInitForTesting){ value: 100 ether }();
        game = LuckySix(setup.game());
    }

    function test__Ownable() public {
        // Expect `OwnableUnauthorizedAccount` when calling with unauthorized access
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this)));
        game.withdrawPlatformFee();

        // Sets `msg.sender` to the specified address for the next call
        vm.prank(address(setup));
        game.withdrawPlatformFee();
    }

    function test__Pausable() public {
        // Expect the contract to emit `Paused` when the `owner` pauses it
        vm.prank(address(setup));
        vm.expectEmit(false, false, false, true, address(game));
        emit PausableUpgradeable.Paused(address(setup));
        game.pause();

        // Expect the contract to revert with `EnforcedPause` 
        vm.expectRevert(abi.encodeWithSelector(PausableUpgradeable.EnforcedPause.selector));
        setup.keeperCheck();

        // Expect the contract to emit `Unpaused` when the `owner` unpauses it
        vm.prank(address(setup));
        vm.expectEmit(false, false, false, true, address(game));
        emit PausableUpgradeable.Unpaused(address(setup));
        game.unpause();
    }
}