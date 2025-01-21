// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    uint256 s_raffleState;

    /**
     * Events
     */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    /**
     * modifier
     */
    modifier prankPlayer() {
        // Arrange
        vm.prank(PLAYER);
        _;
    }

    /**
     * Functions
     */
    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /**
     * Enter Raffle
     */
    function testRaffleRevertWithInsufficientEntranceFee() public prankPlayer {
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__InsufficientEntranceFee.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersOnEntry() public prankPlayer {
        // Act
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecord = raffle.getPlayer(0);
        assertEq(PLAYER, playerRecord);
    }

    function testEnteringRaffleEmitsEvent() public prankPlayer {
        // Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRestrictPlayersFromEnteringWhileRaffleIsCalculating()
        public
        prankPlayer
    {
        raffle.enterRaffle{value: entranceFee}();
        // Set the block.timestamp
        vm.warp(block.timestamp + interval + 1);
        //  Set block.number
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
