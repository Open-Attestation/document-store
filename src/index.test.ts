import { JsonRpcProvider, JsonRpcSigner, ethers } from "ethers";
import { deploy, deployAndWait, connect } from "./index";
import { DocumentStoreCreator__factory as DocumentStoreCreatorFactory } from "./contracts";

const provider = new JsonRpcProvider();
let signer: JsonRpcSigner;
let account: string;
let documentStoreCreatorAddressOverride: string;

const adminRole = ethers.ZeroHash;
const issuerRole = ethers.id("ISSUER_ROLE");
const revokerRole = ethers.id("REVOKER_ROLE");

beforeAll(async () => {
  // Deploy an instance of DocumentStoreFactory on the new blockchain
  signer = await provider.getSigner();
  const factory = new DocumentStoreCreatorFactory(signer);
  const receipt = await factory.deploy();
  documentStoreCreatorAddressOverride = await receipt.getAddress();
  account = await signer.getAddress();
});

describe("deploy", () => {
  it("deploys a new DocumentStore contract without waiting for confirmation", async () => {
    const receipt = await deploy("My Store", signer, { documentStoreCreatorAddressOverride });
    expect(receipt.from).toBe(account);
  });
});

describe("deployAndWait", () => {
  it("deploys a new DocumentStore contract", async () => {
    const instance = await deployAndWait("My Store", signer, { documentStoreCreatorAddressOverride });

    const hasAdminRole = await instance.hasRole(adminRole, account);
    const hasIssuerRole = await instance.hasRole(issuerRole, account);
    const hasRevokerRole = await instance.hasRole(revokerRole, account);
    expect(hasAdminRole).toBe(true);
    expect(hasIssuerRole).toBe(true);
    expect(hasRevokerRole).toBe(true);

    const name = await instance.name();
    expect(name).toBe("My Store");
  });
});

describe("connect", () => {
  it("connects to existing contract", async () => {
    const documentStore = await deployAndWait("My Store", signer, { documentStoreCreatorAddressOverride });
    const address = await documentStore.getAddress();
    const instance = await connect(address, signer);
    const name = await instance.name();
    expect(name).toBe("My Store");
  });
});
