// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { DeployAccountScript } from "../../../script/DeployAccount.s.sol";

contract DeployAccountScriptTest is Test {
    DeployAccountScript deployAccountScript;

    function setUp() public {
        // Fork from base sepolia
        vm.createSelectFork("https://sepolia.base.org");
        vm.fee(1 gwei);

        deployAccountScript = new DeployAccountScript();

        vm.setEnv(
            "PRIVATE_KEY", 
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privKey);
        vm.deal(deployer, 100 ether);

        vm.setEnv(
            "SIGNER",
            "0x69bec2dd161d6bbcc91ec32aa44d9333ebc864c0"
        );
        address signer = vm.envAddress("SIGNER");
        vm.deal(signer, 100 ether);

    }

    function test_run() public {
        deployAccountScript.run();
    }

    
}
