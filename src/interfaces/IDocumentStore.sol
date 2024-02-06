// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

interface IDocumentStore {
  error InactiveDocument(bytes32 documentRoot, bytes32 document);
  error DocumentExists(bytes32 document);
  error ZeroDocument();
  error InvalidDocument(bytes32 documentRoot, bytes32 document);

  /**
   * @notice Emitted when a document is issued
   * @param document The hash of the issued document
   */
  event DocumentIssued(bytes32 indexed document);

  /**
   * @notice Emitted when a document is revoked
   * @param document The hash of the revoked document
   */
  event DocumentRevoked(bytes32 indexed documentRoot, bytes32 indexed document);
}
