// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { DocumentStoreDeployScript } from "./DeployBase.s.sol";
import "../src/initializables/DocumentStoreInitializable.sol";

contract DocumentStoreInitializableScript is DocumentStoreDeployScript {
  function run() public returns (DocumentStoreInitializable documentStore) {
    require(!dsImplExists(), "DocumentStoreInitializable already exists");

    bytes memory initCode = abi.encodePacked(type(DocumentStoreInitializable).creationCode);

    bytes32 dsSalt = getDocumentStoreSalt();

    address computedAddr = computeAddr(dsSalt);
    require(computedAddr == DS_IMPL, "Bad deployment address");

    vm.broadcast();
    address dsAddr = deploy(dsSalt, initCode);

    documentStore = DocumentStoreInitializable(dsAddr);

    console2.log("Deployed Address: ", dsAddr);
  }
}
