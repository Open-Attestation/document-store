// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "./DeployBase.s.sol";
import "../src/upgradeables/DocumentStoreUpgradeable.sol";
import {DeployUtils} from "../src/libraries/DeployUtils.sol";

contract DocumentStoreUpgradeableScript is DeployBaseScript {
  function run(string memory name, address admin) public returns (DocumentStoreUpgradeable ds) {
    _requireParams(name, admin);

    console2.log("DocumentStore Name: ", name);
    console2.log("DocumentStore Admin: ", admin);

    vm.broadcast();
    (address pAddr, ) = DeployUtils.deployDocumentStoreUpgradeable(name, admin);
    ds = DocumentStoreUpgradeable(pAddr);
  }

  function _requireParams(string memory name, address admin) private pure {
    require(bytes(name).length > 0, "Name is required");
    require(admin != address(0), "Admin address is required");
  }
}
