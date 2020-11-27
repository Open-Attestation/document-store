// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@opengsn/gsn/contracts/forwarder/IForwarder.sol";
import "@opengsn/gsn/contracts/BasePaymaster.sol";

/**
 * @dev Implementation of the {BasePaymaster} interface.
 *
 * Contracts may inherit from this and call {setTarget}, {removeTarget} to declare
 * if they are willing to pay for relay call to given address.
 */
contract NaivePaymaster is BasePaymaster {
  string public name;
  string public version = "1.0.0";

  // TODO: Do we need a withdraw function?

  /**
   * @dev Mapping of the addresses we are willing to pay for.
   */
  mapping(address => bool) private targetAddresses;

  constructor(string memory _name) public {
    name = _name;
  }

  event TargetSet(address indexed target);
  event TargetRemoved(address indexed target);

  /**
   * @dev Registers the contract paymaster is willing to pay for.
   */
  function setTarget(address target) external onlyOwner {
    targetAddresses[target] = true;
    emit TargetSet(target);
  }

  /**
   * @dev Revoke the contract paymaster no longer willing to pay.
   */
  function removeTarget(address target) external onlyOwner {
    targetAddresses[target] = false;
    emit TargetRemoved(target);
  }

  /**
   * @dev Returns true if this paymaster willing to pay for relayed transaction
   * This function call must use less than 30 000 gas.
   */
  function supportsAddress(address target) external view returns (bool) {
    return targetAddresses[target];
  }

  event PreRelayed(uint256);
  event PostRelayed(uint256);

  function preRelayedCall(
    GsnTypes.RelayRequest calldata relayRequest,
    bytes calldata signature,
    bytes calldata approvalData,
    uint256 maxPossibleGas
  ) external virtual override returns (bytes memory context, bool) {
    _verifyForwarder(relayRequest);
    (signature, approvalData, maxPossibleGas);

    // check if relayed request is to a accepted address
    require(targetAddresses[relayRequest.request.to]);
    emit PreRelayed(now);
    return (abi.encode(now), false);
  }

  function postRelayedCall(
    bytes calldata context,
    bool success,
    uint256 gasUseWithoutPost,
    GsnTypes.RelayData calldata relayData
  ) external virtual override {
    (context, success, gasUseWithoutPost, relayData);
    emit PostRelayed(abi.decode(context, (uint256)));
  }

  function versionPaymaster() external virtual override view returns (string memory) {
    return version;
  }
}
