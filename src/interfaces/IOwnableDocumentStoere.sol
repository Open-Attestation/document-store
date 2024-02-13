// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import {IDocumentStore} from "./IDocumentStore.sol";

interface IOwnableDocumentStore is IDocumentStore {
  function issue(address to, bytes32 documentRoot) external;
}
