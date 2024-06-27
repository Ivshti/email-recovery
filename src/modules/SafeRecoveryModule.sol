// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ERC7579ExecutorBase } from "@rhinestone/modulekit/src/Modules.sol";
import { IERC7579Account } from "erc7579/interfaces/IERC7579Account.sol";
import { ExecutionLib } from "erc7579/lib/ExecutionLib.sol";
import { ModeLib } from "erc7579/lib/ModeLib.sol";

import { IRecoveryModule } from "../interfaces/IRecoveryModule.sol";
import { IEmailRecoveryManager } from "../interfaces/IEmailRecoveryManager.sol";

contract SafeRecoveryModule is ERC7579ExecutorBase, IRecoveryModule {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    address public immutable emailRecoveryManager;

    error NotTrustedRecoveryContract();
    error InvalidOldOwner();
    error InvalidNewOwner();

    constructor(address _emailRecoveryManager) {
        emailRecoveryManager = _emailRecoveryManager;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * Initialize the module with the given data
     * @param data The data to initialize the module with
     */
    function onInstall(bytes calldata data) external {
        (
            address[] memory guardians,
            uint256[] memory weights,
            uint256 threshold,
            uint256 delay,
            uint256 expiry
        ) = abi.decode(data, (address[], uint256[], uint256, uint256, uint256));

        _execute({
            to: emailRecoveryManager,
            value: 0,
            data: abi.encodeCall(
                IEmailRecoveryManager.configureRecovery, (guardians, weights, threshold, delay, expiry)
            )
        });
    }

    /**
     * De-initialize the module with the given data
     * @param data The data to de-initialize the module with
     */
    function onUninstall(bytes calldata data) external {
        IEmailRecoveryManager(emailRecoveryManager).deInitRecoveryFromModule(msg.sender);
    }

    /**
     * Check if the module is initialized
     * @param smartAccount The smart account to check
     * @return true if the module is initialized, false otherwise
     */
    function isInitialized(address smartAccount) external view returns (bool) {
        return IEmailRecoveryManager(emailRecoveryManager).getGuardianConfig(smartAccount).threshold
            != 0;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODULE LOGIC
    //////////////////////////////////////////////////////////////////////////*/

    function recover(address account, bytes calldata recoveryCalldata) external {
        if (msg.sender != emailRecoveryManager) {
            revert NotTrustedRecoveryContract();
        }

        IERC7579Account(account).executeFromExecutor(
            ModeLib.encodeSimpleSingle(), ExecutionLib.encodeSingle(account, 0, recoveryCalldata)
        );
    }

    /**
     * @notice Returns the address of the trusted recovery manager.
     * @return address The address of the email recovery manager.
     */
    function getTrustedRecoveryManager() external view returns (address) {
        return emailRecoveryManager;
    }

    function getAllowedValidators(address account) public view returns (address[] memory) {
        address[] memory result = new address[](1);
        result[0] = address(1);
        return result;
    }

    function getAllowedSelectors(address account) external view returns (bytes4[] memory) { }

    /*//////////////////////////////////////////////////////////////////////////
                                     METADATA
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * The name of the module
     * @return name The name of the module
     */
    function name() external pure returns (string memory) {
        return "SafeRecoveryModule";
    }

    /**
     * The version of the module
     * @return version The version of the module
     */
    function version() external pure returns (string memory) {
        return "0.0.1";
    }

    /**
     * Check if the module is of a certain type
     * @param typeID The type ID to check
     * @return true if the module is of the given type, false otherwise
     */
    function isModuleType(uint256 typeID) external pure returns (bool) {
        return typeID == TYPE_EXECUTOR;
    }
}
