// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract DocumentStoreAccessControl is AccessControlUpgradeable {
  bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
  bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");

  function __DocumentStoreAccessControl_init(address owner) internal onlyInitializing {
    require(owner != address(0), "Owner is zero");
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _setupRole(ISSUER_ROLE, owner);
    _setupRole(REVOKER_ROLE, owner);
  }
}
