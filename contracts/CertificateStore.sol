pragma solidity ^0.4.4;

import "./Merkle.sol";

contract CertificateStore {
  address public owner;
  bytes32[] public certificates;
  string public verificationUrl;
  string public name;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function CertificateStore(
    string _verificationUrl,
    string _name
  ) public{
    owner = msg.sender;
    verificationUrl = _verificationUrl;
    name = _name;
  }

  function issueCertificate(
    bytes32 certificateRoot
  ) public onlyOwner returns (uint) {
    certificates.push(certificateRoot);
    return(certificates.length - 1);
  }

  function certificateIndex(
    bytes32 hash
  ) public view returns (uint) {
    for(uint i=0; i<certificates.length; i++){
      if(certificates[i] == hash) return i;
    }
    revert();
  }

  function checkProof(
    uint index,
    bytes32 claim,
    bytes32[] proof
  ) public view returns (bool) {
    if(index > certificates.length - 1 ){ revert(); }
    return Merkle.verifyMerkleTreeProof(proof, claim, certificates[index]);
  }
}
