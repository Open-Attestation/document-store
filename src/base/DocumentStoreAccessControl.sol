// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title DocumentStoreAccessControl
 * @notice Base contract for managing access control roles for a DocumentStore
 */
contract DocumentStoreAccessControl is AccessControlUpgradeable {
  bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
  bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");

  /**
   * @notice Initialises the contract with the given owner as the default admin, issuer, and revoker
   * @param owner The owner of the contract
   */
  function __DocumentStoreAccessControl_init(address owner) internal onlyInitializing {
    require(owner != address(0), "Owner is zero");
    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    _grantRole(ISSUER_ROLE, owner);
    _grantRole(REVOKER_ROLE, owner);
  }
}
