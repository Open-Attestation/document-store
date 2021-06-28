// const { expect } = require("chai").use(require("chai-as-promised"));
// const config = require("../config.js");

// const NaivePaymaster = artifacts.require("./NaivePaymaster.sol");

// const assertTargetAddressLog = (logs, event, target) => {
//   expect(logs.event).to.deep.equal(event);
//   expect(logs.args[0]).to.deep.equal(target);
// };

// contract("NaivePaymaster", (accounts) => {
//   let instance = null;

//   // Related: https://github.com/trufflesuite/truffle-core/pull/98#issuecomment-360619561
//   beforeEach(async () => {
//     instance = await NaivePaymaster.new(config.INSTITUTE_NAME, { from: accounts[0] });
//   });

//   const sampleGsnCapableDocumentStoreAddress1 = "0x29e41C2b329fF4921d8AC654CEc909a0B575df20";
//   const sampleGsnCapableDocumentStoreAddress2 = "0x762A4D5F51d8b2F9bA1B0412B45687cE0EfFD92B";

//   describe("constructor", () => {
//     it("should have correct name", async () => {
//       const name = await instance.name();
//       expect(name).to.be.equal(config.INSTITUTE_NAME, "Name of institute does not match");
//     });
//   });

//   describe("version", () => {
//     it("should have a version field value that should be bumped on new versions of the contract", async () => {
//       const versionFromSolidity = await instance.version();
//       expect(versionFromSolidity).to.be.equal("1.0.0");
//     });

//     it("should return version when versionRecipient called", async () => {
//       const versionFromSolidity = await instance.versionPaymaster();
//       expect(versionFromSolidity).to.be.equal("1.0.0");
//     });
//   });

//   describe("targetAddresses", () => {
//     beforeEach(async () => {
//       await instance.setTarget(sampleGsnCapableDocumentStoreAddress1);
//     });

//     it("return true if target address is supported", async () => {
//       const isSupportedAddress = await instance.supportsAddress(sampleGsnCapableDocumentStoreAddress1);
//       expect(isSupportedAddress).to.be.true;
//     });

//     it("should set target address", async () => {
//       const receipt = await instance.setTarget(sampleGsnCapableDocumentStoreAddress2);

//       const setTargetLog = receipt.logs.find((log) => log.event === "TargetSet");
//       assertTargetAddressLog(setTargetLog, "TargetSet", sampleGsnCapableDocumentStoreAddress2);

//       const isSupportedAddress1 = await instance.supportsAddress(sampleGsnCapableDocumentStoreAddress1);
//       expect(isSupportedAddress1).to.be.true;
//       const isSupportedAddress2 = await instance.supportsAddress(sampleGsnCapableDocumentStoreAddress1);
//       expect(isSupportedAddress2).to.be.true;
//     });

//     it("should remove target address", async () => {
//       const removeTargetReceipt = await instance.removeTarget(sampleGsnCapableDocumentStoreAddress1);
//       const removeTargetLog = removeTargetReceipt.logs.find((log) => log.event === "TargetRemoved");
//       assertTargetAddressLog(removeTargetLog, "TargetRemoved", sampleGsnCapableDocumentStoreAddress1);

//       const isSupportedAddress = await instance.supportsAddress(sampleGsnCapableDocumentStoreAddress1);
//       expect(isSupportedAddress).to.be.false;
//     });
//   });
// });
