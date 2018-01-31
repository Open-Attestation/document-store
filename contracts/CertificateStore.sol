pragma solidity ^0.4.4;


contract CertificateStore {
  address public issuer;
  string public verificationUrl;
  string public name;

  mapping(bytes32 => bool) certificateIssued;
  mapping(bytes32 => bool) certificateInvalidated;

  modifier onlyIssuer {
    require(msg.sender == issuer);
    _;
  }

  function CertificateStore(
    string _verificationUrl,
    string _name
  ) public
  {
    issuer = msg.sender;
    verificationUrl = _verificationUrl;
    name = _name;
  }

  function issueCertificate(
    bytes32 certificateRoot
  ) public onlyIssuer returns (bool)
  {
    certificateIssued[certificateRoot] = true;
    return true;
  }

  function invalidateCertificate(
    bytes32 certificateRoot
  ) public onlyIssuer returns (bool)
  {
    certificateInvalidated[certificateRoot] = true;
    return true;
  }

  function isIssued(
    bytes32 certificateRoot
  ) public view returns (bool)
  {
    return (certificateIssued[certificateRoot] == true);
  }

  function checkProof(
    bytes32 certificateRoot,
    bytes32 claim,
    bytes32[] proof
  ) public view returns (bool)
  {
    if (!isIssued(certificateRoot)) {
      return false;
    }
    return merkleProofInvalidated(proof, certificateRoot, claim);
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

    if (certificateInvalidated[computedHash]) {
      return false;
    }

    return computedHash == _root;
  }
}
