// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IDocumentStore} from "./interfaces/IDocumentStore.sol";

/**
 * @title BaseDocumentStore
 * @notice A base contract for storing and revoking documents
 */
abstract contract BaseDocumentStore is Initializable, IDocumentStore {
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
}
