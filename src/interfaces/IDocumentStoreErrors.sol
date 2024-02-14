// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

interface IDocumentStoreErrors {
  error InactiveDocument(bytes32 documentRoot, bytes32 document);

  error DocumentExists(bytes32 document);

  error ZeroDocument();

  error InvalidDocument(bytes32 documentRoot, bytes32 document);

  error DocumentNotIssued(bytes32 documentRoot, bytes32 document);

  error DocumentIsRevoked(bytes32 documentRoot, bytes32 document);
}
