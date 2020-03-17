export const DOCUMENT_STORE_CREATOR_ROPSTEN = "0x4077534e82C97Be03A07FB10f5c853d2bC7161FB";
export const PROXY_FACTORY_ROPSTEN = "0xba2501bf20593f156879c17d38b6c245ca65de80";

let documentStoreCreatorAddressOverwrite: string;
let proxyFactoryAddressOverwrite: string;

export const getDocumentStoreCreatorAddress = () =>
  documentStoreCreatorAddressOverwrite || DOCUMENT_STORE_CREATOR_ROPSTEN;
export const getProxyFactoryAddress = () => proxyFactoryAddressOverwrite || PROXY_FACTORY_ROPSTEN;

export const overwriteDocumentStoreCreatorAddress = (address: string) => {
  documentStoreCreatorAddressOverwrite = address;
};
export const overwriteProxyFactoryAddress = (address: string) => {
  proxyFactoryAddressOverwrite = address;
};
