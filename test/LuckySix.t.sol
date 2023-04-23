// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import { LuckySix } from 'src/LuckySix.sol';

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
        vm.expectEmit(true, true, true, true, address(luckySixContract));
        emit LotteryStarted(1);

        luckySixContract.startLottery();	
    }

    function testEnterLottery(uint256[6] memory input) public {
        vm.assume(input[0] != input[1]);
        vm.assume(input[1] != input[2]);
        vm.assume(input[2] != input[3]);
        vm.assume(input[3] != input[4]);
        vm.assume(input[4] != input[5]);

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

        luckySixContract.enterLottery(combination);

        combination[0] = 0;
        vm.expectRevert(bytes('Not valid combination'));
        luckySixContract.enterLottery(combination);
    }

    function testDrawNumbers() public {
        testEnterLottery([uint256(1), 2, 3, 4, 5, 6]);

        vm.expectRevert(bytes('Lottery has not ended'));
        luckySixContract.drawNumbers();

        luckySixContract.endLottery();
        luckySixContract.drawNumbers();
    }
}