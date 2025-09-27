// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {DummyFactory} from "src/levels/DummyFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

interface Fallout {
    function owner() external view returns (address);

    function Fal1out() external;
}

contract TestFalloutSolution is Test, Utils {
    Ethernaut ethernaut;
    Fallout instance;

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
        DummyFactory factory = DummyFactory(getOldFactory("FalloutFactory"));
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Fallout(
            payable(createLevelInstance(ethernaut, Level(address(factory)), 0))
        );
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

    function testSolve() public {
        // Goal:
        // - claim ownership og Fallout contract

        // the ownership can be claimed by only calling Fal1out
        // which maybe was intended to be a constructor(i guess cause it's using caps)
        vm.startPrank(player);

        console.log("owner:", instance.owner());

        instance.Fal1out();

        console.log("owner after call:", instance.owner());

        assertEq(instance.owner(), player);
    }
}
