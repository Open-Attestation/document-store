// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;
import "./IDocumentStore.sol";

interface IDocumentStoreBatchable is IDocumentStore {
  function revoke(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) external;

  function isIssued(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) external view returns (bool);

  function isRevoked(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) external view returns (bool);

  function isActive(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) external view returns (bool);
}
