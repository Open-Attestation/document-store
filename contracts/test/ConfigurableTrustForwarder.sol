// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

contract ConfigurableTrustForwarder {
  function execute(
    bytes calldata data,
    address from,
    address to
  ) public returns (bool success, bytes memory ret) {
    (success, ret) = to.call(abi.encodePacked(data, from));
    require(success);
    return (success, ret);
  }
}
