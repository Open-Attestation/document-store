// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

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
   * @notice Initialises the contract with a name and initial admin
   * @param _name The name of the contract
   * @param initAdmin The initial admin of the contract
   */
  constructor(string memory _name, address initAdmin) {
    initialize(_name, initAdmin);
  }

  /**
   * @notice Internally initialises the contract with a name and owner
   * @param _name The name of the contract
   * @param initAdmin The owner of the contract
   */
  function initialize(string memory _name, address initAdmin) internal initializer {
    __DocumentStoreAccessControl_init(initAdmin);
    __BaseDocumentStore_init(_name);
  }

  /**
   * @notice Issues a document
   * @param documentRoot The hash of the document to issue
   */
  function issue(bytes32 documentRoot) external onlyRole(ISSUER_ROLE) {
    _issue(documentRoot);
  }

  /**
   * @notice Issues multiple documents
   * @param documentRoots The hashes of the documents to issue
   */
  function bulkIssue(bytes32[] memory documentRoots) external onlyRole(ISSUER_ROLE) {
    for (uint256 i = 0; i < documentRoots.length; i++) {
      _issue(documentRoots[i]);
    }
  }

  function revoke(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) external onlyRole(REVOKER_ROLE) {
    _revoke(documentRoot, document, proof);
  }

  /**
   * @notice Revokes a document
   * @param documentRoot The hash of the document to revoke
   */
  function revoke(bytes32 documentRoot) external onlyRole(REVOKER_ROLE) {
    _revoke(documentRoot, documentRoot, new bytes32[](0));
  }

  /**
   * @notice Revokes documents in bulk
   * @param documentRoots The hashes of the documents to revoke
   */
  function bulkRevoke(
    bytes32[] memory documentRoots,
    bytes32[] memory documents,
    bytes32[][] memory proofs
  ) external onlyRole(REVOKER_ROLE) {
    for (uint256 i = 0; i < documentRoots.length; i++) {
      _revoke(documentRoots[i], documents[i], proofs[i]);
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
    return _isRevoked(documentRoot, document, proof);
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
    return !_isRevoked(documentRoot, document, proof);
  }

  function _issue(bytes32 documentRoot) internal override {
    if (isIssued(documentRoot)) {
      revert DocumentExists(documentRoot);
    }

    BaseDocumentStore._issue(documentRoot);

    emit DocumentIssued(documentRoot);
  }

  function _revoke(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) internal {
    bool active = isActive(documentRoot, document, proof);
    if (!active) {
      revert InactiveDocument(documentRoot, document);
    }
    _revoke(document);
    emit DocumentRevoked(documentRoot, document);
  }

  function _isRevoked(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) internal view returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _isRevoked(document);
    }
    return (_isRevoked(documentRoot) || _isRevoked(document));
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
