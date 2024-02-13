// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {IDocumentStore} from "./interfaces/IDocumentStore.sol";
import "./base/DocumentStoreAccessControl.sol";
import "./interfaces/IOwnableDocumentStoere.sol";
import "./interfaces/IOwnableDocumentStoreErrors.sol";

contract OwnableDocumentStore is
  DocumentStoreAccessControl,
  ERC721Upgradeable,
  IOwnableDocumentStoreErrors,
  IOwnableDocumentStore
{
  mapping(uint256 => bool) private _revoked;

  constructor(string memory name_, string memory symbol_, address initAdmin) {
    initialize(name_, symbol_, initAdmin);
  }

  function initialize(string memory name_, string memory symbol_, address initAdmin) internal initializer {
    __OwnableDocumentStore_init(name_, symbol_, initAdmin);
  }

  function __OwnableDocumentStore_init(
    string memory name_,
    string memory symbol_,
    address initAdmin
  ) internal onlyInitializing {
    __ERC721_init(name_, symbol_);
    __DocumentStoreAccessControl_init(initAdmin);
  }

  function name() public view override(IDocumentStore, ERC721Upgradeable) returns (string memory) {
    return super.name();
  }

  function _isRevoked(uint256 tokenId) internal view returns (bool) {
    return _revoked[tokenId];
  }

  function isActive(bytes32 document) public view nonZeroDocument(document) returns (bool) {
    uint256 tokenId = uint256(document);
    address owner = _ownerOf(tokenId);
    if (owner == address(0) && _isRevoked(tokenId)) {
      return false;
    }
    if (owner != address(0) && !_isRevoked(tokenId)) {
      return true;
    }
    revert ERC721NonexistentToken(tokenId);
  }

  function issue(address to, bytes32 document) public nonZeroDocument(document) onlyRole(ISSUER_ROLE) {
    uint256 tokenId = uint256(document);
    if (!_isRevoked(tokenId)) {
      _mint(to, tokenId);
    } else {
      revert DocumentIsRevoked(document);
    }
  }

  function revoke(bytes32 document) public onlyRole(REVOKER_ROLE) {
    uint256 tokenId = uint256(document);
    _burn(tokenId);
    _revoked[tokenId] = true;
  }

  function isIssued(bytes32 document) public view nonZeroDocument(document) returns (bool) {
    uint256 tokenId = uint256(document);
    address owner = _ownerOf(tokenId);
    if (owner != address(0) || _isRevoked(tokenId)) {
      return true;
    }
    return false;
  }

  function isRevoked(bytes32 document) public view nonZeroDocument(document) returns (bool) {
    uint256 tokenId = uint256(document);
    address owner = _ownerOf(tokenId);
    if (owner == address(0)) {
      if (_isRevoked(tokenId)) {
        return true;
      }
      revert ERC721NonexistentToken(tokenId);
    }
    return false;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
    return
      interfaceId == type(IDocumentStore).interfaceId ||
      interfaceId == type(IOwnableDocumentStore).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  modifier nonZeroDocument(bytes32 document) {
    uint256 tokenId = uint256(document);
    if (tokenId == 0) {
      revert ZeroDocument();
    }
    _;
  }
}
