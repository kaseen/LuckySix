// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LuckySix, UUPSProxy } from 'src/LuckySix.sol';
import '@chainlink/interfaces/VRFCoordinatorV2Interface.sol';
import 'forge-std/Script.sol';

contract DeployScript is Script {
    address immutable COORDINATOR_ADDRESS;
    address immutable LINK_TOKEN;
    bytes32 immutable KEYHASH;
    uint64 immutable SUBSCRIPTION_ID;
    address immutable KEEPER_ADDRESS;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint256 immutable PRIVATE_KEY;

    /**
     * @dev Adjust settings for Chainlink VRF subscription based on the `chain.id` provided by the RPC URL.
     */
    constructor() {
        // For Sepolia testnet
        if(block.chainid == 11155111){
            COORDINATOR_ADDRESS = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
            KEYHASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
            SUBSCRIPTION_ID = 1508;
            KEEPER_ADDRESS = 0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976;
            LINK_TOKEN = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        }
        // For Mumbai testnet
        else if(block.chainid == 80001){
            COORDINATOR_ADDRESS = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
            KEYHASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
            SUBSCRIPTION_ID = 6579;
            KEEPER_ADDRESS = 0xf97C091179A4A4d666da7a2764dDeD4F932FC14A;
            LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        }
        else
            revert();

        COORDINATOR = VRFCoordinatorV2Interface(COORDINATOR_ADDRESS);
        PRIVATE_KEY = vm.envUint("PRIVATE_KEY");
    }

    function run() external {

        vm.startBroadcast(PRIVATE_KEY);

        LuckySix implementation = new LuckySix();
        UUPSProxy proxy = new UUPSProxy(address(implementation), "");
        LuckySix game = LuckySix(payable(address(proxy)));
        game.initialize(COORDINATOR_ADDRESS, KEYHASH, SUBSCRIPTION_ID, KEEPER_ADDRESS);

        COORDINATOR.addConsumer(SUBSCRIPTION_ID, address(game));

        vm.stopBroadcast();

        /*
        vm.startBroadcast(PRIVATE_KEY);
        LuckySix game = LuckySix(payable(0xAaa14C6064b2649cf6D6af5C99df3EEe26FE7344));
        game.setKeeperAddress(0xB3335686967A9B4e492d4b5A0b1e7Dfc0F9F41F1);
        vm.stopBroadcast();
        */
    }
}