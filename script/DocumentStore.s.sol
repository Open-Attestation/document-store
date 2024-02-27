// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "./DeployBase.s.sol";
import "../src/DocumentStore.sol";

contract DocumentStoreScript is DeployBaseScript {
  function run(string memory name, address admin) public returns (DocumentStore ds) {
    _requireParams(name, admin);

    console2.log("DocumentStore Name: ", name);
    console2.log("DocumentStore Admin: ", admin);

    if (dsImplExists()) {
      bytes memory initData = abi.encodeWithSignature("initialize(string,address)", name, admin);

      vm.broadcast();
      address dsAddr = clone(DS_IMPL, initData);

      ds = DocumentStore(dsAddr);
    } else {
      vm.broadcast();
      ds = new DocumentStore(name, admin);
    }
  }

  function _requireParams(string memory name, address admin) private pure {
    require(bytes(name).length > 0, "Name is required");
    require(admin != address(0), "Admin address is required");
  }
}
