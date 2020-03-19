export const DOCUMENT_STORE_CREATOR_ROPSTEN = "0x4077534e82C97Be03A07FB10f5c853d2bC7161FB";
export const DOCUMENT_STORE_CREATOR_MAINNET = "0x0";
export const PROXY_FACTORY_ROPSTEN = "0xba2501bf20593f156879c17d38b6c245ca65de80";
export const PROXY_FACTORY_MAINNET = "0x0";

export const getDocumentStoreCreatorAddress = (networkId?: number) => {
  if (networkId === 3) return DOCUMENT_STORE_CREATOR_ROPSTEN;
  return DOCUMENT_STORE_CREATOR_MAINNET;
};

export const getProxyFactoryAddress = (networkId?: number) => {
  if (networkId === 3) return PROXY_FACTORY_ROPSTEN;
  return PROXY_FACTORY_MAINNET;
};
