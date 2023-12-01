// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import { LuckySix } from 'src/LuckySix.sol';

interface IMockKeeper {
    error UpkeepNotNeeded();
}

contract MockKeeper is IMockKeeper {

    LuckySix game;

    function setLuckySixAddress(address gameAddress) public {
        game = LuckySix(payable(gameAddress));
    }

    function checkUpkeep() public {
        (bool upkeepNeeded, bytes memory performData) = game.checkUpkeep(hex"");
        
        if(upkeepNeeded)
            game.performUpkeep(performData);
        else
            revert UpkeepNotNeeded();
    }
    
}