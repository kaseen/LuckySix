// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { ERC1967Proxy } from '@oz/proxy/ERC1967/ERC1967Proxy.sol';
import { LuckySix } from 'src/LuckySix.sol';

import { MockVRFCoordinator } from '../test/helpers/MockVRFCoordinator.sol';
import { MockKeeper } from '../test/helpers/MockKeeper.sol';

import 'forge-std/Script.sol';

contract LocalDeployGameScript is Script {

    uint256 private constant PRIVATE_KEY =
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6; // Index 0

    uint256 private constant LOCAL_ID = 31337;

    function run() external {
        if(block.chainid != LOCAL_ID){
            revert();
        }

        vm.startBroadcast(PRIVATE_KEY);

        MockVRFCoordinator mockVrfCoordinator = new MockVRFCoordinator();
        console.log('VRFCoordinator address: %s', address(mockVrfCoordinator));

        MockKeeper mockKeeper = new MockKeeper();
        console.log('Keeper address: %s', address(mockKeeper));

        LuckySix implementation = new LuckySix();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");
        LuckySix game = LuckySix(payable(address(proxy)));
        game.initialize(address(mockVrfCoordinator), 0, 0);
        game.setKeeperAddress(address(mockKeeper));
        game.setRoundDuration(0);

        mockKeeper.setLuckySixAddress(address(game));

        console.log('Game address: %s', address(game));

        mockKeeper.checkUpkeep();

        vm.stopBroadcast();
    }
}