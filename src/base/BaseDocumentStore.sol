// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.23 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "../interfaces/IDocumentStoreBatchable.sol";
import "./DocumentStoreAccessControl.sol";

/**
 * @title BaseDocumentStore
 * @notice A base contract for storing and revoking documents
 */
abstract contract BaseDocumentStore is
  Initializable,
  MulticallUpgradeable,
  DocumentStoreAccessControl,
  IDocumentStoreBatchable
{
  using MerkleProof for bytes32[];

  struct DocumentStoreStorage {
    /**
     * @notice The name of the contract
     */
    string name;
    /**
     * @notice A mapping of the document hash to the block number that was issued
     */
    mapping(bytes32 => uint256) documentIssued;
    /**
     * @notice A mapping of the hash of the claim being revoked to the revocation block number
     */
    mapping(bytes32 => uint256) documentRevoked;
  }

  // bytes32(uint256(keccak256("openattestation.storage.DocumentStore")) - 1)
  bytes32 private constant _DocumentStoreStorageSlot =
    0xd1729b464cf3942c060af2de854503be68723da388e8d702eabdad3958b7feb9;

  /**
   * @notice Initialises the contract with a name
   * @param _name The name of the contract
   */
  function __BaseDocumentStore_init(string memory _name, address initAdmin) internal onlyInitializing {
    __DocumentStoreAccessControl_init(initAdmin);
    _getStorage().name = _name;
  }

  function name() external view returns (string memory) {
    return _getStorage().name;
  }

  /**
   * @notice Issues a document
   * @param documentRoot The hash of the document to issue
   */
  function issue(
    bytes32 documentRoot
  ) external onlyValidDocument(documentRoot, documentRoot, new bytes32[](0)) onlyRole(ISSUER_ROLE) {
    _issue(documentRoot);
  }

  function revoke(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) external onlyRole(REVOKER_ROLE) {
    _revoke(documentRoot, document, proof);
  }

  /**
   * @notice Revokes a document
   * @param documentRoot The hash of the document to revoke
   */
  function revoke(bytes32 documentRoot) external onlyRole(REVOKER_ROLE) {
    _revoke(documentRoot, documentRoot, new bytes32[](0));
  }

  function isIssued(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document, proof) returns (bool) {
    return _isIssued(documentRoot, document, proof);
  }

  function isIssued(bytes32 documentRoot) public view returns (bool) {
    return isIssued(documentRoot, documentRoot, new bytes32[](0));
  }

  function isRevoked(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document, proof) returns (bool) {
    if (!_isIssued(documentRoot, document, proof)) {
      revert DocumentNotIssued(documentRoot, document);
    }
    return _isRevoked(documentRoot, document, proof);
  }

  /**
   * @notice Checks if a document has been revoked
   * @param documentRoot The hash of the document to check
   * @return A boolean indicating whether the document has been revoked
   */
  function isRevoked(bytes32 documentRoot) public view returns (bool) {
    return isRevoked(documentRoot, documentRoot, new bytes32[](0));
  }

  function isActive(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) public view onlyValidDocument(documentRoot, document, proof) returns (bool) {
    if (!_isIssued(documentRoot, document, proof)) {
      revert DocumentNotIssued(documentRoot, document);
    }
    return !_isRevoked(documentRoot, document, proof);
  }

  function isActive(bytes32 documentRoot) public view returns (bool) {
    return isActive(documentRoot, documentRoot, new bytes32[](0));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IDocumentStore).interfaceId ||
      interfaceId == type(IDocumentStoreBatchable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @notice Issues a document
   * @param documentRoot The hash of the document to issue
   */
  function _issue(bytes32 documentRoot) internal {
    if (_isIssued(documentRoot, documentRoot, new bytes32[](0))) {
      revert DocumentExists(documentRoot);
    }

    _setDocumentIssued(documentRoot, block.number);

    emit DocumentIssued(documentRoot);
  }

  function _revoke(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) internal {
    bool active = isActive(documentRoot, document, proof);
    if (!active) {
      revert InactiveDocument(documentRoot, document);
    }
    _setDocumentRevoked(document, block.number);
    emit DocumentRevoked(documentRoot, document);
  }

  function _isIssued(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) internal view returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _getDocumentIssued(document) != 0;
    }
    return _getDocumentIssued(documentRoot) != 0;
  }

  function _isRevoked(bytes32 documentRoot, bytes32 document, bytes32[] memory proof) internal view returns (bool) {
    if (documentRoot == document && proof.length == 0) {
      return _getDocumentRevoked(document) != 0;
    }
    return _getDocumentRevoked(documentRoot) != 0 || _getDocumentRevoked(document) != 0;
  }

  function _getStorage() internal pure returns (DocumentStoreStorage storage $) {
    assembly {
      $.slot := _DocumentStoreStorageSlot
    }
  }

  function _getDocumentIssued(bytes32 document) internal view returns (uint256) {
    return _getStorage().documentIssued[document];
  }

  function _setDocumentIssued(bytes32 document, uint256 blockNumber) internal {
    _getStorage().documentIssued[document] = blockNumber;
  }

  function _getDocumentRevoked(bytes32 document) internal view returns (uint256) {
    return _getStorage().documentRevoked[document];
  }

  function _setDocumentRevoked(bytes32 document, uint256 blockNumber) internal {
    _getStorage().documentRevoked[document] = blockNumber;
  }

  modifier onlyValidDocument(
    bytes32 documentRoot,
    bytes32 document,
    bytes32[] memory proof
  ) {
    if (document == 0x0 || documentRoot == 0x0) {
      revert ZeroDocument();
    }
    if (!proof.verify(documentRoot, document)) {
      revert InvalidDocument(documentRoot, document);
    }
    _;
  }
}
