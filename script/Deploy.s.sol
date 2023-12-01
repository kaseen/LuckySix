// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { LuckySix, UUPSProxy } from 'src/LuckySix.sol';
import { AutomationRegistrarInterface, RegistrationParams } from './interfaces/AutomationRegistrarInterface.sol';
import '@chainlink/automation/interfaces/v2_1/IKeeperRegistryMaster.sol';
import '@chainlink/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/shared/interfaces/LinkTokenInterface.sol';
import 'forge-std/Script.sol';

contract DeployScript is Script {

    // VRF
    address immutable COORDINATOR_ADDRESS;
    bytes32 immutable KEYHASH;
    uint64 immutable SUBSCRIPTION_ID;

    // Automation
    address immutable LINK_ADDRESS;
    address immutable REGISTRY_ADDRESS;
    address immutable REGISTRAR_ADDRESS;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    AutomationRegistrarInterface immutable REGISTRAR;
    LinkTokenInterface immutable LINK_TOKEN;
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
            REGISTRY_ADDRESS = 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad;
            REGISTRAR_ADDRESS = 0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976;
            LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        }
        // For Mumbai testnet
        else if(block.chainid == 80001){
            COORDINATOR_ADDRESS = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
            KEYHASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
            SUBSCRIPTION_ID = 6579;
            REGISTRY_ADDRESS = 0xf97C091179A4A4d666da7a2764dDeD4F932FC14A;
            REGISTRAR_ADDRESS = 0xb58E509b59538256854b2a223289160F83B23F92;
            LINK_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        }
        else
            revert();

        COORDINATOR = VRFCoordinatorV2Interface(COORDINATOR_ADDRESS);
        REGISTRAR = AutomationRegistrarInterface(REGISTRAR_ADDRESS);
        LINK_TOKEN = LinkTokenInterface(LINK_ADDRESS);
        PRIVATE_KEY = vm.envUint("PRIVATE_KEY");
    }

    /**
     * @dev Script deploying an upgradable contract, adding a VRF consumer, and automating with Chainlink keepers.
     */
    function run() external {
        vm.startBroadcast(PRIVATE_KEY);

       /* address lotteryAddress = deployLottery();
        addVrfConsumer(lotteryAddress);

        uint256 keeperId = addKeeper(lotteryAddress, msg.sender, 5 * 10 ** 18);
        addForwarder(lotteryAddress, keeperId);*/

        
        LuckySix game = LuckySix(payable(0x86E074017b01541fcb8CB548Cbd61d9fF9D23a9a));
        console.log("BLA %s", uint256(game.lotteryState()));
        /*uint256[] memory tmp = game.unpackResultForRound(0);
        for(uint i; i<35; i++)
            console.log(tmp[i]);*/
        //game.playTicket{ value: 0.02 ether }([1,2,3,4,5,6]);
        
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
     * @dev This function allows `amount` of LINK tokens to be funded for upkeep in the automation registrar
     *      and registers the upkeep, returning the `upkeepId` when successful.
     */
    function addKeeper(address lotteryAddress, address owner, uint256 amount) private returns (uint256) {
        RegistrationParams memory params = RegistrationParams({
            name: "KEEPER",
            encryptedEmail: hex"",
            upkeepContract: lotteryAddress,
            gasLimit: uint32(500000),
            adminAddress: owner,
            triggerType: uint8(0),  // Conditional upkeep
            checkData: hex"",
            triggerConfig: hex"",
            offchainConfig: hex"",
            amount: uint96(amount)
        });

        LINK_TOKEN.approve(address(REGISTRAR), params.amount);
        uint256 upkeepId = REGISTRAR.registerUpkeep(params);

        if(upkeepId == 0) revert(); 

        return upkeepId;
    }

    /**
     * @dev This function retrieves a unique address from the upkeep with the given `upkeepId`, which is
     *      then set as the `forwarderAddress` for the `onlyKeeper` modifier. This modifier allows
     *      permissioned access for the `performUpkeep` function.
     */
    function addForwarder(address lotteryAddress, uint256 upkeepId) private {
        IKeeperRegistryMaster registry = IKeeperRegistryMaster(REGISTRY_ADDRESS);
        address forwarderAddress = registry.getForwarder(upkeepId);

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