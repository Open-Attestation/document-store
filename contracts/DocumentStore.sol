// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BaseDocumentStore.sol";
import "./base/DocumentStoreAccessControl.sol";

contract DocumentStore is BaseDocumentStore, DocumentStoreAccessControl {
  constructor(string memory _name, address owner) {
    initialize(_name, owner);
  }

  function initialize(string memory _name, address owner) internal initializer {
    __DocumentStoreAccessControl_init(owner);
    __BaseDocumentStore_init(_name);
  }

  function issue(bytes32 document) public onlyRole(ISSUER_ROLE) onlyNotIssued(document) {
    BaseDocumentStore._issue(document);
  }

  function bulkIssue(bytes32[] memory documents) public onlyRole(ISSUER_ROLE) {
    BaseDocumentStore._bulkIssue(documents);
  }

  function revoke(bytes32 document) public onlyRole(REVOKER_ROLE) onlyNotRevoked(document) returns (bool) {
    return BaseDocumentStore._revoke(document);
  }

  function bulkRevoke(bytes32[] memory documents) public onlyRole(REVOKER_ROLE) {
    return BaseDocumentStore._bulkRevoke(documents);
  }
}
