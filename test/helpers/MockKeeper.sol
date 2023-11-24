// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';

contract MockKeeper {

    function performUpkeep(address game) public {
        LuckySix(game).performUpkeep(hex"");
    }

}