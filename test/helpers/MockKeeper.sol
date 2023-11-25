// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';

contract MockKeeper {

    function checkUpkeep(address game) public view {
        LuckySix(payable(game)).checkUpkeep(hex"");
    }

    function performUpkeep(address game, bytes4 selector) public {
        LuckySix(payable(game)).performUpkeep(abi.encode(bytes4(selector)));
    }

}