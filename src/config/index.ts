export const DOCUMENT_STORE_CREATOR_ROPSTEN = "0x4077534e82C97Be03A07FB10f5c853d2bC7161FB";
export const DOCUMENT_STORE_CREATOR_MAINNET = "0x0";
export const PROXY_FACTORY_ROPSTEN = "0xba2501bf20593f156879c17d38b6c245ca65de80";
export const PROXY_FACTORY_MAINNET = "0x0";

let documentStoreCreatorAddressOverwrite: string;
let proxyFactoryAddressOverwrite: string;

export const getDocumentStoreCreatorAddress = (networkId: number) => {
  switch (true) {
    case !!documentStoreCreatorAddressOverwrite:
      return documentStoreCreatorAddressOverwrite;
    case networkId === 3:
      return DOCUMENT_STORE_CREATOR_ROPSTEN;
    default:
      return DOCUMENT_STORE_CREATOR_MAINNET;
  }
};

export const getProxyFactoryAddress = (networkId: number) => {
  switch (true) {
    case !!proxyFactoryAddressOverwrite:
      return proxyFactoryAddressOverwrite;
    case networkId === 3:
      return PROXY_FACTORY_ROPSTEN;
    default:
      return PROXY_FACTORY_MAINNET;
  }
};

export const overwriteDocumentStoreCreatorAddress = (address: string) => {
  documentStoreCreatorAddressOverwrite = address;
};
export const overwriteProxyFactoryAddress = (address: string) => {
  proxyFactoryAddressOverwrite = address;
};
