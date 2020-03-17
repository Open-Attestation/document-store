pragma solidity 0.5.12;

import "./DocumentStore.sol";

contract DocumentStoreFactory {
  event DocumentStoreDeployed(address indexed instance, address indexed creator);

  function deploy(string memory name) public returns (address) {
    // solhint-disable-next-line mark-callable-contracts
    DocumentStore instance = new DocumentStore();
    instance.initialize(name, msg.sender);
    emit DocumentStoreDeployed(address(instance), msg.sender);
    return address(instance);
  }
}
