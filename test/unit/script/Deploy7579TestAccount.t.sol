// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Deploy7579TestAccountScript } from "../../../script/Deploy7579TestAccount.s.sol";
import { EmailRecoverySubjectHandler } from "src/handlers/EmailRecoverySubjectHandler.sol";
import { Verifier } from "ether-email-auth/packages/contracts/src/utils/Verifier.sol";
import { ECDSAOwnedDKIMRegistry } from
    "ether-email-auth/packages/contracts/src/utils/ECDSAOwnedDKIMRegistry.sol";
import { EmailAuth } from "ether-email-auth/packages/contracts/src/EmailAuth.sol";
import { EmailRecoveryFactory } from "src/factories/EmailRecoveryFactory.sol";
import { OwnableValidator } from "src/test/OwnableValidator.sol";

contract Deploy7579TestAccountTest is Test {
    Deploy7579TestAccountScript deploy7579TestAccountScript;

    function setUp() public {
        // Fork from base sepolia
        vm.createSelectFork("https://sepolia.base.org");
        vm.fee(1 gwei);
        
        // Set envs
        vm.setEnv(
            "PRIVATE_KEY", 
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privKey);
        vm.deal(deployer, 100 ether);
        vm.setEnv(
            "ACCOUNT_SALT", 
            "0x0000000000000000000000000000000000000000000000000000000000000002"
        );
        vm.setEnv(
            "SIGNER",
            "0x69bec2dd161d6bbcc91ec32aa44d9333ebc864c0"
        );

        // Deploy contracts
        address verifier = address(new Verifier());
        address dkimRegistry = address(new ECDSAOwnedDKIMRegistry(vm.envAddress("SIGNER")));
        address emailAuthImpl = address(new EmailAuth());
        address validatorAddr = address(new OwnableValidator());
        EmailRecoverySubjectHandler emailRecoveryHandler = new EmailRecoverySubjectHandler();

        address _factory = address(new EmailRecoveryFactory(verifier, emailAuthImpl));
        {
            EmailRecoveryFactory factory = EmailRecoveryFactory(_factory);
            (address module, address manager, address subjectHandler) = factory
                .deployEmailRecoveryModule(
                bytes32(uint256(0)),
                bytes32(uint256(0)),
                bytes32(uint256(0)),
                type(EmailRecoverySubjectHandler).creationCode,
                dkimRegistry,
                validatorAddr,
                bytes4(keccak256(bytes("changeOwner(address)")))
            );

            console.log("Deployed Email Recovery Module at", vm.toString(module));
            vm.setEnv("RECOVERY_MODULE", vm.toString(module));
            console.log("Deployed Email Recovery Manager at", vm.toString(manager));
            vm.setEnv("RECOVERY_MANAGER", vm.toString(manager));
            console.log("Deployed Email Recovery Handler at", vm.toString(subjectHandler));
        }
        deploy7579TestAccountScript = new Deploy7579TestAccountScript();
    }

    function test_run() public {
        deploy7579TestAccountScript.run();
    }
}
