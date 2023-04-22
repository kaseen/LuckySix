// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import '../src/LuckySix.sol';

interface Events {
    event LotteryStarted(uint256 numOfRound);
    event TickedBought(address indexed player, uint256 numOfRound, uint256[6] combination);
}

contract LuckySixTest is Test, Events {

    LuckySix public luckySixContract;

    function setUp() public {
        luckySixContract = new LuckySix(address(this), address(this), '0x', 0);
    }

    function testStartLottery() public {
        vm.expectEmit(false, false, false, false, address(luckySixContract));
        emit LotteryStarted(1);

        luckySixContract.startLottery();	
    }

    function testEnterLottery(uint256 x, uint256 y) public {
        testStartLottery();
        uint256[6] memory combination = [
            uint256(x % 8 + 1),
            y % 8 + 8 + 1,
            x % 8 + 2 * 8 + 1,
            y % 8 + 3 * 8 + 1,
            x % 8 + 4 * 8 + 1,
            y % 8 + 5 * 8 + 1
        ];

        vm.expectEmit(true, true, false, false, address(luckySixContract));
        emit TickedBought(address(this), 1, combination);

        luckySixContract.enterLottery(combination);
    }

    function testDrawNumbers() public {
        testEnterLottery(0, 1);
        luckySixContract.endLottery();
        luckySixContract.drawNumbers();
    }
}