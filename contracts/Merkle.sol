pragma solidity ^0.4.18;

library Merkle {
  function verifyMerkleTreeProof(
    bytes32[] _proof,
    bytes32 _hash,
    bytes32 _root
  ) public pure returns (bool) {
    bytes32 hash = _hash;
    for(uint128 i=0; i<_proof.length; i++){
      if(hash < _proof[i]){
        hash = keccak256(hash, _proof[i]);
      }else{
        hash = keccak256(_proof[i], hash);
      }
    }
    
    return hash == _root;
  }
}