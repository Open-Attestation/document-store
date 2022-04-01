// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseDocumentStore.sol";

contract OwnableDocumentStore is BaseDocumentStore, Ownable {
  constructor(string memory _name) initializer {
    BaseDocumentStore.initialize(_name);
  }

  function issue(bytes32 document) public onlyOwner onlyNotIssued(document) {
    BaseDocumentStore._issue(document);
  }

  function bulkIssue(bytes32[] memory documents) public onlyOwner {
    BaseDocumentStore._bulkIssue(documents);
  }

  function revoke(bytes32 document) public onlyOwner onlyNotRevoked(document) returns (bool) {
    return BaseDocumentStore._revoke(document);
  }

  function bulkRevoke(bytes32[] memory documents) public onlyOwner {
    return BaseDocumentStore._bulkRevoke(documents);
  }
}
