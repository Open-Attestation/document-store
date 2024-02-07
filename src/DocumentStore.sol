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
contract DocumentStore is DocumentStoreAccessControl, BaseDocumentStore {
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
   * @param documentRoot The hash of the document to issue
   */
  function issue(bytes32 documentRoot) public onlyRole(ISSUER_ROLE) {
    if (isIssued(documentRoot)) {
      revert DocumentExists(documentRoot);
    }

    _issue(documentRoot);

    emit DocumentIssued(documentRoot);
  }

  /**
   * @notice Issues multiple documents
   * @param documentRoots The hashes of the documents to issue
   */
  function bulkIssue(bytes32[] memory documentRoots) public {
    for (uint256 i = 0; i < documentRoots.length; i++) {
      issue(documentRoots[i]);
    }
  }

  /**
   * @notice Revokes a document
   * @param documentRoot The hash of the document to revoke
   */
  function revoke(bytes32 documentRoot) public onlyRole(REVOKER_ROLE) {
    revoke(documentRoot, documentRoot, new bytes32[](0));
  }

  function revoke(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) public onlyRole(REVOKER_ROLE) {
    bool active = isActive(documentRoot, document, proof);
    if (!active) {
      revert InactiveDocument(documentRoot, document);
    }
    _revoke(document);
    emit DocumentRevoked(documentRoot, document);
  }

  /**
   * @notice Revokes documents in bulk
   * @param documentRoots The hashes of the documents to revoke
   */
  function bulkRevoke(
    bytes32[] memory documentRoots,
    bytes32[] memory documents,
    bytes32[][] memory proofs
  ) public onlyRole(REVOKER_ROLE) {
    for (uint256 i = 0; i < documentRoots.length; i++) {
      revoke(documentRoots[i], documents[i], proofs[i]);
    }
  }

  function isIssued(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document, proof) returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _isIssued(document);
    }
    return _isIssued(documentRoot);
  }

  function isIssued(bytes32 documentRoot) public view returns (bool) {
    return isIssued(documentRoot, documentRoot, new bytes32[](0));
  }

  function isRevoked(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document, proof) returns (bool) {
    if (!isIssued(documentRoot, document, proof)) {
      revert InvalidDocument(documentRoot, document);
    }
    return _isRevokedInternal(documentRoot, document, proof);
  }

  function _isRevokedInternal(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) internal view returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _isRevoked(document);
    }
    return (_isRevoked(documentRoot) || _isRevoked(document));
  }

  /**
   * @notice Checks if a document has been revoked
   * @param documentRoot The hash of the document to check
   * @return A boolean indicating whether the document has been revoked
   */
  function isRevoked(bytes32 documentRoot) public view returns (bool) {
    return isRevoked(documentRoot, documentRoot, new bytes32[](0));
  }

  function isActive(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) public view returns (bool) {
    if (!isIssued(documentRoot, document, proof)) {
      revert InvalidDocument(documentRoot, document);
    }
    return !_isRevokedInternal(documentRoot, document, proof);
  }

  modifier onlyValidDocument(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) {
    if (document == 0x0 || documentRoot == 0x0) {
      revert ZeroDocument();
    }
    if (!proof.verify(documentRoot, document)) {
      revert InvalidDocument(documentRoot, document);
    }
    _;
  }
}
