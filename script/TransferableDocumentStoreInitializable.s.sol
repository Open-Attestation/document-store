// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { TransferableDocumentStoreDeployScript } from "./DeployBase.s.sol";
import "../src/initializables/TransferableDocumentStoreInitializable.sol";

contract TransferableDocumentStoreInitializableScript is TransferableDocumentStoreDeployScript {
  function run() public returns (TransferableDocumentStoreInitializable documentStore) {
    require(!tdsImplExists(), "TransferableDocumentStoreInitializable already exists");

    bytes memory initCode = abi.encodePacked(type(TransferableDocumentStoreInitializable).creationCode);

    bytes32 dsSalt = getTransferableDocumentStoreSalt();

    address computedAddr = computeAddr(dsSalt);
    require(computedAddr == TDS_IMPL, "Bad deployment address");

    vm.broadcast();
    address dsAddr = deploy(dsSalt, initCode);

    documentStore = TransferableDocumentStoreInitializable(dsAddr);

    console2.log("Deployed Address: ", dsAddr);
  }
}
