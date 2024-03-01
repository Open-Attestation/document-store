// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { DocumentStoreUpgradeable } from "../src/upgradeables/DocumentStoreUpgradeable.sol";
import { TransferableDocumentStoreUpgradeable } from "../src/upgradeables/TransferableDocumentStoreUpgradeable.sol";
import { CommonTest } from "./CommonTest.t.sol";
import { DeployUtils } from "../src/libraries/DeployUtils.sol";

contract DeployUtils_Test is CommonTest {
  string public initialName = "Test DocumentStore";
  string public initialSymbol = "TEST";

  function testDeployDocumentStoreUpgradeableParameters() public {
    (DocumentStoreUpgradeable dsProxy, DocumentStoreUpgradeable documentStore) = _runDeployDocumentStoreUpgradeable();

    assertEq(dsProxy.name(), initialName);
    assertTrue(dsProxy.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testDeployDocumentStorageUpgradeableImplementation() public {
    (DocumentStoreUpgradeable dsProxy, DocumentStoreUpgradeable documentStore) = _runDeployDocumentStoreUpgradeable();

    bytes32 proxyImpl = vm.load(address(dsProxy), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    assertEq(address(documentStore), address(uint160(uint256(proxyImpl))));
  }

  function testDeployTransferableDocumentStoreUpgradeableParameters() public {
    (
      TransferableDocumentStoreUpgradeable dsProxy,
      TransferableDocumentStoreUpgradeable documentStore
    ) = _runDeployTransferableDocumentStoreUpgradeable();

    assertEq(dsProxy.name(), initialName);
    assertEq(dsProxy.symbol(), initialSymbol);
    assertTrue(dsProxy.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testDeployTransferableDocumentStorageUpgradeableImplementation() public {
    (
      TransferableDocumentStoreUpgradeable dsProxy,
      TransferableDocumentStoreUpgradeable documentStore
    ) = _runDeployTransferableDocumentStoreUpgradeable();

    bytes32 proxyImpl = vm.load(address(dsProxy), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    assertEq(address(documentStore), address(uint160(uint256(proxyImpl))));
  }

  function _runDeployDocumentStoreUpgradeable()
    internal
    returns (DocumentStoreUpgradeable dsProxy, DocumentStoreUpgradeable ds)
  {
    (address proxyAddr, address dsAddr) = DeployUtils.deployDocumentStoreUpgradeable(initialName, owner);

    dsProxy = DocumentStoreUpgradeable(proxyAddr);
    ds = DocumentStoreUpgradeable(dsAddr);
  }

  function _runDeployTransferableDocumentStoreUpgradeable()
    internal
    returns (TransferableDocumentStoreUpgradeable dsProxy, TransferableDocumentStoreUpgradeable ds)
  {
    (address proxyAddr, address dsAddr) = DeployUtils.deployTransferableDocumentStoreUpgradeable(
      initialName,
      initialSymbol,
      owner
    );

    dsProxy = TransferableDocumentStoreUpgradeable(proxyAddr);
    ds = TransferableDocumentStoreUpgradeable(dsAddr);
  }
}
