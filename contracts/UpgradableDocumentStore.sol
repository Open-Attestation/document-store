// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./BaseDocumentStore.sol";

contract UpgradableDocumentStore is BaseDocumentStore, OwnableUpgradeable {
  function initialize(string memory _name, address owner) public initializer {
    super.__Ownable_init();
    super.transferOwnership(owner);
    BaseDocumentStore.initialize(_name);
  }

  function issue(bytes32 document) public override(BaseDocumentStore) onlyOwner onlyNotIssued(document) {
    BaseDocumentStore.issue(document);
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
