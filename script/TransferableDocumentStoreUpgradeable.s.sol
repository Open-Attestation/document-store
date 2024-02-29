// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { TransferableDocumentStoreDeployScript } from "./DeployBase.s.sol";
import { DeployUtils } from "../src/libraries/DeployUtils.sol";
import "../src/upgradeables/TransferableDocumentStoreUpgradeable.sol";

contract TransferableDocumentStoreUpgradeableScript is TransferableDocumentStoreDeployScript {
  function run(
    string memory name,
    string memory symbol,
    address admin
  ) public returns (TransferableDocumentStoreUpgradeable ds) {
    _requireParams(name, symbol, admin);

    console2.log("TransferableDocumentStore Name: ", name);
    console2.log("TransferableDocumentStore Symbol: ", symbol);
    console2.log("TransferableDocumentStore Admin: ", admin);

    vm.broadcast();
    (address pAddr, ) = DeployUtils.deployTransferableDocumentStoreUpgradeable(name, symbol, admin);
    ds = TransferableDocumentStoreUpgradeable(pAddr);
  }
}
