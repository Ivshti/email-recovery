// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { console2 } from "forge-std/console2.sol";
import { ModuleKitHelpers } from "modulekit/ModuleKit.sol";
import { MODULE_TYPE_EXECUTOR } from "modulekit/external/ERC7579.sol";
import { IEmailRecoveryManager } from "src/interfaces/IEmailRecoveryManager.sol";
import { GuardianStorage, GuardianStatus } from "src/libraries/EnumerableGuardianMap.sol";
import { GuardianUtils } from "src/libraries/GuardianUtils.sol";
import { UnitBase } from "../UnitBase.t.sol";
import { IModule } from "erc7579/interfaces/IERC7579Module.sol";

contract EmailRecoveryManager_configureRecovery_Test is UnitBase {
    using ModuleKitHelpers for *;

    function setUp() public override {
        super.setUp();
    }

    function test_ConfigureRecovery_RevertWhen_AlreadyRecovering() public {
        acceptGuardian(accountSalt1);
        vm.warp(12 seconds);
        handleRecovery(recoveryModuleAddress, calldataHash, accountSalt1);

        vm.expectRevert(IEmailRecoveryManager.SetupAlreadyCalled.selector);
        vm.startPrank(accountAddress);
        emailRecoveryManager.configureRecovery(guardians, guardianWeights, threshold, delay, expiry);
    }

    function test_ConfigureRecovery_RevertWhen_ConfigureRecoveryCalledTwice() public {
        vm.startPrank(accountAddress);
        vm.expectRevert(IEmailRecoveryManager.SetupAlreadyCalled.selector);
        emailRecoveryManager.configureRecovery(guardians, guardianWeights, threshold, delay, expiry);
    }

    function test_ConfigureRecovery_RevertWhen_RecoveryModuleNotInstalled() public {
        vm.prank(accountAddress);
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.stopPrank();

        vm.prank(accountAddress);
        vm.expectRevert(IEmailRecoveryManager.RecoveryModuleNotAuthorized.selector);
        emailRecoveryManager.configureRecovery(guardians, guardianWeights, threshold, delay, expiry);
    }

    function test_ConfigureRecovery_Succeeds() public {
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");

        // Install recovery module - configureRecovery is called on `onInstall`
        // vm.expectEmit();
        // emit IEmailRecoveryManager.RecoveryConfigured(instance.account, guardians.length);
        instance.installModule({
            moduleTypeId: MODULE_TYPE_EXECUTOR,
            module: recoveryModuleAddress,
            data: abi.encode(
                validatorAddress,
                isInstalledContext,
                functionSelector,
                guardians,
                guardianWeights,
                threshold,
                delay,
                expiry
            )
        });

        IEmailRecoveryManager.RecoveryConfig memory recoveryConfig =
            emailRecoveryManager.getRecoveryConfig(accountAddress);
        assertEq(recoveryConfig.delay, delay);
        assertEq(recoveryConfig.expiry, expiry);

        IEmailRecoveryManager.GuardianConfig memory guardianConfig =
            emailRecoveryManager.getGuardianConfig(accountAddress);
        assertEq(guardianConfig.guardianCount, guardians.length);
        assertEq(guardianConfig.totalWeight, totalWeight);
        assertEq(guardianConfig.threshold, threshold);
        assertEq(guardianConfig.initialized, true);

        GuardianStorage memory guardian =
            emailRecoveryManager.getGuardian(accountAddress, guardians[0]);
        assertEq(uint256(guardian.status), uint256(GuardianStatus.REQUESTED));
        assertEq(guardian.weight, guardianWeights[0]);
    }

    function test_ConfigureRecovery_RevertWhen_ZeroGuardians() public {
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.startPrank(accountAddress);
        emailRecoveryModule.allowValidatorRecovery(
            validatorAddress, isInstalledContext, functionSelector
        );
        address[] memory zeroGuardians;

        vm.expectRevert(GuardianUtils.IncorrectNumberOfWeights.selector);
        emailRecoveryManager.configureRecovery(
            zeroGuardians, guardianWeights, threshold, delay, expiry
        );
    }

    function test_ConfigureRecovery_RevertWhen_ZeroGuardianWeights() public {
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.startPrank(accountAddress);
        emailRecoveryModule.allowValidatorRecovery(
            validatorAddress, isInstalledContext, functionSelector
        );
        uint256[] memory zeroGuardianWeights;

        vm.expectRevert(GuardianUtils.IncorrectNumberOfWeights.selector);
        emailRecoveryManager.configureRecovery(
            guardians, zeroGuardianWeights, threshold, delay, expiry
        );
    }

    function test_ConfigureRecovery_RevertWhen_ZeroThreshold() public {
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.startPrank(accountAddress);
        emailRecoveryModule.allowValidatorRecovery(
            validatorAddress, isInstalledContext, functionSelector
        );
        uint256 zeroThreshold = 0;

        vm.expectRevert(GuardianUtils.ThresholdCannotBeZero.selector);
        emailRecoveryManager.configureRecovery(
            guardians, guardianWeights, zeroThreshold, delay, expiry
        );
    }

    function test_ConfigureRecovery_SucceedsWithNoGuardians() public {
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");

        address[] memory zeroGuardians;
        uint256[] memory zeroGuardianWeights;
        uint256 zeroThreshold = 0;

        // Install recovery module - configureRecovery is called on `onInstall`
        instance.installModule({
            moduleTypeId: MODULE_TYPE_EXECUTOR,
            module: recoveryModuleAddress,
            data: abi.encode(
                validatorAddress,
                isInstalledContext,
                functionSelector,
                zeroGuardians,
                zeroGuardianWeights,
                zeroThreshold,
                delay,
                expiry
            )
        });

        IEmailRecoveryManager.RecoveryConfig memory recoveryConfig =
            emailRecoveryManager.getRecoveryConfig(accountAddress);
        assertEq(recoveryConfig.delay, delay);
        assertEq(recoveryConfig.expiry, expiry);

        IEmailRecoveryManager.GuardianConfig memory guardianConfig =
            emailRecoveryManager.getGuardianConfig(accountAddress);
        assertEq(guardianConfig.guardianCount, zeroGuardians.length);
        assertEq(guardianConfig.totalWeight, 0);
        assertEq(guardianConfig.threshold, zeroThreshold);
        assertEq(guardianConfig.initialized, true);

        GuardianStorage memory guardian =
            emailRecoveryManager.getGuardian(accountAddress, guardians[0]);
        assertEq(uint256(guardian.status), uint256(GuardianStatus.NONE));
        assertEq(guardian.weight, 0);
    }
}
