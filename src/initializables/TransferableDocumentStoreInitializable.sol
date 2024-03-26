// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "../base/BaseTransferableDocumentStore.sol";

contract TransferableDocumentStoreInitializable is BaseTransferableDocumentStore {
  constructor() initializer {}

  function initialize(string memory name_, string memory symbol_, address initAdmin) external initializer {
    __TransferableDocumentStore_init(name_, symbol_, initAdmin);
  }
}
