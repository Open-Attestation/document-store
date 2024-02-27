// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "../base/BaseOwnableDocumentStore.sol";

contract OwnableDocumentStoreInitializable is BaseOwnableDocumentStore {
  constructor() initializer {}

  function initialize(string memory name_, string memory symbol_, address initAdmin) public initializer {
    __OwnableDocumentStore_init(name_, symbol_, initAdmin);
  }
}
