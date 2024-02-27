// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import {console2} from "forge-std/console2.sol";

import {OwnableDocumentStoreDeployScript} from "./DeployBase.s.sol";
import {DeployUtils} from "../src/libraries/DeployUtils.sol";
import "../src/upgradeables/OwnableDocumentStoreUpgradeable.sol";

contract OwnableDocumentStoreUpgradeableScript is OwnableDocumentStoreDeployScript {
  function run(
    string memory name,
    string memory symbol,
    address admin
  ) public returns (OwnableDocumentStoreUpgradeable ds) {
    _requireParams(name, symbol, admin);

    console2.log("OwnableDocumentStore Name: ", name);
    console2.log("OwnableDocumentStore Symbol: ", symbol);
    console2.log("OwnableDocumentStore Admin: ", admin);

    vm.broadcast();
    (address pAddr, ) = DeployUtils.deployOwnableDocumentStoreUpgradeable(name, symbol, admin);
    ds = OwnableDocumentStoreUpgradeable(pAddr);
  }
}
