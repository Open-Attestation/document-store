// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../upgradeables/DocumentStoreUpgradeable.sol";
import "../upgradeables/TransferableDocumentStoreUpgradeable.sol";

library DeployUtils {
  function deployDocumentStoreUpgradeable(string memory name, address initAdmin) internal returns (address, address) {
    bytes memory initData = abi.encodeCall(DocumentStoreInitializable.initialize, (name, initAdmin));

    DocumentStoreUpgradeable documentStore = new DocumentStoreUpgradeable();
    address dsAddr = address(documentStore);

    ERC1967Proxy proxy = new ERC1967Proxy(dsAddr, initData);

    return (address(proxy), dsAddr);
  }

  function deployTransferableDocumentStoreUpgradeable(
    string memory name,
    string memory symbol,
    address initAdmin
  ) internal returns (address, address) {
    bytes memory initData = abi.encodeCall(
      TransferableDocumentStoreInitializable.initialize,
      (name, symbol, initAdmin)
    );

    TransferableDocumentStoreUpgradeable documentStore = new TransferableDocumentStoreUpgradeable();
    address dsAddr = address(documentStore);

    ERC1967Proxy proxy = new ERC1967Proxy(dsAddr, initData);

    return (address(proxy), dsAddr);
  }
}
