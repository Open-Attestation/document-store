// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { DocumentStoreDeployScript } from "./DeployBase.s.sol";
import { DeployUtils } from "../src/libraries/DeployUtils.sol";
import "../src/upgradeables/DocumentStoreUpgradeable.sol";

contract DocumentStoreUpgradeableScript is DocumentStoreDeployScript {
  function run(string memory name, address admin) public returns (DocumentStoreUpgradeable ds) {
    _requireParams(name, admin);

    console2.log("DocumentStore Name: ", name);
    console2.log("DocumentStore Admin: ", admin);

    vm.startBroadcast();
    (address pAddr, ) = DeployUtils.deployDocumentStoreUpgradeable(name, admin);
    vm.stopBroadcast();

    ds = DocumentStoreUpgradeable(pAddr);

    console2.log("Deployed Address: ", pAddr);
  }
}
