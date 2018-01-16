pragma solidity ^0.4.4;

contract CertificateStore {
  address public issuer;
  string public verificationUrl;
  string public name;

  // certificateIssued[certificateRoot] shows if the certificate is issued
  mapping(bytes32 => bool) certificateIssued;
  mapping(bytes32 => bool) certificateInvalidated;

  modifier onlyIssuer {
    require(msg.sender == issuer);
    _;
  }

  function CertificateStore(
    string _verificationUrl,
    string _name
  ) public{
    issuer = msg.sender;
    verificationUrl = _verificationUrl;
    name = _name;
  }

  function issueCertificate(
    bytes32 certificateRoot
  ) public onlyIssuer returns (bool) {
    certificateIssued[certificateRoot] = true;
    return true;
  }

  function invalidateCertificate(
    bytes32 certificateRoot
  ) public onlyIssuer returns (bool) {
    certificateInvalidated[certificateRoot] = true;
    return true;
  }

  function isIssued(
    bytes32 certificateRoot
  ) public view returns (bool) {
    return (certificateIssued[certificateRoot] == true);
  }

  function checkProof(
    bytes32 certificateRoot,
    bytes32 claim,
    bytes proof
  ) public view returns (bool) {
    if(!isIssued(certificateRoot)){ return false; }
    return merkleProofInvalidated(proof, certificateRoot, claim);
  }

  function merkleProofInvalidated(
    bytes _proof,
    bytes32 _root,
    bytes32 _leaf
  ) public view returns (bool) {
    // Check if proof length is a multiple of 32
    if (_proof.length % 32 != 0) {
      return false;
    }

    bytes32 proofElement;
    bytes32 computedHash = _leaf;

    for (uint256 i = 32; i <= _proof.length; i += 32) {
      assembly {
        // Load the current element of the proof
        proofElement := mload(add(_proof, i))
      }

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(proofElement, computedHash);
      }
    }

    if(certificateInvalidated[computedHash] == true) {
      return false;
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == _root;
  }
}
