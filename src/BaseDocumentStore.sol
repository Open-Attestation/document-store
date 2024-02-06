// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IDocumentStore} from "./interfaces/IDocumentStore.sol";

/**
 * @title BaseDocumentStore
 * @notice A base contract for storing and revoking documents
 */
contract BaseDocumentStore is Initializable, IDocumentStore {
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
  function _issue(bytes32 document) internal {
    documentIssued[document] = block.number;
    // emit DocumentIssued(document);
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
   */
  function _revoke(bytes32 document) internal {
    documentRevoked[document] = block.number;
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
    require(_isIssued(document), "Error: Only issued document hashes can be revoked");
    _;
  }
}
