// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/console2.sol";
import { ModuleKitHelpers } from "modulekit/ModuleKit.sol";
import { MODULE_TYPE_EXECUTOR, MODULE_TYPE_VALIDATOR } from "modulekit/external/ERC7579.sol";
import { OwnableValidator } from "src/test/OwnableValidator.sol";
import { UnitBase } from "../../UnitBase.t.sol";

contract EmailRecoveryModule_getAllowedSelectors_Test is UnitBase {
    using ModuleKitHelpers for *;

    function setUp() public override {
        super.setUp();
    }

    function test_GetAllowedSelectors_Succeeds() public view {
        bytes4[] memory allowedSelectors = emailRecoveryModule.getAllowedSelectors(accountAddress);

        assertEq(allowedSelectors.length, 1);
        assertEq(allowedSelectors[0], functionSelector);
    }

    function test_GetAllowedSelectors_SucceedsMultipleSelectors() public {
        // Deplopy and install new validator
        OwnableValidator newValidator = new OwnableValidator();
        address newValidatorAddress = address(newValidator);
        instance.installModule({
            moduleTypeId: MODULE_TYPE_VALIDATOR,
            module: newValidatorAddress,
            data: abi.encode(owner, recoveryModuleAddress)
        });
        bytes4 newFunctionSelector = bytes4(keccak256(bytes("rotateOwner(address,address)")));

        vm.startPrank(accountAddress);
        emailRecoveryModule.allowValidatorRecovery(newValidatorAddress, "", newFunctionSelector);
        vm.stopPrank();

        bytes4[] memory allowedSelectors = emailRecoveryModule.getAllowedSelectors(accountAddress);
        assertEq(allowedSelectors.length, 2);
        assertEq(allowedSelectors[0], newFunctionSelector);
        assertEq(allowedSelectors[1], functionSelector);
    }
}
