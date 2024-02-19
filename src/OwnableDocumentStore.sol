// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "./base/BaseOwnableDocumentStore.sol";

contract OwnableDocumentStore is BaseOwnableDocumentStore {
  constructor(string memory name_, string memory symbol_, address initAdmin) {
    initialize(name_, symbol_, initAdmin);
  }

  function initialize(string memory name_, string memory symbol_, address initAdmin) internal initializer {
    __OwnableDocumentStore_init(name_, symbol_, initAdmin);
  }
}
