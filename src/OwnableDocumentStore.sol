// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./base/DocumentStoreAccessControl.sol";
import "./interfaces/IOwnableDocumentStore.sol";
import "./interfaces/IOwnableDocumentStoreErrors.sol";
import "./interfaces/IERC5192.sol";

contract OwnableDocumentStore is
  DocumentStoreAccessControl,
  ERC721Upgradeable,
  IERC5192,
  IOwnableDocumentStoreErrors,
  IOwnableDocumentStore
{
  /// @custom:storage-location erc7201:openattestation.storage.OwnableDocumentStore
  struct DocumentStoreStorage {
    mapping(uint256 => bool) revoked;
    mapping(uint256 => bool) locked;
  }

  // keccak256(abi.encode(uint256(keccak256("openattestation.storage.OwnableDocumentStore")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 private constant _DocumentStoreStorageSlot =
    0x5b868bb5de5c3e5f8f786d02cbc568987b1921539a10331babbe7311c24de500;

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

  function issue(address to, bytes32 document, bool lock) public nonZeroDocument(document) onlyRole(ISSUER_ROLE) {
    uint256 tokenId = uint256(document);
    if (!_isRevoked(tokenId)) {
      _mint(to, tokenId);
      if (lock) {
        _getStorage().locked[tokenId] = true;
        emit Locked(tokenId);
      } else {
        emit Unlocked(tokenId);
      }
    } else {
      revert DocumentIsRevoked(document);
    }
  }

  function revoke(bytes32 document) public onlyRole(REVOKER_ROLE) {
    uint256 tokenId = uint256(document);
    _burn(tokenId);
    _getStorage().revoked[tokenId] = true;
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
      interfaceId == type(IERC5192).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function locked(uint256 tokenId) public view returns (bool) {
    if (tokenId == 0) {
      revert ZeroDocument();
    }
    return _isLocked(tokenId);
  }

  function _isRevoked(uint256 tokenId) internal view returns (bool) {
    return _getStorage().revoked[tokenId];
  }

  function _isLocked(uint256 tokenId) internal view returns (bool) {
    return _getStorage().locked[tokenId];
  }

  function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
    address from = super._update(to, tokenId, auth);
    if (_isLocked(tokenId) && (from != address(0) && to != address(0))) {
      revert DocumentLocked(bytes32(tokenId));
    }
    return from;
  }

  function _getStorage() private pure returns (DocumentStoreStorage storage $) {
    assembly {
      $.slot := _DocumentStoreStorageSlot
    }
  }

  modifier nonZeroDocument(bytes32 document) {
    uint256 tokenId = uint256(document);
    if (tokenId == 0) {
      revert ZeroDocument();
    }
    _;
  }
}
