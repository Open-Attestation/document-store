// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;

/**
 * Interface carried over from OpenGSN v2.1.0
 * https://github.com/opengsn/gsn/blob/v2.1.0/contracts/interfaces/IKnowForwarderAddress.sol[Original Source]
 */
interface IKnowForwarderAddress {

  /**
   * return the forwarder we trust to forward relayed transactions to us.
   * the forwarder is required to verify the sender's signature, and verify
   * the call is not a replay.
   */
  function getTrustedForwarder() external view returns(address);
}
