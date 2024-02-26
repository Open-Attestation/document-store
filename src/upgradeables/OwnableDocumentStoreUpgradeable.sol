// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../base/BaseOwnableDocumentStore.sol";

contract OwnableDocumentStoreUpgradeable is UUPSUpgradeable, BaseOwnableDocumentStore {
  constructor() initializer {}

  function initialize(string memory name_, string memory symbol_, address initAdmin) public initializer {
    __OwnableDocumentStore_init(name_, symbol_, initAdmin);
  }

  function _authorizeUpgrade(address) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
