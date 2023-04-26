// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { LuckySix } from 'src/LuckySix.sol';

interface Events {
    event LotteryStarted(uint256 numOfRound);
    event LotteryEnded(uint256 numOfRound);
    event TickedBought(address indexed player, uint256 numOfRound, uint256[6] combination);
}

contract LuckySixTest is Test, Events {

    LuckySix public luckySixContract;

    function setUp() public {
        luckySixContract = new LuckySix(0, address(this));
    }

    function testStartLottery() public {
        vm.expectEmit(true, true, true, true, address(luckySixContract));
        emit LotteryStarted(1);

        luckySixContract.startLottery();	
    }

    function testEnterLottery(uint256[6] memory input) public {
        vm.assume(input[0] > 0);
        vm.assume(input[1] > 1000);
        vm.assume(input[2] > 1000000);
        vm.assume(input[3] > 1000000000);
        vm.assume(input[4] > 1000000000000);

        testStartLottery();
        uint256[6] memory combination = [
            uint256(input[0] % 8 + 1),
            input[1] % 8 + 1 * 8 + 1,
            input[2] % 8 + 2 * 8 + 1,
            input[3] % 8 + 3 * 8 + 1,
            input[4] % 8 + 4 * 8 + 1,
            input[5] % 8 + 5 * 8 + 1
        ];

        vm.expectEmit(true, true, true, true, address(luckySixContract));
        emit TickedBought(address(this), 1, combination);
        luckySixContract.enterLottery{ value: 1 ether }(combination);

        combination[0] = 0;
        vm.expectRevert(bytes('Not valid combination'));
        luckySixContract.enterLottery(combination);
    }

    function testDrawNumbers() public {
        luckySixContract.startLottery();
        luckySixContract.enterLottery{ value: 1 ether }([uint256(1), 2, 3, 4, 5, 6]);
		luckySixContract.enterLottery{ value: 1 ether }([uint256(1), 11, 21, 31, 41, 48]);
		luckySixContract.enterLottery{ value: 1 ether }([uint256(5), 10, 15, 20, 25, 30]);

        luckySixContract.endLottery();

        vm.expectEmit(true, true, true, true, address(luckySixContract));
        emit LotteryEnded(1);
        //luckySixContract.localTest();
    }
}