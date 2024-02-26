// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/upgradeables/OwnableDocumentStoreUpgradeable.sol";
import {CommonTest} from "./CommonTest.t.sol";
import {DeployUtils} from "../src/utils/DeployUtils.sol";

contract OwnableDocumentStoreUpgradeable_Test is CommonTest {
  OwnableDocumentStoreUpgradeable public dsProxy;
  OwnableDocumentStoreUpgradeable public documentStore;

  string public initialName = "OwnableDocumentStore";
  string public initialSymbol = "TEST";

  function setUp() public override {
    super.setUp();

    (address proxyAddr, address dsAddr) = DeployUtils.deployOwnableDocumentStoreUpgradeable(
      initialName,
      initialSymbol,
      owner
    );
    dsProxy = OwnableDocumentStoreUpgradeable(proxyAddr);
    documentStore = OwnableDocumentStoreUpgradeable(dsAddr);
  }

  function testImplInitializedValues() public {
    assertEq(documentStore.name(), "");
    assertEq(documentStore.symbol(), "");
    assertFalse(documentStore.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testImplReinitialiseFail() public {
    vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

    documentStore.initialize("NewName", "TEST2", owner);
  }

  function testInitializeValues() public {
    assertEq(dsProxy.name(), initialName);
    assertEq(dsProxy.symbol(), initialSymbol);
    assertTrue(dsProxy.hasRole(documentStore.DEFAULT_ADMIN_ROLE(), owner));
  }

  function testFailReinitialize() public {
    dsProxy.initialize("NewName", "TEST2", owner);
  }

  function testUpgradeToAndCallAsNonAdmin() public {
    address nonAdmin = vm.addr(69);
    address newImplementation = address(new OwnableDocumentStoreUpgradeable());

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
    address newImplementation = address(new OwnableDocumentStoreUpgradeable());

    vm.prank(owner);
    dsProxy.upgradeToAndCall(newImplementation, "");

    bytes32 proxyImpl = vm.load(address(dsProxy), 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    assertEq(newImplementation, address(uint160(uint256(proxyImpl))));
  }

  function testUpgradeToAndCallReinitialiseFail() public {
    address newImplementation = address(new OwnableDocumentStoreUpgradeable());
    bytes memory initData = abi.encodeCall(
      OwnableDocumentStoreUpgradeable.initialize,
      (initialName, initialSymbol, owner)
    );

    vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

    vm.prank(owner);
    dsProxy.upgradeToAndCall(newImplementation, initData);
  }
}
