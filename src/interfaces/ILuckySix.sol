// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

/**
 * @dev Interface of LuckySix lottery
 */
interface ILuckySix {
    // =============================================================
    //                          STRUCTS
    // =============================================================
    /**
     * @dev The current round is represented by this struct, where `isStarted` indicates whether
     *      the countdown for the current round's `roundDuration` has started, and the time it 
     *      started is saved in the `timeStarted` field. Note that when contiguous items within a
     *      struct require 256 bits or less, the compiler combines multiple values into a
     *      single 256-bit word.
     */
    struct Round {
        uint128 numberOfRound;
        uint64 timeStarted;
        bool isStarted;
    }

    /**
     * @dev Each ticket a user plays is saved in the `players` nested mapping, where an array of
     *      tickets played in a given round is stored for each address. Additionally, this struct
     *      uses two 256-bit words when storing information about a ticket.
     */
    struct Ticket {
        uint256 bet;
        uint8[6] combination;
        bool redeemed;
    }

    /**
     * @dev The lottery can have various states, and a specific state is required for executing particular
     *      functions. Keepers are responsible for automating the game based on these states.
     */
    enum LOTTERY_STATE {
        READY,                  // GameOpened
        STARTED,                // GameStarted
        CALCULATING,            // GameRequestRandomNumber
        DRAWING,                // GameRandomNumberFulfilled
        CLOSED                  // GameRoundEnded
    }

    // =============================================================
    //                          FUNCTIONS
    // =============================================================
    /**
     * @dev See {LuckySix-initialize}.
     */
    function initialize(address, bytes32, uint64) external;

    /**
     * @dev See {LuckySix-openRound}.
     */
    function openRound() external;

    /**
     * @dev See {LuckySix-endRound}.
     */
    function endRound() external;

    /**
     * @dev See {LuckySix-playTicket}.
     */
    function playTicket(uint8[6] memory) external payable;

    /**
     * @dev See {LuckySix-drawNumbers}.
     */
    function drawNumbers() external;

    /**
     * @dev See {LuckySix-getPayoutForTicket}.
     */
    function getPayoutForTicket(uint256, uint256) external;

    /**
     * @dev See {LuckySix-getTicketsForRound}.
     */
    function getTicketsForRound(uint256) external view returns (Ticket[] memory);

    /**
     * @dev See {LuckySix-setKeeperAddress}.
     */
    function setKeeperAddress(address) external;

    /**
     * @dev See {LuckySix-withdrawPlatformFee}.
     */
    function withdrawPlatformFee() external payable;

    /**
     * @dev See {LuckySix-setPlatformFee}.
     */
    function setPlatformFee(uint256) external;

    /**
     * @dev See {LuckySix-setRoundDuration}.
     */
    function setRoundDuration(uint256) external;

    /**
     * @dev See {LuckySix-pause}.
     */
    function pause() external;

    /**
     * @dev See {LuckySix-unpause}.
     */
    function unpause() external;

    // =============================================================
    //                          EVENTS
    // =============================================================
    /**
     * @dev Emitted when the `openRound` function is executed by the keeper, with the parameter
     *      indicating the number of the current round.
     */
    event GameRoundOpened(uint256);

    /**
     * @dev Emitted when the first ticket of a round is played, and the countdown is initiated,
     *      with the parameter indicating the number of the current round.
     */
    event GameStarted(uint256);

    /**
     * @dev Emitted when the keeper ends a round and initiates a VRF request for a random number
     *      for the current round.
     */
    event GameRequestRandomNumber(uint256);

    /**
     * @dev Emitted when `Chainlink` callback request is fulfilled, and the random number is stored
     *      for the current round.
     */
    event GameRandomNumberFulfilled(uint256);

    /**
     * @dev Emitted when the numbers and jokers are drawn and saved for the current round. Note that
     *      `numberOfRound` is incremented when this event is emitted.
     */
    event GameRoundEnded(uint256);

    /**
     * @dev Emitted when a `msg.sender` successfully plays a valid ticket.
     */
    event TicketBought(address indexed player, uint256 numOfRound, uint8[6] combination);

    /**
     * @dev Emitted when a 'msg.sender' successfully cashes out a winning ticket.
     */
    event TicketCashedOut(address indexed player, uint256 numOfRound, uint256 indexOfTicket, uint256 amount);

    /**
     * @dev Emitted when the owner changes the `platformFee`.
     */
    event PlatformFeeChanged(uint256 newAmount);

    // =============================================================
    //                          ERRORS
    // =============================================================

    /**
     * @dev Indicates a failure when executing a function that requires the lottery state to be `CLOSED`.
     */
    error LotteryNotClosed();

    /**
     * @dev Indicates a failure when executing a function that requires the lottery state to be `READY`
     *      or `STARTED`.
     */
    error LotteryNotOpen();

    /**
     * @dev Indicates a failure when executing a function that requires the lottery state to be `STARTED`.
     */
    error LotteryNotStarted();

    /**
     * @dev Indicates a failure when executing a function that requires the countdown to be finished.
     */
    error LotteryNotEnded();

    /**
     * @dev Indicates a failure when executing a function that requires the lottery state to be `DRAWING`.
     */
    error LotteryNotDrawn();
    
    /**
     * @dev Indicates a failure when the `msg.sender` is not the keeper address.
     */
    error UnauthorizedAccess();

    /**
     * @dev Indicates a failure when the given `combination` to be played is determined to be invalid.
     */
    error NotValidCombination(uint8[6] combination);

    /**
     * @dev Indicates a failure when playing a ticket and the `msg.value` is lower than the `platformFee`.
     */
    error NotEnoughFunds(uint256);

    /**
     * @dev Indicates a failure when the ticket with the given `index` for the `round` does not exist.
     */
    error InvalidTicket(uint256 round, uint256 index);

    /**
     * @dev Indicates a failure when trying to get the payout of a ticket that has already received one.
     */
    error TicketAlreadyCashed(uint256, uint256);

    /**
     * @dev Indicates a failure when a ticket does not have a winning combination.
     */
    error TicketNotWinning(uint256, uint256);

    /**
     * @dev Indicates a failure when the keeper fails to call a function with the given selector.
     */
    error KeeperFailed(bytes4);
}
