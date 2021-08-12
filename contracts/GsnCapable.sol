// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract GsnCapable is ERC165Storage, Ownable {
  address public paymaster;
  bytes4 private constant _INTERFACE_ID_GSN_CAPABLE = 0xa5a23640;

  event PaymasterSet(address indexed target);

  constructor() {
    // register the supported interface to conform to TradeTrustERC721 via ERC165
    _registerInterface(_INTERFACE_ID_GSN_CAPABLE);
  }

  function setPaymaster(address target) external onlyOwner {
    paymaster = target;
    emit PaymasterSet(target);
  }

  function getPaymaster() external view returns (address) {
    return paymaster;
  }
}

contract CalculateGsnCapableSelector {
  function calculateSelector() public pure returns (bytes4) {
    GsnCapable i;
    return i.setPaymaster.selector ^ i.getPaymaster.selector;
  }
}
