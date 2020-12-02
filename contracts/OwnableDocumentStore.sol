// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseDocumentStore.sol";

contract OwnableDocumentStore is BaseDocumentStore, Ownable {
  constructor(string memory _name) public BaseDocumentStore(_name) {}

  function issue(bytes32 document) public override(BaseDocumentStore) onlyOwner onlyNotIssued(document) {
    return BaseDocumentStore.issue(document);
  }

  function revoke(bytes32 document)
    public
    override(BaseDocumentStore)
    onlyOwner
    onlyNotRevoked(document)
    returns (bool)
  {
    return BaseDocumentStore.revoke(document);
  }

}
