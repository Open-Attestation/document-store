pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract CertificateStore is Ownable {
  string public verificationUrl;
  string public name;

  /// A mapping of the certificate batch merkle root to the block number that was issued
  mapping(bytes32 => uint) batchIssued;
  /// A mapping of the hash of the claim being revoked to a revocation struct
  mapping(bytes32 => Revocation) claimRevoked;

  event BatchIssued(bytes32 indexed batchRoot);
  event ClaimRevoked(
    bytes32 indexed claim,
    bytes32 indexed batchRoot,
    uint indexed revocationReason
  );

  /// A recovation
  ///
  /// See https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/index.html#RevocationList
  /// for the details needed
  struct Revocation {
    // Merkle root of the batch
    bytes32 batchRoot;
    /// Block number of revocation
    uint blockNumber;
    uint revocationReason;
  }

  function CertificateStore(
    string _verificationUrl,
    string _name
  ) public
  {
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

  function getIssuedBlock(
    bytes32 batchRoot
  ) public onlyIssuedBatch(batchRoot) view returns (uint)
  {
    return batchIssued[batchRoot];
  }

  function isBatchIssued(
    bytes32 batchRoot
  ) public view returns (bool)
  {
    return (batchIssued[batchRoot] != 0);
  }

  function revokeClaim(
    bytes32 batchRoot,
    bytes32 claim,
    bytes32[] proof,
    uint reason
  ) public onlyOwner onlyIssuedBatch(batchRoot) returns (bool)
  {
    require(verifyMerkleProof(proof, batchRoot, claim));
    claimRevoked[claim] = Revocation(batchRoot, block.number, reason);
    ClaimRevoked(claim, batchRoot, reason);
  }

  function isRevoked(
    bytes32 claim
  ) public view returns (bool)
  {
    return claimRevoked[claim].blockNumber != 0;
  }

  function verifyClaim(
    bytes32 batchRoot,
    bytes32 claim,
    bytes32[] proof
  ) public view returns (bool)
  {
    if (!isBatchIssued(batchRoot)) {
      return false;
    }
    return verifyMerkleProof(proof, batchRoot, claim);
  }

  /// Modified implementation of MerkleProof from zepplin-solidity
  /// Also checks that along the entire path, nothing has been revoked
  function verifyMerkleProof(
    bytes32[] _proof,
    bytes32 _root,
    bytes32 _leaf
  ) private view returns (bool)
  {

    if (isRevoked(_root) || isRevoked(_leaf)) {
      return false;
    }

    bytes32 proofElement;
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i ++) {
      proofElement = _proof[i];

      if (isRevoked(proofElement)) {
        return false;
      }

      if (computedHash < proofElement) {
        computedHash = keccak256(computedHash, proofElement);
      } else {
        computedHash = keccak256(proofElement, computedHash);
      }

      if (isRevoked(computedHash)) {
        return false;
      }
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

  modifier onlyNotRevoked(bytes32 claim) {
    require(!isRevoked(claim));
    _;
  }
}
