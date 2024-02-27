// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import "./DeployBase.s.sol";
import "../src/upgradeables/OwnableDocumentStoreUpgradeable.sol";
import {DeployUtils} from "../src/libraries/DeployUtils.sol";

contract OwnableDocumentStoreUpgradeableScript is DeployBaseScript {
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

  function _requireParams(string memory name, string memory symbol, address admin) private pure {
    require(bytes(name).length > 0, "Name is required");
    require(bytes(symbol).length > 0, "Symbol is required");
    require(admin != address(0), "Admin address is required");
  }
}
