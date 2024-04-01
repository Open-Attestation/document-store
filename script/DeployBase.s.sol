// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.23 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract DeployBaseScript is Script {
  address internal constant FACTORY = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;
  address internal constant DS_IMPL = 0xdF6514554ffE0ccD1BeA3470e9F06B377101A3da;
  address internal constant TDS_IMPL = 0xF8b2A0C86A945C618a771917Ea8B967464f461f5;

  constructor() {
    require(getDocumentStoreSalt() != getTransferableDocumentStoreSalt(), "Salts must be different");
  }

  function getSaltEntropy(string memory entropyName) internal view returns (bytes11) {
    bytes11 entropy = bytes11(vm.envOr({ name: entropyName, defaultValue: bytes("") }));
    require(entropy != bytes11(0), "Salt entropy not set");

    return entropy;
  }

  function getSalt(bytes11 entropy) internal view returns (bytes32 salt) {
    require(entropy != bytes11(0), "Salt entropy not be zero");

    address deployer = vm.envOr({ name: "DEPLOYER_ADDRESS", defaultValue: address(0) });
    require(deployer != address(0), "Deployer address not set");

    bytes20 deployerBytes = bytes20(deployer);

    salt = bytes32(abi.encodePacked(deployerBytes, bytes1(0x00), entropy));
  }

  function getDocumentStoreSalt() internal view returns (bytes32 salt) {
    bytes11 entropy = getSaltEntropy("SALT_DOCUMENT_STORE");
    salt = getSalt(entropy);
  }

  function getTransferableDocumentStoreSalt() internal view returns (bytes32 salt) {
    bytes11 entropy = getSaltEntropy("SALT_TRANSFERABLE_DOCUMENT_STORE");
    salt = getSalt(entropy);
  }

  function dsImplExists() internal view returns (bool) {
    return _exists(DS_IMPL);
  }

  function tdsImplExists() internal view returns (bool) {
    return _exists(TDS_IMPL);
  }

  function computeAddr(bytes32 salt) internal view returns (address) {
    bytes32 guardedSalt = _hash(bytes32(uint256(uint160(msg.sender))), salt);
    (bool ok, bytes memory data) = FACTORY.staticcall(
      abi.encodeWithSignature("computeCreate3Address(bytes32)", guardedSalt)
    );
    require(ok, "Error compute DocumentStoreInitializable address");
    return abi.decode(data, (address));
  }

  function deploy(bytes32 salt, bytes memory initCode) internal returns (address) {
    (bool ok, bytes memory data) = FACTORY.call(
      abi.encodeWithSignature("deployCreate3(bytes32,bytes)", salt, initCode)
    );
    require(ok, "Deployment failed");

    return abi.decode(data, (address));
  }

  function clone(address impl, bytes memory initData) internal returns (address) {
    (bool ok, bytes memory data) = FACTORY.call(
      abi.encodeWithSignature("deployCreate2Clone(address,bytes)", impl, initData)
    );
    require(ok, "Clone deployment failed");

    return abi.decode(data, (address));
  }

  function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 hash) {
    assembly ("memory-safe") {
      mstore(0x00, a)
      mstore(0x20, b)
      hash := keccak256(0x00, 0x40)
    }
  }

  function _exists(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }
}

abstract contract DocumentStoreDeployScript is DeployBaseScript {
  function _requireParams(string memory name, address admin) internal pure {
    require(bytes(name).length > 0, "Name is required");
    require(admin != address(0), "Admin address is required");
  }
}

abstract contract TransferableDocumentStoreDeployScript is DeployBaseScript {
  function _requireParams(string memory name, string memory symbol, address admin) internal pure {
    require(bytes(name).length > 0, "Name is required");
    require(bytes(symbol).length > 0, "Symbol is required");
    require(admin != address(0), "Admin address is required");
  }
}
