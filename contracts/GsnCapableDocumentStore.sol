// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.10;

import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";
import "@opengsn/gsn/contracts/interfaces/IKnowForwarderAddress.sol";

import "./DocumentStore.sol";
import "./GsnCapable.sol";

contract GsnCapableDocumentStore is DocumentStore, BaseRelayRecipient, IKnowForwarderAddress, GsnCapable {
  constructor(string memory _name, address _forwarder) public DocumentStore(_name) {
    trustedForwarder = _forwarder;
  }

  function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address payable) {
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

  function versionRecipient() external view virtual override returns (string memory) {
    return version;
  }
}
