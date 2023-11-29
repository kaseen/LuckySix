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
            LINK_TOKEN = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        }
        // For Mumbai testnet
        else if(block.chainid == 80001){
            COORDINATOR_ADDRESS = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
            KEYHASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
            SUBSCRIPTION_ID = 6579;
            LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        }
        else
            revert();

        COORDINATOR = VRFCoordinatorV2Interface(COORDINATOR_ADDRESS);
        PRIVATE_KEY = vm.envUint("PRIVATE_KEY");
    }

    function run() external {
        vm.startBroadcast(PRIVATE_KEY);

        address lotteryAddress = deployLottery();
        addVrfConsumer(lotteryAddress);

        //addForwarder(0x5E6ee5534b4C7081E852788b1a8781EDFA1b35e5, 0xD0E80E2ceDCF8c8953358e5E3A9EBc873aB3A848);

        vm.stopBroadcast();
    }

    /**
     * @dev This function deploys the implementation code, wraps it in a proxy, initializes the game,
     *      and returns the address of lottery.
     */
    function deployLottery() private returns (address) {
        LuckySix implementation = new LuckySix();
        UUPSProxy proxy = new UUPSProxy(address(implementation), "");
        LuckySix game = LuckySix(payable(address(proxy)));
        game.initialize(COORDINATOR_ADDRESS, KEYHASH, SUBSCRIPTION_ID);
        return address(game);
    }

    /**
     * @dev This function adds a new consumer to the VRF subscription.
     */
    function addVrfConsumer(address lotteryAddress) private {
        COORDINATOR.addConsumer(SUBSCRIPTION_ID, lotteryAddress);
    }

    /**
     * @dev After the registration of upkeep, a unique `forwarder` address is created for permissioned
     *      access to the `performUpkeep` function.
     */
    function addForwarder(address lotteryAddress, address forwarderAddress) private {
        LuckySix game = LuckySix(payable(lotteryAddress));
        game.setKeeperAddress(forwarderAddress);
    }

    /**
     * @dev Remove all consumers from a VRF subscription with the given `subId`.
     */
    function clearAllConsumersVRF() private {
        (,,,address[] memory consumers) = COORDINATOR.getSubscription(SUBSCRIPTION_ID);
        for(uint i; i<consumers.length; i++)
            COORDINATOR.removeConsumer(SUBSCRIPTION_ID, consumers[i]);
    }
}