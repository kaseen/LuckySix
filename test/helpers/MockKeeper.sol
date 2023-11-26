// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';

contract MockKeeper {

    LuckySix game;

    function setLuckySixAddress(address gameAddress) public {
        game = LuckySix(payable(gameAddress));
    }

    function checkUpkeep() public {
        (bool upkeepNeeded, bytes memory performData) = game.checkUpkeep(hex"");
        
        if(upkeepNeeded)
            game.performUpkeep(performData);
    }
    
}