// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@chainlink/interfaces/VRFCoordinatorV2Interface.sol';
import 'forge-std/Script.sol';

contract DeployScript is Script {

    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint256 immutable PRIVATE_KEY;
    address immutable LINK_TOKEN;
    uint64 immutable SUBSCRIPTION_ID;

    /**
     * @dev Adjust settings for Chainlink VRF subscription based on the `chain.id` provided by the RPC URL.
     */
    constructor() {
        // For Sepolia testnet
        if(block.chainid == 11155111){  
            COORDINATOR = VRFCoordinatorV2Interface(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625);
            LINK_TOKEN = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
            SUBSCRIPTION_ID = 1508;
        }
        // For Mumbai testnet
        else if(block.chainid == 80001){
            COORDINATOR = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
            LINK_TOKEN = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
            SUBSCRIPTION_ID = 6579;
        }
        else
            revert();

        PRIVATE_KEY = vm.envUint("PRIVATE_KEY");
        
    }

    function run() external {

        vm.startBroadcast(PRIVATE_KEY);
        
        COORDINATOR.addConsumer(SUBSCRIPTION_ID, address(this));

        vm.stopBroadcast();
        
    }

}