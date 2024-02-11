// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "./base/BaseDocumentStore.sol";

/**
 * @title DocumentStore
 * @notice A contract for storing and revoking documents with access control
 */
contract DocumentStore is BaseDocumentStore {
  /**
   * @notice Initialises the contract with a name and initial admin
   * @param name The name of the contract
   * @param initAdmin The initial admin of the contract
   */
  constructor(string memory name, address initAdmin) {
    initialize(name, initAdmin);
  }

  /**
   * @notice Internally initialises the contract with a name and owner
   * @param _name The name of the contract
   * @param initAdmin The owner of the contract
   */
  function initialize(string memory _name, address initAdmin) internal initializer {
    __BaseDocumentStore_init(_name, initAdmin);
  }
}
