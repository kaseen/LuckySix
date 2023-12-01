# LuckySix  

Lucky Six, a Solidity-based game built with [Foundry](https://github.com/foundry-rs/foundry), features 35 numbers drawn in order randomly in each round from 1 to 48. The lottery is automated, and when the first ticket is played in a round, a countdown of `roundDuration` seconds begins, enabling participation during this period. After the countdown, a request for a random salt is sent, and upon receiving it, the system generates random numbers and two joker positions for the round. System then initiates a new round, perpetuating this cycle indefinitely.  

Users participate by playing one or multiple tickets in the current round, selecting a set of 6 unique numbers and specifying their desired spending amount. The details of user-played tickets in each round are securely stored on the blockchain. If a player's chosen combination matches all 6 numbers drawn from the pool of 35, they become eligible to redeem a prize. The prize amount is calculated by multiplying the ticket value with the coefficient corresponding to the last correctly guessed number. Additionally, each occurrence of a joker in the combination results in a doubled prize. In the event that a user's combination doesn't match any of the 35 drawn numbers, they receive a prize equal to the ticket value multiplied by 100!  

## Features
* The lottery contract balance is divided into two distinct pools: one for users to claim prizes, and the other for the lottery owner, containing the `platformFee` paid by users for participating in the lottery.
* The lottery process operates smoothly with the forwarder address of the keepers from the [Chainlink Automation v2.1](https://docs.chain.link/chainlink-automation), ensuring seamless and continuous automation.
* The salt utilized to draw random numbers (and jokers) for each round is generated using [Chainlink VRF (Verifiable Random Function)](https://docs.chain.link/vrf).
* The drawn numbers and jockers for each round are efficiently packed into a single 256-word using 6 bits for each number. This packing strategy optimizes the cost of a single `SSTORE` operation when storing this data on the blockchain.
* The lottery is designed to be [UUPS Upgradeable](https://docs.openzeppelin.com/contracts/5.x/api/proxy), providing flexibility for the inclusion of additional features in future updates. Unclaimed winning tickets are securely stored in subsequent versions.
* The [ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/ReentrancyGuardUpgradeable.sol) module is implemented to safeguard against reentrant calls to a payout function.
* The [Ownable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol) module provides a fundamental access control mechanism, allowing the owner to configure the `forwarderAddress`, `platformFee` and `roundDuration`.
* The [Pausable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/PausableUpgradeable.sol) module incorporates an emergency stop mechanism, enabling the owner to temporarily halt keepers from automating the lottery.


#### Automation
The `checkUpkeep` function checks the current lottery state and encodes the corresponding function which changes lottery state as a bytes array. Keepers utilize this data to invoke the `performUpkeep` function, where the encoded `performData` is decoded and then executed.
```
bytes4 selector = abi.decode(performData, (bytes4));
(bool success,) = address(this).delegatecall(abi.encodeWithSelector(selector));
```

#### Randomness
The seed for randomness `lastVerifiedRandomNumber` is acquired through Chainlink VRF. Subsequently, all other numbers are generated in sequence from that seed, shown below:
```
randomNumbers[i] = uint256(keccak256(abi.encode(block.timestamp, lastVerifiedRandomNumber, i)));
```

All the listed features have been individually tested, and you can view the behavior in the `test/` directory.

## Deploy script
Based on the provided `block.chainid`, the deployment script initiates the deployment of the `LuckySix` contract to the designated network. Subsequently, it deploys the `ERC1967Proxy` proxy contract, associating it with the implemented code, and finally initializes the game.
```
LuckySix implementation = new LuckySix();
ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");
LuckySix game = LuckySix(payable(address(proxy)));
game.initialize(COORDINATOR_ADDRESS, KEYHASH, SUBSCRIPTION_ID);
```

Following the deployment of the lottery, the script proceeds to add a new consumer, namely the LuckySix contract, to the VRF subscription. In this context, `COORDINATOR` represents the `VRFCoordinatorV2Interface` specific to the given network.
```
COORDINATOR.addConsumer(SUBSCRIPTION_ID, lotteryAddress);
```

Subsequently, within the Chainlink Automation network, LINK tokens are granted approval to the `Registrar` of the specified network, and a new Upkeep is registered, resulting in the generation of an `upkeepId`.
```
RegistrationParams memory params = RegistrationParams({
    ...
});
LINK_TOKEN.approve(address(REGISTRAR), params.amount);
uint256 upkeepId = REGISTRAR.registerUpkeep(params);
```

Finally, the Chainlink registry address for the specified network is utilized to instantiate `IKeeperRegistryMaster`.  This step involves obtaining the unique forwarder address of the Keeper with the given `upkeepId`, which is then employed to set permissioned access for the `performUpkeep` function.
```
IKeeperRegistryMaster registry = IKeeperRegistryMaster(REGISTRY_ADDRESS);
address forwarderAddress = registry.getForwarder(upkeepId);
game.setKeeperAddress(forwarderAddress);
```

### Lottery addresses

Sepolia: [0x4153a9Ea482a8cCb1737662FF840def7E087A6c8](https://sepolia.etherscan.io/address/0x4153a9ea482a8ccb1737662ff840def7e087a6c8)  
Mumbai: [0x86E074017b01541fcb8CB548Cbd61d9fF9D23a9a](https://mumbai.polygonscan.com/address/0x86e074017b01541fcb8cb548cbd61d9ff9d23a9a)


## License

This project is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).