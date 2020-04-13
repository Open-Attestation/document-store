pragma solidity 0.5.12;

import "./UpgradableDocumentStore.sol";

contract DocumentStoreWithRevokeReasons is UpgradableDocumentStore {
  /// A mapping of the document hash to the block number that was issued
  mapping(bytes32 => uint256) public revokeReason;

  event DocumentRevokedWithReason(bytes32 indexed document, uint256 reason);

  function revoke(bytes32 document, uint256 reason) public onlyOwner onlyNotRevoked(document) returns (bool) {
    revoke(document);
    revokeReason[document] = reason;
    emit DocumentRevokedWithReason(document, reason);
  }

  function bulkRevoke(bytes32[] memory documents, uint256 reason) public {
    for (uint256 i = 0; i < documents.length; i++) {
      revoke(documents[i]);
      revokeReason[documents[i]] = reason;
      emit DocumentRevokedWithReason(documents[i], reason);
    }
  }
}
