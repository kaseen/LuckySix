// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LuckySix, UUPSProxy } from 'src/LuckySix.sol';
import { Test } from 'forge-std/Test.sol';

contract LuckySixV2 is LuckySix {
    uint256 public newVariable;

    // Reinitialize version v2 with reinitializer(2)
    function initialize(uint256 _newVariable) reinitializer(2) public {
        newVariable = _newVariable;
    }

    function getNewVariable() public view returns (uint256) {
        return newVariable;
    }
}

contract UpgradeableTest is Test {

    UUPSProxy proxy;
    LuckySix implementationV1;

    LuckySix gameV1;
    LuckySixV2 gameV2;  

    function setUp() public {
        // Deploy LuckySix v1
        implementationV1 = new LuckySix();

        // Deploy proxy contract and point it to implementation
        proxy = new UUPSProxy(address(implementationV1), "");

        // Wrap in ABI to support easier calls
        gameV1 = LuckySix(address(proxy));

        // Constructor
        gameV1.initialize(0, address(this), address(this));
    }

    function test__Upgrade() public {
        LuckySixV2 implementationV2 = new LuckySixV2();
        gameV1.upgradeToAndCall(address(implementationV2), "");

        // Rewrap the proxy and initialize
        gameV2 = LuckySixV2(address(proxy));
        gameV2.initialize(1234);

        assertEq(gameV2.platformFee(), 0.01 ether);
        assertEq(gameV2.getNewVariable(), 1234);
    }
}