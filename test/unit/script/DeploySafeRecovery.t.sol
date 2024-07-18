// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { DeploySafeRecovery_Script } from "../../../script/DeploySafeRecovery.s.sol";

contract DeploySafeRecoveryScriptTest is Test {
    DeploySafeRecovery_Script deploySafeRecoveryScript;

    function setUp() public {
        deploySafeRecoveryScript = new DeploySafeRecovery_Script();

        vm.setEnv(
            "PRIVATE_KEY", 
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );
        vm.setEnv(
            "DKIM_REGISTRY_SIGNER",
            "0x69bec2dd161d6bbcc91ec32aa44d9333ebc864c0"
        );
        vm.setEnv(
            "SAFE_ACCOUNT_SALT",
            "0x0000000000000000000000000000000000000000000000000000000000000007"
        );
    }

    function test_run() public {
        deploySafeRecoveryScript.run();
    }

    
}
