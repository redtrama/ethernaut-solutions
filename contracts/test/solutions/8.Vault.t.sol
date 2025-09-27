// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Vault} from "src/levels/Vault.sol";
import {VaultFactory} from "src/levels/VaultFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

contract TestVaultSolution is Test, Utils {
    Ethernaut ethernaut;
    Vault instance;

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
        VaultFactory factory = new VaultFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Vault(
            payable(
                createLevelInstance(
                    ethernaut,
                    Level(address(factory)),
                    0.001 ether
                )
            )
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
        // goal: unlock the vault (bool unlock = true)

        // the variable in the second slot is bytes32 private password
        // making a variable private doesn't mean that it will be private, we can see what's stored on the slot
        // and then just call unlock with that value

        //check that locked is true before attack
        assert(instance.locked() == true);

        // we need to read the second storage slot 1
        bytes32 slot1 = vm.load(address(instance), bytes32(uint256(1)));

        // bytes32 password = bytes32(0x412076657279207374726f6e67207365637265742070617373776f7264203a29);
        // use slot1 value to match password
        instance.unlock(slot1);

        // check it's unlocked
        assert(instance.locked() == false);
    }
}
