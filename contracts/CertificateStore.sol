pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract CertificateStore is Ownable {
  string public verificationUrl;
  string public name;

  /// A mapping of the certificate batch merkle root to the block number that was issued
  mapping(bytes32 => uint) certificateIssued;
  /// A mapping of the hash of the claim being revoked to a revocation struct
  mapping(bytes32 => Revocation) certificateRevoked;

  event CertificateIssued(bytes32 indexed certificate);
  event CertificateRevoked(
    bytes32 indexed certificate,
    uint indexed revocationReason
  );

  /// A revocation
  ///
  /// See https://www.imsglobal.org/sites/default/files/Badges/OBv2p0/index.html#RevocationList
  /// for the details needed
  struct Revocation {
    // Merkle root of the batch
    bytes32 certificate;
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

  function issueCertificate(
    bytes32 certificate
  ) public onlyOwner onlyNotIssuedBatch(certificate)
  {
    certificateIssued[certificate] = block.number;
    CertificateIssued(certificate);
  }

  function getIssuedBlock(
    bytes32 certificate
  ) public onlyIssuedBatch(certificate) view returns (uint)
  {
    return certificateIssued[certificate];
  }

  function isCertificateIssued(
    bytes32 certificate
  ) public view returns (bool)
  {
    return (certificateIssued[certificate] != 0);
  }

  function revokeCertificate(
    bytes32 certificate,
    uint reason
  ) public onlyOwner onlyNotRevoked(certificate) returns (bool)
  {
    certificateRevoked[certificate] = Revocation(certificate, block.number, reason);
    CertificateRevoked(certificate, reason);
  }

  function isRevoked(
    bytes32 certificate
  ) public view returns (bool)
  {
    return certificateRevoked[certificate].blockNumber != 0;
  }

  modifier onlyIssuedBatch(bytes32 certificate) {
    require(isCertificateIssued(certificate));
    _;
  }

  modifier onlyNotIssuedBatch(bytes32 certificate) {
    require(!isCertificateIssued(certificate));
    _;
  }

  modifier onlyNotRevoked(bytes32 claim) {
    require(!isRevoked(claim));
    _;
  }
}
