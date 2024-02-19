// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

contract OwnableDocumentStoreFixture {
  bytes32[] internal _documents;

  constructor() {
    _documents = [
      bytes32(0x795bb6abe4c5bb81e397821324d44bf7a94785587d0c88c621f57268c8aef4cb),
      bytes32(0x9bc394ef702b639adb913242a472e883f4834b4f38ed38f046bec8fcc1104fa3)
    ];
  }

  function documents() public view returns (bytes32[] memory) {
    return _documents;
  }
}
