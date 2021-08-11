// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./BaseDocumentStore.sol";

contract UpgradableDocumentStore is BaseDocumentStore, OwnableUpgradeable {
  function initialize(string memory _name, address owner) public initializer {
    super.__Ownable_init();
    super.transferOwnership(owner);
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
