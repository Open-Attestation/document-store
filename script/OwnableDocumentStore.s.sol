// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { OwnableDocumentStoreDeployScript } from "./DeployBase.s.sol";
import "../src/OwnableDocumentStore.sol";

contract OwnableDocumentStoreScript is OwnableDocumentStoreDeployScript {
  function run(string memory name, string memory symbol, address admin) public returns (OwnableDocumentStore ds) {
    _requireParams(name, symbol, admin);

    console2.log("OwnableDocumentStore Name: ", name);
    console2.log("OwnableDocumentStore Symbol: ", symbol);
    console2.log("OwnableDocumentStore Admin: ", admin);

    if (tdsImplExists()) {
      bytes memory initData = abi.encodeWithSignature("initialize(string,string,address)", name, symbol, admin);

      vm.broadcast();
      address dsAddr = clone(TDS_IMPL, initData);

      ds = OwnableDocumentStore(dsAddr);
    } else {
      vm.broadcast();
      ds = new OwnableDocumentStore(name, symbol, admin);
    }
  }
}
