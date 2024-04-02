// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { DocumentStoreDeployScript } from "./DeployBase.s.sol";

contract ComputeInitializableAddresses is DocumentStoreDeployScript {
  function run() public view {
    bytes32 dsSalt = getDocumentStoreSalt();
    bytes32 tdsSalt = getTransferableDocumentStoreSalt();

    address dsComputedAddr = computeAddr(dsSalt);
    address tdsComputedAddr = computeAddr(tdsSalt);

    console2.log("Document Store Address: ", dsComputedAddr);
    console2.log("Transferable Document Store Address: ", tdsComputedAddr);
  }
}
