import { Signer, providers, ContractTransaction } from "ethers";
import {
  DocumentStoreCreator__factory as DocumentStoreCreatorFactory,
  UpgradeableDocumentStore__factory as UpgradeableDocumentStoreFactory,
} from "./contracts/";
import { getDocumentStoreCreatorAddress } from "./config";

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
  return UpgradeableDocumentStoreFactory.connect(receipt.logs![0].address, signer);
};

export const connect = async (address: string, signerOrProvider: Signer | providers.Provider) => {
  return UpgradeableDocumentStoreFactory.connect(address, signerOrProvider);
};

export {
  DocumentStore__factory as DocumentStoreFactory,
  DocumentStoreCreator__factory as DocumentStoreCreatorFactory,
  GsnCapableDocumentStore__factory as GsnCapableDocumentStoreFactory,
  NaivePaymaster__factory as NaivePaymasterFactory,
  UpgradeableDocumentStore__factory as UpgradeableDocumentStoreFactory,
} from "./contracts";
