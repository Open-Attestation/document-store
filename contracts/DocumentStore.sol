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
  error InactiveDocument(bytes32 documentRoot, bytes32 document);
  error DocumentAlreadyRevoked(bytes32 document);
  error DocumentAlreadyIssued(bytes32 document);
  error InvalidDocument();

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
  function issue(bytes32 documentRoot) public onlyRole(ISSUER_ROLE) {
    if (isRootIssued(documentRoot)) {
      revert DocumentAlreadyIssued(documentRoot);
    }

    _issue(documentRoot);

    emit DocumentIssued(documentRoot);
  }

  /**
   * @notice Issues multiple documents
   * @param documents The hashes of the documents to issue
   */
  function bulkIssue(bytes32[] memory documentRoots) public onlyRole(ISSUER_ROLE) {
    _bulkIssue(documentRoots);
  }

  /**
   * @notice Revokes a document
   * @param document The hash of the document to revoke
   * @return A boolean indicating whether the revocation was successful
   */
  function revokeRoot(bytes32 documentRoot) public onlyRole(REVOKER_ROLE) {
    revoke(documentRoot, documentRoot, new bytes32[](0));
  }

  function revoke(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public onlyRole(REVOKER_ROLE) {
    bool isActive = isActive(documentRoot, document, proof);
    if (!isActive) {
      revert InActiveDocument(documentRoot, document);
    }
    _revoke(document);
    emit DocumentRevoked(documentRoot, document);
  }

  /**
   * @notice Revokes documents in bulk
   * @param documents The hashes of the documents to revoke
   */
  function bulkRevoke(
    bytes32[] documentRoots,
    bytes32[] documents,
    bytes32[][] memory proofs
  ) public onlyRole(REVOKER_ROLE) {
    for (uint256 i = 0; i < documentRoots.length; i++) {
      revoke(documentRoots[i], documents[i], proofs[i]);
    }
  }

  function bulkRevokeRoot(bytes32[] documentRoots, bytes32[][] memory proofs) public onlyRole(REVOKER_ROLE) {
    for (uint256 i = 0; i < documentRoots.length; i++) {
      revoke(documentRoots[i], documentRoots[i], proofs[i]);
    }
  }

  function isIssued(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document) returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _isIssued(document);
    }
    return _isIssued(documentRoot) && proof.verify(documentRoot, document);
  }

  function isRootIssued(bytes32 documentRoot) public view returns (bool) {
    return isIssued(documentRoot, documentRoot, new bytes32[](0));
  }

  function isRevoked(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document) returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _isRevoked(document);
    }
    return (_isRevoked(documentRoot) || _isRevoked(document)) && proof.verify(documentRoot, document);
  }

  /**
   * @notice Checks if a document has been revoked
   * @param document The hash of the document to check
   * @return A boolean indicating whether the document has been revoked
   */
  function isRootRevoked(bytes32 documentRoot) public view returns (bool) {
    return isRevoked(documentRoot, documentRoot, new bytes32[](0));
  }

  function isActive(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view returns (bool) {
    return isIssued(documentRoot, document, proof) && !isRevoked(documentRoot, document, proof);
  }

  modifier onlyValidDocument(bytes32 documentRoot, bytes32 document) {
    if (document == 0x0 || documentRoot == 0x0) {
      revert InvalidDocument();
    }
    _;
  }
}
