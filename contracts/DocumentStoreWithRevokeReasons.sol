// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./DocumentStore.sol";

contract DocumentStoreWithRevokeReasons is DocumentStore {
  /// A mapping of the document hash to the block number that was issued
  mapping(bytes32 => uint256) public revokeReason;

  event DocumentRevokedWithReason(bytes32 indexed document, uint256 reason);

  constructor(string memory _name, address owner) DocumentStore(_name, owner) {}

  function revoke(bytes32 document, uint256 reason)
    public
    onlyRole(REVOKER_ROLE)
    onlyNotRevoked(document)
    returns (bool)
  {
    revoke(document);
    revokeReason[document] = reason;
    emit DocumentRevokedWithReason(document, reason);

    return true;
  }

  function bulkRevoke(bytes32[] memory documents, uint256 reason) public {
    for (uint256 i = 0; i < documents.length; i++) {
      revoke(documents[i]);
      revokeReason[documents[i]] = reason;
      emit DocumentRevokedWithReason(documents[i], reason);
    }
  }
}
