// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { DeployUniversalEmailRecoveryModuleScript } from "../../../script/DeployUniversalEmailRecoveryModule.s.sol";

contract DeployUniversalEmailRecoveryModuleScriptTest is Test {
    DeployUniversalEmailRecoveryModuleScript deployUniversalEmailRecoveryModuleScript;

    function setUp() public {
        deployUniversalEmailRecoveryModuleScript = new DeployUniversalEmailRecoveryModuleScript();

        vm.setEnv(
            "PRIVATE_KEY", 
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );
        vm.setEnv(
            "DKIM_REGISTRY_SIGNER",
            "0x69bec2dd161d6bbcc91ec32aa44d9333ebc864c0"
        );
    }

    function test_run() public {
        deployUniversalEmailRecoveryModuleScript.run();
    }

    
}
