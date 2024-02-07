// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "forge-std/Test.sol";

import "../src/DocumentStore.sol";

abstract contract BaseTest is Test {
  string public storeName = "DocumentStore Test";

  address public owner = vm.addr(1);
  address public issuer = vm.addr(2);
  address public revoker = vm.addr(3);

  DocumentStore public documentStore;

  function setUp() public virtual {
    vm.startPrank(owner);

    documentStore = new DocumentStore(storeName, owner);
    documentStore.grantRole(documentStore.ISSUER_ROLE(), issuer);
    documentStore.grantRole(documentStore.REVOKER_ROLE(), revoker);

    vm.stopPrank();
  }
}

abstract contract DocumentStoreWithFakeDocuments_Base is BaseTest {
  bytes32 public docRoot;
  bytes32[] public documents = new bytes32[](3);
  bytes32[][] public proofs = new bytes32[][](3);

  function setUp() public virtual override {
    super.setUp();

    docRoot = 0x5f0ed7e331c430ce34bcb45e2ddbff2b56a0f5971a226eee85f7ed6cc85e8e27;

    documents = [
      bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
      bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
      bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
    ];

    proofs = [
      [
        bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
        bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
      ],
      [
        bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
        bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
      ]
    ];
    proofs.push([bytes32(0x3763f4f892fb4c2ff4d76c4b9d391985568f8940f93f71283a84ff73277fb81e)]);
  }
}
