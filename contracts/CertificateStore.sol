pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract CertificateStore is Ownable {
  string public name;

  /// A mapping of the certificate hash to the block number that was issued
  mapping(bytes32 => uint) certificateIssued;
  /// A mapping of the hash of the claim being revoked to the revocation block number
  mapping(bytes32 => uint) certificateRevoked;

  event CertificateIssued(bytes32 indexed certificate);
  event CertificateRevoked(
    bytes32 indexed certificate
  );

  function CertificateStore(
    string _name
  ) public
  {
    name = _name;
  }

  function issueCertificate(
    bytes32 certificate
  ) public onlyOwner onlyNotIssuedCertificate(certificate)
  {
    certificateIssued[certificate] = block.number;
    CertificateIssued(certificate);
  }

  function getIssuedBlock(
    bytes32 certificate
  ) public onlyIssuedCertificate(certificate) view returns (uint)
  {
    return certificateIssued[certificate];
  }

  function isCertificateIssued(
    bytes32 certificate
  ) public view returns (bool)
  {
    return (certificateIssued[certificate] != 0);
  }

  function isCertificateIssuedBefore(
    bytes32 certificate,
    uint timestamp
  ) public view returns (bool)
  {
    return certificateIssued[certificate] != 0 && certificateIssued[certificate] <= timestamp;
  }

  function revokeCertificate(
    bytes32 certificate
  ) public onlyOwner onlyNotRevoked(certificate) returns (bool)
  {
    certificateRevoked[certificate] = block.number;
    CertificateRevoked(certificate);
  }

  function isRevoked(
    bytes32 certificate
  ) public view returns (bool)
  {
    return certificateRevoked[certificate] != 0;
  }

  function isRevokedBefore(
    bytes32 certificate,
    uint timestamp
  ) public view returns (bool)
  {
    return certificateRevoked[certificate] <= timestamp && certificateRevoked[certificate] != 0;
  }

  modifier onlyIssuedCertificate(bytes32 certificate) {
    require(isCertificateIssued(certificate));
    _;
  }

  modifier onlyNotIssuedCertificate(bytes32 certificate) {
    require(!isCertificateIssued(certificate));
    _;
  }

  modifier onlyNotRevoked(bytes32 claim) {
    require(!isRevoked(claim));
    _;
  }
}
