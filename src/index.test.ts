import { providers } from "ethers";
import { deploy, deployAndWait, connect } from "./index";
import { DocumentStoreCreator__factory as DocumentStoreCreatorFactory } from "./contracts";

const provider = new providers.JsonRpcProvider();
const signer = provider.getSigner();
let account: string;
let documentStoreCreatorAddressOverride: string;

beforeAll(async () => {
  // Deploy an instance of DocumentStoreFactory on the new blockchain
  const factory = new DocumentStoreCreatorFactory(signer);
  const receipt = await factory.deploy();
  documentStoreCreatorAddressOverride = receipt.address;
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
    const owner = await instance.owner();
    expect(owner).toBe(account);
    const name = await instance.name();
    expect(name).toBe("My Store");
  });
});

describe("connect", () => {
  it("connects to existing contract", async () => {
    const { address } = await deployAndWait("My Store", signer, { documentStoreCreatorAddressOverride });
    console.log(address);
    const instance = await connect(address, signer);
    const owner = await instance.owner();
    expect(owner).toBe(account);
    const name = await instance.name();
    expect(name).toBe("My Store");
  });
});
