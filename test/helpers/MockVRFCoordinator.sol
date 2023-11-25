// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@chainlink/vrf/VRFConsumerBaseV2.sol";

contract MockVRFCoordinator {

    uint256 internal counter = 0;

    function requestRandomWords(
        bytes32     /* keyHash */,
        uint64      /* subId */,
        uint16      /* requestConfirmations */,
        uint32      /* callbackGasLimit */,
        uint32      /* numWords*/
    ) external returns (uint256 requestId) {
        VRFConsumerBaseV2 consumer = VRFConsumerBaseV2(msg.sender);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = counter;
        consumer.rawFulfillRandomWords(requestId, randomWords);
        counter += 1;
    }

}