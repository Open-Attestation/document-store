import {Signer, providers, ContractTransaction} from "ethers";
import {DocumentStoreFactory} from "../types/ethers-contracts/DocumentStoreFactory";
import {DocumentStoreCreatorFactory} from "../types/ethers-contracts/DocumentStoreCreatorFactory";
import {getDocumentStoreCreatorAddress} from "./config";

export const deploy = async (name: string, signer: Signer): Promise<ContractTransaction> => {
  const chainId = (await signer.provider?.getNetwork())?.chainId || 1;
  const factory = DocumentStoreCreatorFactory.connect(getDocumentStoreCreatorAddress(chainId), signer);
  return factory.deploy(name);
};

export const deployAndWait = async (name: string, signer: Signer) => {
  const receipt = await (await deploy(name, signer)).wait();
  if (!receipt.logs || !receipt.logs[0].address) throw new Error("Fail to detect deployed contract address");
  return DocumentStoreFactory.connect(receipt.logs![0].address, signer);
};

export const connect = async (address: string, signerOrProvider: Signer | providers.Provider) => {
  return DocumentStoreFactory.connect(address, signerOrProvider);
};

export {DocumentStoreFactory} from "../types/ethers-contracts/DocumentStoreFactory";
