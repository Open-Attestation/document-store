// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "./DeployBase.s.sol";
import "../src/initializables/OwnableDocumentStoreInitializable.sol";

contract OwnableDocumentStoreInitializableScript is DeployBaseScript {
  function run() public returns (OwnableDocumentStoreInitializable documentStore) {
    require(!dsImplExists(), "OwnableDocumentStoreInitializable already exists");

    bytes memory initCode = abi.encodePacked(type(OwnableDocumentStoreInitializable).creationCode);

    bytes32 dsSalt = getTransferableDocumentStoreSalt();

    address computedAddr = computeAddr(dsSalt);
    require(computedAddr == TDS_IMPL, "Bad deployment address");

    vm.broadcast();
    address dsAddr = deploy(dsSalt, initCode);

    documentStore = OwnableDocumentStoreInitializable(dsAddr);
  }
}
