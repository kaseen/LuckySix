// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { LuckySix } from 'src/LuckySix.sol';
import { ILuckySix } from 'src/interfaces/ILuckySix.sol';
import 'forge-std/Test.sol';
import 'forge-std/console.sol';

contract LuckySixTest is Test, ILuckySix {

    LuckySix public luckySixContract;
    uint256 platformFee;
    uint256 ticketBet = 1 ether;

    receive() payable external {}

    function setUp() public {
        luckySixContract = new LuckySix(0, address(this));
        platformFee = luckySixContract.platformFee();
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
        emit TicketBought(address(this), 1, combination);
        luckySixContract.enterLottery{ value: ticketBet }(combination);

        combination[0] = 0;
        vm.expectRevert(bytes('Not valid combination.'));
        luckySixContract.enterLottery(combination);
    }

    function testDrawNumbers() public {
        luckySixContract.startLottery();
        luckySixContract.enterLottery{ value: ticketBet }([uint256(1), 2, 3, 4, 5, 6]);
        luckySixContract.enterLottery{ value: ticketBet }([uint256(1), 11, 21, 31, 41, 48]);
        luckySixContract.enterLottery{ value: ticketBet }([uint256(16), 46, 22, 11, 3, 40]);

        vm.expectEmit(true, true, true, true, address(luckySixContract));
        emit LotteryEnded(1);
        luckySixContract.endLotteryForLocalTesting();
    }

    function testGetPayoutForTicket() public {
        testDrawNumbers();

        uint256 platformBalance = luckySixContract.platformBalance();

        vm.expectRevert(bytes('Ticket not valid.'));
        luckySixContract.getPayoutForTicket(1, 0);

        vm.expectEmit(true, true, true, true, address(luckySixContract));
        emit TicketCashedOut(address(this), 1, 2, platformBalance);
        luckySixContract.getPayoutForTicket(1, 2);

        vm.expectRevert(bytes('Ticket already cashed out.'));
        luckySixContract.getPayoutForTicket(1, 2);
    }
}