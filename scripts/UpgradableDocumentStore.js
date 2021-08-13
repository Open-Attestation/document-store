const { ethers, upgrades } = require("hardhat");

// ---------- To Deploy -------------------
// async function main() {
//   try {
//     const DocumentStore = await ethers.getContractFactory("UpgradeableDocumentStore");
//     console.log("Deploying Document Store...");
//     const documentStore2 = await upgrades.deployProxy(
//       DocumentStore,
//       ["TestDocumentStore", "0x1245e5B64D785b25057f7438F715f4aA5D965733"],
//       { initializer: "initialize(string memory _name, address owner)" }
//     );
//     await documentStore2.deployed();
//     console.log("Document Store deployed to:", documentStore2.address);
//   } catch (e) {
//     console.log(e);
//   }
// }

// -------------- To Upgrade --------------
// async function main () {
//   try {
//     const DocumentStoreV2 = await ethers.getContractFactory('UpgradeableDocumentStore');
//     console.log('Upgrading Document Store...');
//     await upgrades.upgradeProxy('0x4F39E41c1E0819FB0Ad641f235d59B13f68e6FEf', DocumentStoreV2);
//     console.log('Document Store upgraded');

//   } catch (e) {
//     console.log(e);
//   }
// }

// --------------- To Retrieve ---------------

// async function main () {
//   try {
//     const DocumentStore = await ethers.getContractFactory('UpgradeableDocumentStore');
//     console.log('Retrieve document store...');
//     const documentStore2 = await DocumentStore.attach('0x4F39E41c1E0819FB0Ad641f235d59B13f68e6FEf');
//     console.log(await documentStore2.TestUpgradeV2());

//   } catch (e) {
//     console.log(e);
//   }
// }

main();
