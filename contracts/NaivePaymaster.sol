// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@opengsn/gsn/contracts/forwarder/IForwarder.sol";
import "@opengsn/gsn/contracts/BasePaymaster.sol";

contract NaivePaymaster is BasePaymaster {
  address public ourTarget; // The target contract we are willing to pay for

  // allow the owner to set ourTarget
  event TargetSet(address target);
  function setTarget(address target) external onlyOwner {
    ourTarget = target;
    emit TargetSet(target);
  }

  event PreRelayed(uint256);
  event PostRelayed(uint256);

  function preRelayedCall(
    GsnTypes.RelayRequest calldata relayRequest,
    bytes calldata signature,
    bytes calldata approvalData,
    uint256 maxPossibleGas
  ) external override virtual returns (bytes memory context, bool) {
    _verifyForwarder(relayRequest);
    (signature, approvalData, maxPossibleGas);

    require(relayRequest.request.to == ourTarget);
    emit PreRelayed(now);
    return (abi.encode(now), false);
  }

  function postRelayedCall(
    bytes calldata context,
    bool success,
    uint256 gasUseWithoutPost,
    GsnTypes.RelayData calldata relayData
  ) external override virtual {
    (context, success, gasUseWithoutPost, relayData);
    emit PostRelayed(abi.decode(context, (uint256)));
  }

  function versionPaymaster() external view virtual override returns (string memory) {
    return "1.0";
  }

}
