// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.10;

import "./Ownable.sol";
import "./DocumentStore.sol";
import "./GsnCapable.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";
import "@opengsn/gsn/contracts/interfaces/IKnowForwarderAddress.sol";

contract GsnCapableDocumentStore is DocumentStore, BaseRelayRecipient, IKnowForwarderAddress, GsnCapable {
  constructor(string memory _name, address _forwarder) public DocumentStore(_name) {
    trustedForwarder = _forwarder;
  }

  function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address payable) {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData() internal override(Context, BaseRelayRecipient) view returns (bytes memory) {
    return BaseRelayRecipient._msgData();
  }

  function getTrustedForwarder() public override view returns (address) {
    return trustedForwarder;
  }

  function setTrustedForwarder(address _forwarder) public onlyOwner {
    trustedForwarder = _forwarder;
  }

  function versionRecipient() external virtual override view returns (string memory) {
    return version;
  }
}
