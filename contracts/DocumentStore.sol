// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./BaseDocumentStore.sol";
import "./base/DocumentStoreAccessControl.sol";

/**
 * @title DocumentStore
 * @notice A contract for storing and revoking documents with access control
 */
contract DocumentStore is BaseDocumentStore, DocumentStoreAccessControl {
  using MerkleProof for bytes32[];

  /**
   * @notice Initialises the contract with a name and owner
   * @param _name The name of the contract
   * @param owner The owner of the contract
   */
  constructor(string memory _name, address owner) {
    initialize(_name, owner);
  }

  /**
   * @notice Internally initialises the contract with a name and owner
   * @param _name The name of the contract
   * @param owner The owner of the contract
   */
  function initialize(string memory _name, address owner) internal initializer {
    __DocumentStoreAccessControl_init(owner);
    __BaseDocumentStore_init(_name);
  }

  /**
   * @notice Issues a document
   * @param document The hash of the document to issue
   */
  function issue(bytes32 documentRoot) public onlyRole(ISSUER_ROLE) onlyNotIssued(document) {
    BaseDocumentStore._issue(documentRoot);
  }

  /**
   * @notice Issues multiple documents
   * @param documents The hashes of the documents to issue
   */
  function bulkIssue(bytes32[] memory documentRoots) public onlyRole(ISSUER_ROLE) {
    BaseDocumentStore._bulkIssue(documentRoots);
  }

  /**
   * @notice Revokes a document
   * @param document The hash of the document to revoke
   * @return A boolean indicating whether the revocation was successful
   */
  function revoke(bytes32 document) public onlyRole(REVOKER_ROLE) onlyNotRevoked(document) returns (bool) {
    return BaseDocumentStore._revoke(document);
  }

  /**
   * @notice Revokes documents in bulk
   * @param documents The hashes of the documents to revoke
   */
  function bulkRevoke(bytes32[] memory documents) public onlyRole(REVOKER_ROLE) {
    return BaseDocumentStore._bulkRevoke(documents);
  }

  function isIssued(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view returns (bool) {
    require(document != 0x0 && documentRoot != 0x0, "Invalid document");
    if (documentRoot == document && proof.length == 0) {
      return _isIssued(document) && !isRevoked(document);
    }
    return
      _isIssued(documentRoot) &&
      !isRevoked(documentRoot) &&
      !isRevoked(document) &&
      proof.verify(documentRoot, document);
  }

  function isIssued(bytes32 documentRoot) public view returns (bool) {
    return isIssued(documentRoot, documentRoot, new bytes32[](0));
  }
}
