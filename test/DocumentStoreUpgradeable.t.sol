// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/upgradeables/DocumentStoreUpgradeable.sol";
import {CommonTest} from "./CommonTest.t.sol";
import {DeployUtils} from "../src/libraries/DeployUtils.sol";

contract DocumentStoreUpgradeable_Test is CommonTest {
  DocumentStoreUpgradeable public dsProxy;
  DocumentStoreUpgradeable public documentStore;

  string public initialName = "DocumentStore";

  function setUp() public override {
    super.setUp();

    (address proxyAddr, address dsAddr) = DeployUtils.deployDocumentStoreUpgradeable(initialName, owner);
    dsProxy = DocumentStoreUpgradeable(proxyAddr);
    documentStore = DocumentStoreUpgradeable(dsAddr);
  }

  function testImplInitializedValues() public {
    assertEq(documentStore.name(), "");
    assertFalse(documentStore.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testImplReinitialiseFail() public {
    vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

    documentStore.initialize("NewName", owner);
  }

  function testInitializeValues() public {
    assertEq(dsProxy.name(), initialName);
    assertTrue(dsProxy.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testFailReinitialize() public {
    dsProxy.initialize("NewName", owner);
  }

  function testUpgradeToAndCallAsNonAdmin() public {
    address nonAdmin = vm.addr(69);
    address newImplementation = address(new DocumentStoreUpgradeable());

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        nonAdmin,
        documentStore.DEFAULT_ADMIN_ROLE()
      )
    );

    vm.prank(nonAdmin);
    dsProxy.upgradeToAndCall(newImplementation, "");
  }

  function testUpgradeToAndCallAsAdmin() public {
    address newImplementation = address(new DocumentStoreUpgradeable());

    vm.prank(owner);
    dsProxy.upgradeToAndCall(newImplementation, "");

    bytes32 proxyImpl = vm.load(address(dsProxy), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    assertEq(newImplementation, address(uint160(uint256(proxyImpl))));
  }

  function testUpgradeToAndCallReinitialiseFail() public {
    address newImplementation = address(new DocumentStoreUpgradeable());
    bytes memory initData = abi.encodeCall(DocumentStoreInitializable.initialize, (initialName, owner));

    vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

    vm.prank(owner);
    dsProxy.upgradeToAndCall(newImplementation, initData);
  }
}
