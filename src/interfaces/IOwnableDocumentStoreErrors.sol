// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

interface IOwnableDocumentStoreErrors {
  error InactiveDocument(bytes32 document);

  error DocumentExists(bytes32 document);

  error ZeroDocument();

  error DocumentIsRevoked(bytes32 document);

  error DocumentLocked(bytes32 document);
}
