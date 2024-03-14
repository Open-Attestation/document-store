// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

contract DocumentStoreFixture {
  bytes32[] internal _documents;

  constructor() {
    _documents = [
      bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
      bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
      bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
    ];
  }

  function documents() public view returns (bytes32[] memory) {
    return _documents;
  }
}

contract DocumentStoreBatchableFixture {
  bytes32 internal _docRoot;
  bytes32[] internal _documents = new bytes32[](3);
  bytes32[][] internal _proofs = new bytes32[][](3);

  constructor() {
    _docRoot = 0x5f0ed7e331c430ce34bcb45e2ddbff2b56a0f5971a226eee85f7ed6cc85e8e27;

    _documents = [
      bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
      bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
      bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
    ];

    _proofs = [
      [
        bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3),
        bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
      ],
      [
        bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
        bytes32(0x4aac698f1a67c980d0a52901fe4805775cc31beae66fb33bbb9dd89d30de81bd)
      ]
    ];
    _proofs.push([bytes32(0x3763f4f892fb4c2ff4d76c4b9d391985568f8940f93f71283a84ff73277fb81e)]);
  }

  function docRoot() public view returns (bytes32) {
    return _docRoot;
  }

  function documents() public view returns (bytes32[] memory) {
    return _documents;
  }

  function proofs() public view returns (bytes32[][] memory) {
    return _proofs;
  }
}
