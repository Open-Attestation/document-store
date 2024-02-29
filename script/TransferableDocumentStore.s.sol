// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { TransferableDocumentStoreDeployScript } from "./DeployBase.s.sol";
import "../src/TransferableDocumentStore.sol";

contract TransferableDocumentStoreScript is TransferableDocumentStoreDeployScript {
  function run(string memory name, string memory symbol, address admin) public returns (TransferableDocumentStore ds) {
    _requireParams(name, symbol, admin);

    console2.log("TransferableDocumentStore Name: ", name);
    console2.log("TransferableDocumentStore Symbol: ", symbol);
    console2.log("TransferableDocumentStore Admin: ", admin);

    if (tdsImplExists()) {
      bytes memory initData = abi.encodeWithSignature("initialize(string,string,address)", name, symbol, admin);

      vm.broadcast();
      address dsAddr = clone(TDS_IMPL, initData);

      ds = TransferableDocumentStore(dsAddr);
    } else {
      vm.broadcast();
      ds = new TransferableDocumentStore(name, symbol, admin);
    }
  }
}
