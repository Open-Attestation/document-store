import {Signer, providers, ContractTransaction} from "ethers";
import {UpgradableDocumentStoreFactory} from "./contracts/UpgradableDocumentStoreFactory";
import {DocumentStoreCreatorFactory} from "./contracts/DocumentStoreCreatorFactory";
import {getDocumentStoreCreatorAddress} from "./config";

interface DeployOptions {
  documentStoreCreatorAddressOverride?: string;
}

export const deploy = async (name: string, signer: Signer, options?: DeployOptions): Promise<ContractTransaction> => {
  let documentStoreCreatorFactoryAddress = options?.documentStoreCreatorAddressOverride;
  if (!documentStoreCreatorFactoryAddress) {
    const chainId = (await signer.provider?.getNetwork())?.chainId;
    documentStoreCreatorFactoryAddress = getDocumentStoreCreatorAddress(chainId);
  }
  const factory = DocumentStoreCreatorFactory.connect(documentStoreCreatorFactoryAddress, signer);
  return factory.deploy(name);
};

export const deployAndWait = async (name: string, signer: Signer, options?: DeployOptions) => {
  const receipt = await (await deploy(name, signer, options)).wait();
  if (!receipt.logs || !receipt.logs[0].address) throw new Error("Fail to detect deployed contract address");
  return UpgradableDocumentStoreFactory.connect(receipt.logs![0].address, signer);
};

export const connect = async (address: string, signerOrProvider: Signer | providers.Provider) => {
  return UpgradableDocumentStoreFactory.connect(address, signerOrProvider);
};

export {UpgradableDocumentStoreFactory} from "./contracts/UpgradableDocumentStoreFactory";
export {DocumentStoreFactory} from "./contracts/DocumentStoreFactory";
export {GsnCapableDocumentStoreFactory} from "./contracts/GsnCapableDocumentStoreFactory";
export {DocumentStoreCreatorFactory} from "./contracts/DocumentStoreCreatorFactory";
export {NaivePaymasterFactory} from "./contracts/NaivePaymasterFactory";
