// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { console2 } from "forge-std/console2.sol";
import { UnitBase } from "../UnitBase.t.sol";
import { IEmailRecoveryManager } from "src/interfaces/IEmailRecoveryManager.sol";
import { GuardianStorage, GuardianStatus } from "src/libraries/EnumerableGuardianMap.sol";
import { GuardianUtils } from "src/libraries/GuardianUtils.sol";

contract EmailRecoveryManager_addGuardian_Test is UnitBase {
    function setUp() public override {
        super.setUp();
    }

    function test_AddGuardian_RevertWhen_AlreadyRecovering() public {
        acceptGuardian(accountSalt1);
        vm.warp(12 seconds);
        handleRecovery(recoveryModuleAddress, calldataHash, accountSalt1);

        vm.startPrank(accountAddress);
        vm.expectRevert(IEmailRecoveryManager.RecoveryInProcess.selector);
        emailRecoveryManager.addGuardian(guardians[0], guardianWeights[0]);
    }

    function test_AddGuardian_AddGuardian_Succeeds() public {
        address newGuardian = address(1);
        uint256 newGuardianWeight = 1;

        uint256 expectedGuardianCount = guardians.length + 1;
        uint256 expectedTotalWeight = totalWeight + newGuardianWeight;
        uint256 expectedThreshold = threshold; // same threshold

        vm.startPrank(accountAddress);
        vm.expectEmit();
        emit GuardianUtils.AddedGuardian(accountAddress, newGuardian);
        emailRecoveryManager.addGuardian(newGuardian, newGuardianWeight);

        GuardianStorage memory guardianStorage =
            emailRecoveryManager.getGuardian(accountAddress, newGuardian);
        assertEq(uint256(guardianStorage.status), uint256(GuardianStatus.REQUESTED));
        assertEq(guardianStorage.weight, newGuardianWeight);

        IEmailRecoveryManager.GuardianConfig memory guardianConfig =
            emailRecoveryManager.getGuardianConfig(accountAddress);
        assertEq(guardianConfig.guardianCount, expectedGuardianCount);
        assertEq(guardianConfig.totalWeight, expectedTotalWeight);
        assertEq(guardianConfig.threshold, expectedThreshold);
        assertEq(guardianConfig.initialized, true);
    }
}
