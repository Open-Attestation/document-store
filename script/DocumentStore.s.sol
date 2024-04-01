// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { DocumentStoreDeployScript } from "./DeployBase.s.sol";
import "../src/DocumentStore.sol";

contract DocumentStoreScript is DocumentStoreDeployScript {
  function run(string memory name, address admin) public returns (DocumentStore ds) {
    _requireParams(name, admin);

    console2.log("DocumentStore Name: ", name);
    console2.log("DocumentStore Admin: ", admin);

    if (dsImplExists()) {
      bytes memory initData = abi.encodeWithSignature("initialize(string,address)", name, admin);

      vm.broadcast();
      address dsAddr = clone(DS_IMPL, initData);

      ds = DocumentStore(dsAddr);
      console2.log("Deployed Address: ", dsAddr);
    } else {
      vm.broadcast();
      ds = new DocumentStore(name, admin);
      console2.log("Deployed Address: ", address(ds));
    }
  }
}
