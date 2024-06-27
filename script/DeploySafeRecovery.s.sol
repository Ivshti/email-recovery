// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { SafeRecoverySubjectHandler } from "src/handlers/SafeRecoverySubjectHandler.sol";
import { EmailRecoveryManager } from "src/EmailRecoveryManager.sol";
import { SafeRecoveryModule } from "src/modules/SafeRecoveryModule.sol";
import { Verifier } from "ether-email-auth/packages/contracts/src/utils/Verifier.sol";
import { ECDSAOwnedDKIMRegistry } from
    "ether-email-auth/packages/contracts/src/utils/ECDSAOwnedDKIMRegistry.sol";
import { EmailAuth } from "ether-email-auth/packages/contracts/src/EmailAuth.sol";

// source .env
// forge script --chain sepolia script/DeploySafeRecovery.s.sol:DeploySafeRecovery_Script --rpc-url
// $BASE_SEPOLIA_RPC_URL --broadcast -vvvv
contract DeploySafeRecovery_Script is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address verifier = vm.envOr("VERIFIER", address(0));
        address dkimRegistry = vm.envOr("DKIM_REGISTRY", address(0));
        address dkimRegistrySigner = vm.envOr("SIGNER", address(0));
        address emailAuthImpl = vm.envOr("EMAIL_AUTH_IMPL", address(0));

        if (verifier == address(0)) {
            verifier = address(new Verifier());
            console.log("Deployed Verifier at", verifier);
        }

        if (dkimRegistry == address(0)) {
            require(dkimRegistrySigner != address(0), "DKIM_REGISTRY_SIGNER is required");
            dkimRegistry = address(new ECDSAOwnedDKIMRegistry(dkimRegistrySigner));
            console.log("Deployed DKIM Registry at", dkimRegistry);
        }

        if (emailAuthImpl == address(0)) {
            emailAuthImpl = address(new EmailAuth());
            console.log("Deployed Email Auth at", emailAuthImpl);
        }

        SafeRecoverySubjectHandler emailRecoveryHandler = new SafeRecoverySubjectHandler();
        EmailRecoveryManager emailRecoveryManager = new EmailRecoveryManager(
            verifier, dkimRegistry, emailAuthImpl, address(emailRecoveryHandler)
        );
        address manager = address(emailRecoveryManager);
        SafeRecoveryModule emailRecoveryModule = new SafeRecoveryModule(manager);
        address module = address(emailRecoveryModule);
        emailRecoveryManager.initialize(module);

        console.log("Deployed Email Recovery Handler at", address(emailRecoveryHandler));
        console.log("Deployed Email Recovery Manager at", vm.toString(manager));
        console.log("Deployed Email Recovery Module at", vm.toString(module));
        vm.stopBroadcast();
    }
}
