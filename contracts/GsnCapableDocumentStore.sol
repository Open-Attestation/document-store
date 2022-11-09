// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./DocumentStore.sol";
import "./GsnCapable.sol";
import "../interfaces/IKnowForwarderAddress.sol";

contract GsnCapableDocumentStore is DocumentStore, BaseRelayRecipient, IKnowForwarderAddress, GsnCapable {
  string public override versionRecipient = "2.0.0";

  constructor(string memory name, address owner, address _forwarder) DocumentStore(name, owner) {
    _setTrustedForwarder(_forwarder);
  }

  function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (address) {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (bytes memory) {
    return BaseRelayRecipient._msgData();
  }

  function getTrustedForwarder() public view override returns (address) {
    return trustedForwarder();
  }

  function setTrustedForwarder(address _forwarder) public onlyOwner {
    _setTrustedForwarder(_forwarder);
  }
}
