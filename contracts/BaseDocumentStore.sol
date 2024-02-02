// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title BaseDocumentStore
 * @notice A base contract for storing and revoking documents
 */
contract BaseDocumentStore is Initializable {
  /**
   * @notice The name of the contract
   */
  string public name;

  /**
   * @notice A mapping of the document hash to the block number that was issued
   */
  mapping(bytes32 => uint256) public documentIssued;

  /**
   * @notice A mapping of the hash of the claim being revoked to the revocation block number
   */
  mapping(bytes32 => uint256) public documentRevoked;

  /**
   * @notice Emitted when a document is issued
   * @param document The hash of the issued document
   */
  event DocumentIssued(bytes32 indexed document);

  /**
   * @notice Emitted when a document is revoked
   * @param document The hash of the revoked document
   */
  event DocumentRevoked(bytes32 indexed document);

  /**
   * @notice Initialises the contract with a name
   * @param _name The name of the contract
   */
  function __BaseDocumentStore_init(string memory _name) internal onlyInitializing {
    name = _name;
  }

  /**
   * @notice Issues a document
   * @param document The hash of the document to issue
   */
  function _issue(bytes32 document) internal onlyNotIssued(document) {
    documentIssued[document] = block.number;
    emit DocumentIssued(document);
  }

  /**
   * @notice Issues documents in bulk
   * @param documents The hashes of the documents to issue
   */
  function _bulkIssue(bytes32[] memory documents) internal {
    for (uint256 i = 0; i < documents.length; i++) {
      _issue(documents[i]);
    }
  }

  /**
   * @notice Gets the block number at which a document was issued
   * @param document The hash of the issued document
   * @return The block number at which the document was issued
   */
  function getIssuedBlock(bytes32 document) public view onlyIssued(document) returns (uint256) {
    return documentIssued[document];
  }

  /**
   * @notice Checks if a document has been issued
   * @param document The hash of the document to check
   * @return A boolean indicating whether the document has been issued
   */
  function _isIssued(bytes32 document) internal view returns (bool) {
    return (documentIssued[document] != 0);
  }

  /**
   * @notice Checks if a document was issued before a specific block number (inclusive)
   * @param document The hash of the document to check
   * @param blockNumber The block number to check against
   * @return A boolean indicating whether the document was issued before the specified block number
   */
  function isIssuedBefore(bytes32 document, uint256 blockNumber) public view returns (bool) {
    return documentIssued[document] != 0 && documentIssued[document] <= blockNumber;
  }

  /**
   * @notice Revokes a document
   * @param document The hash of the document to revoke
   * @return A boolean indicating whether the document was successfully revoked
   */
  function _revoke(bytes32 document) internal onlyNotRevoked(document) returns (bool) {
    documentRevoked[document] = block.number;
    emit DocumentRevoked(document);

    return true;
  }

  function _bulkRevoke(bytes32[] memory documents) internal {
    for (uint256 i = 0; i < documents.length; i++) {
      _revoke(documents[i]);
    }
  }

  /**
   * @notice Checks if a document has been revoked
   * @param document The hash of the document to check
   * @return A boolean indicating whether the document has been revoked
   */
  function _isRevoked(bytes32 document) internal view returns (bool) {
    return documentRevoked[document] != 0;
  }

  /**
   * @notice Checks if a document was revoked before a specific block number (inclusive)
   * @param document The hash of the document to check
   * @param blockNumber The block number to check against
   * @return A boolean indicating whether the document was revoked before the specified block number
   */
  function isRevokedBefore(bytes32 document, uint256 blockNumber) public view returns (bool) {
    return documentRevoked[document] <= blockNumber && documentRevoked[document] != 0;
  }

  /**
   * @dev Checks if a document has been issued
   * @param document The hash of the document to check
   */
  modifier onlyIssued(bytes32 document) {
    require(isIssued(document), "Error: Only issued document hashes can be revoked");
    _;
  }

  /**
   * @dev Checks if a document has not been issued
   * @param document The hash of the document to check
   */
  modifier onlyNotIssued(bytes32 document) {
    require(!isIssued(document), "Error: Only hashes that have not been issued can be issued");
    _;
  }

  /**
   * @dev Modifier that checks if a document has not been revoked
   * @param claim The hash of the document to check
   */
  modifier onlyNotRevoked(bytes32 claim) {
    require(!isRevoked(claim), "Error: Hash has been revoked previously");
    _;
  }
}
