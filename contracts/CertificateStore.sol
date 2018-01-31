pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/ownership/HasNoEther.sol";


contract CertificateStore is HasNoEther {
  address public issuer;
  string public verificationUrl;
  string public name;

  event BatchIssued(bytes32 indexed batchRoot);

  /// A recovation
  ///
  /// See https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/index.html#RevocationList
  /// for the details needed
  struct Revocation {
    // Merkle root of the batch
    bytes32 batchMerkleRoot;
    /// Block number of revocation
    uint blockNumber;
    uint revocationReason;
  }

  /// A mapping of the certificate batch merkle root to the block number that was issued
  mapping(bytes32 => uint) batchIssued;
  /// A mapping of the hash of the certificate being revoked to a revocation struct
  // mapping(bytes32 => Revocation) certificateRevoked;
  mapping(bytes32 => bool) certificateRevoked;

  // modifier onlyBatchIssued(bytes32 merkleRoot) {
  //   Batch storage batch = batchIssued[merkleRoot]
  // }

  function CertificateStore(
    string _verificationUrl,
    string _name
  ) public
  {
    issuer = msg.sender;
    verificationUrl = _verificationUrl;
    name = _name;
  }

  function issueBatch(
    bytes32 batchRoot
  ) public onlyOwner onlyNotIssuedBatch(batchRoot)
  {
    batchIssued[batchRoot] = block.number;
    BatchIssued(batchRoot);
  }

  function revokeCertificate(
    bytes32 certificateHash
  ) public onlyOwner returns (bool)
  {
    certificateRevoked[certificateHash] = true;
    return true;
  }

  function isBatchIssued(
    bytes32 batchRoot
  ) public view returns (bool)
  {
    return (batchIssued[batchRoot] != 0);
  }

  function checkProof(
    bytes32 batchRoot,
    bytes32 claim,
    bytes32[] proof
  ) public view returns (bool)
  {
    if (!isBatchIssued(batchRoot)) {
      return false;
    }
    return merkleProofInvalidated(proof, batchRoot, claim);
  }

  // Modified implementation of MerkleProof from zepplin-solidity
  function merkleProofInvalidated(
    bytes32[] _proof,
    bytes32 _root,
    bytes32 _leaf
  ) private view returns (bool)
  {
    bytes32 proofElement;
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i ++) {
      proofElement = _proof[i];

      if (computedHash < proofElement) {
        computedHash = keccak256(computedHash, proofElement);
      } else {
        computedHash = keccak256(proofElement, computedHash);
      }
    }

    if (certificateRevoked[computedHash]) {
      return false;
    }

    return computedHash == _root;
  }

  modifier onlyIssuedBatch(bytes32 batchRoot) {
    require(isBatchIssued(batchRoot));
    _;
  }

  modifier onlyNotIssuedBatch(bytes32 batchRoot) {
    require(!isBatchIssued(batchRoot));
    _;
  }
}
