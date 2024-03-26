// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../initializables/TransferableDocumentStoreInitializable.sol";

contract TransferableDocumentStoreUpgradeable is UUPSUpgradeable, TransferableDocumentStoreInitializable {
  function _authorizeUpgrade(address) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
