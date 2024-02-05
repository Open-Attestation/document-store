//// SPDX-License-Identifier: Apache-2.0
//
//pragma solidity ^0.8.0;
//
//import "./DocumentStore.sol";
//
///**
// * @title DocumentStoreWithRevokeReasons
// * @notice A contract for storing and revoking documents with access control and reasons for revocation
// */
//contract DocumentStoreWithRevokeReasons is DocumentStore {
//  /**
//   * @notice A mapping of the document hash to the block number that was issued
//   */
//  mapping(bytes32 => uint256) public revokeReason;
//
//  /**
//   * @notice Emitted when a document is revoked with a reason
//   * @param document The hash of the revoked document
//   * @param reason The reason for revocation
//   */
//  event DocumentRevokedWithReason(bytes32 indexed document, uint256 reason);
//
//  /**
//   * @notice Initialises the contract with a name and owner
//   * @param _name The name of the contract
//   * @param owner The owner of the contract
//   */
//  constructor(string memory _name, address owner) DocumentStore(_name, owner) {}
//
//  /**
//   * @notice Revokes a document with a reason
//   * @param document The hash of the document to revoke
//   * @param reason The reason for revocation
//   * @return A boolean indicating whether the revocation was successful
//   */
//  function revoke(bytes32 document, uint256 reason)
//    public
//    onlyRole(REVOKER_ROLE)
//    onlyNotRevoked(document)
//    returns (bool)
//  {
//    revoke(document);
//    revokeReason[document] = reason;
//    emit DocumentRevokedWithReason(document, reason);
//
//    return true;
//  }
//
//  /**
//   * @notice Revokes documents in bulk with a reason
//   * @param documents The hashes of the documents to revoke
//   * @param reason The reason for revocation
//   */
//  function bulkRevoke(bytes32[] memory documents, uint256 reason) public {
//    for (uint256 i = 0; i < documents.length; i++) {
//      revoke(documents[i]);
//      revokeReason[documents[i]] = reason;
//      emit DocumentRevokedWithReason(documents[i], reason);
//    }
//  }
//}
