// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { DeployEmailRecoveryModuleScript } from "../../../script/DeployEmailRecoveryModule.s.sol";

contract DeployEmailRecoveryModuleScriptTest is Test {
    DeployEmailRecoveryModuleScript deployEmailRecoveryModuleScript;

    function setUp() public {
        console.log("setUp");
        deployEmailRecoveryModuleScript = new DeployEmailRecoveryModuleScript();

        vm.setEnv(
            "PRIVATE_KEY", 
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );
    }

    function test_run() public {
        deployEmailRecoveryModuleScript.run();
    }

    
}
