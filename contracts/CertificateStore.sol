pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/MerkleProof.sol";

contract CertificateStore {
  address public issuer;
  string public verificationUrl;
  string public name;

  // certificateIssued[certificateRoot] shows if the certificate is issued
  mapping(bytes32 => bool) certificateIssued;

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
    return MerkleProof.verifyProof(proof, certificateRoot, claim);
  }
}
