// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Privacy} from "src/levels/Privacy.sol";
import {PrivacyFactory} from "src/levels/PrivacyFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestPrivacySolution is Test, Utils {
    Ethernaut ethernaut;
    Privacy instance;

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
        PrivacyFactory factory = new PrivacyFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Privacy(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the intial state of the level and enviroment.
    function testInit() public {
        vm.startPrank(player);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    function testSolve() public {
        vm.startPrank(player);

        // goal: get key stored on data variable

        // we need to get the key that it's stored on contract storage
        // the 4th slot represents the data variable which is an array of bytes32 of 3 elements
        // we read the 5th slot corresponding to _key
        bytes32 slot5 = vm.load(address(instance), bytes32(uint256(5)));
        // call unlock with keyc
        instance.unlock(bytes16(slot5));
        // check that lock is set to false
        assertFalse(instance.locked());
    }
}