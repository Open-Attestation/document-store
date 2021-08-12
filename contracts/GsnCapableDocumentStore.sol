// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./OwnableDocumentStore.sol";
import "./GsnCapable.sol";
import "../interfaces/IKnowForwarderAddress.sol";

contract GsnCapableDocumentStore is OwnableDocumentStore, BaseRelayRecipient, IKnowForwarderAddress, GsnCapable {
  string public override versionRecipient = "2.0.0";

  constructor(string memory _name, address _forwarder) OwnableDocumentStore(_name) {
    trustedForwarder = _forwarder;
  }

  function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address) {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
    return BaseRelayRecipient._msgData();
  }

  function getTrustedForwarder() public view override returns (address) {
    return trustedForwarder;
  }

  function setTrustedForwarder(address _forwarder) public onlyOwner {
    trustedForwarder = _forwarder;
  }
}
