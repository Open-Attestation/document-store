<h1 align="center">
  <p align="center">Document Store</p>
  <img src="https://github.com/Open-Attestation/document-store/blob/master/docs/images/document-store-banner.png?raw=true" alt="OpenAttestation Document Store" />
</h1>

<p align="center">
    Document Store Smart Contracts for the <a href="https://www.openattestation.com">OpenAttestation</a> framework
</p>

<p align="center">
  <a href="https://github.com/Open-Attestation/document-store/actions" alt="Build Status"><img src="https://github.com/Open-Attestation/document-store/actions/workflows/release.yml/badge.svg" /></a>
  <a href="https://codecov.io/gh/Open-Attestation/document-store" alt="Code Coverage"><img src="https://codecov.io/gh/Open-Attestation/document-store/branch/master/graph/badge.svg?token=Y4R9SWXATG" /></a>
  <a href="https://github.com/Open-Attestation/document-store/blob/master/LICENSE" alt="License"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" /></a>
</p>

The Document Store is a set of smart contracts for managing the issuance and revocation of documents. It is designed to be used in conjunction with the [OpenAttestation](https://github.com/Open-Attestation/open-attestation) library to issue and verify documents on the blockchains.

There are 2 types of document stores, namely, the regular _Document Store_ and the _Transferable Document Store_.

#### Document Store

The regular _Document Store_ allows issuers to issue and revoke documents. However, these documents do not have an owner and are, hence, not transferable. Multiple documents issued on the Document Store can be "batched" under a single hash for issuance.

#### Transferable Document Store

The _Transferable Document Store_ allows issuers to issue and revoke documents, and these documents have an owner and are transferable. Each document is essentially an ERC-721 NFT (Non-Fungible Token). Thus, documents are issued individually and the document holder's identity can be verified. Although the documents are transferable, they can also be issued as "soulbound" documents which bounds to an owner. This can be particularly useful for certain use cases such as POAP.

---

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Document Store](#document-store-1)
  - [Transferable Document Store](#transferable-document-store-1)
  - [Roles and Access](#roles-and-access)
- [Deployment](#deployment)
  - [Document Store](#document-store-2)
  - [Transferable Document Store](#transferable-document-store-2)
  - [Hardware Wallet](#hardware-wallet)
  - [Verification](#verification)
  - [Supported Networks](#supported-networks)
- [Configuration](#configuration)
- [Development](#development)
- [Additional Information](#additional-information)

---

## Installation

To make integration easier, we have provided the packages containing the Typechain bindings for interacting with the document store.

#### Using with ethers.js v6

```sh
npm install @govtechsg/document-store-ethers-v6
```

#### Using with ethers.js v5

```sh
npm install @govtechsg/document-store-ethers-v5
```

## Usage

### Document Store

For a complete list of functions, refer to [IDocumentStoreBatchable.sol](https://github.com/Open-Attestation/document-store/blob/master/src/interfaces/IDocumentStoreBatchable.sol).

#### Issuing a document:

```typescript
import { DocumentStore__factory } from "@govtechsg/document-store-ethers-v6"; // Or from "@govtechsg/document-store-ethers-v5"

const documentStore = DocumentStore__factory.connect(documentStoreAddress, signer);
const tx = await documentStore["issue"]("0x1234");
await tx.wait();
```

#### Checking if a document in a batch is issued:

```typescript
const oaDocumentSignature = {
  documentRoot: "0xMerkleRoot",
  targetHash: "0xTargetHash",
  proof: ["0xProof1", "0xProof2"]
};

const documentStore = DocumentStore__factory.connect(documentStoreAddress, signer);
const tx = await documentStore["issue"](oaDocumentSignature.documentRoot);
await tx.wait();

try {
  const isDocIssued = await documentStore.isIssued(
    oaDocumentSignature.documentRoot,
    oaDocumentSignature.targetHash,
    oaDocumentSignature.proof
  );

  console.log(isDocIssued); // Returns true or false
} catch (e) {
  // Error will be thrown if proof is invalid
  console.error(e);
}
```

#### Bulk issuing documents:

Note that this is different from batching. This issues multiple documents or document roots at once.

```typescript
const documentStore = DocumentStore__factory.connect(documentStoreAddress, signer);
const bulkIssuances = [
  documentStore.interface.encodeFunctionData("issue", ["0xDocRoot1"]),
  documentStore.interface.encodeFunctionData("issue", ["0xDocRoot2"])
];
const tx = await documentStore.multicall(bulkIssuances);
await tx.wait();
```

#### Revoking a document root:

```typescript
const documentStore = DocumentStore__factory.connect(documentStoreAddress, signer);
const tx = await documentStore["revoke"]("0x1234");
await tx.wait();
```

#### Revoking a document in a batch:

```typescript
const documentStore = DocumentStore__factory.connect(documentStoreAddress, signer);
const tx = await documentStore["revoke"]("0xDocumentRoot", "0xTargetHash", ["0xProof1", "0xProof2"]);
await tx.wait();
```

#### Revoking multiple documents:

```typescript
const documentStore = DocumentStore__factory.connect(documentStoreAddress, signer);
const bulkRevokations = [
  documentStore.interface.encodeFunctionData("revoke", ["0xDocRoot1"]),
  documentStore.interface.encodeFunctionData("revoke", ["0xDocRoot2"])
];
const tx = await documentStore.multicall(bulkRevokations);
await tx.wait();
```

### Transferable Document Store

For a complete list of functions, refer to [ITransferableDocumentStore.sol](https://github.com/Open-Attestation/document-store/blob/master/src/interfaces/ITransferableDocumentStore.sol).

#### Issuing a transferable document:

```typescript
import { TransferableDocumentStore__factory } from "@govtechsg/document-store-ethers-v6"; // Or from "@govtechsg/document-store-ethers-v5"

const transferableDocumentStore = TransferableDocumentStore__factory.connect(transferableDocumentStoreAddress, signer);

// Issues a transferable document
const tx = await transferableDocumentStore.issue("0xRecipientAddress", "0xDocTargetHash", false);
await tx.wait();

//Issues a soulbound document
const tx = await transferableDocumentStore.issue("0xRecipientAddress", "0xDocTargetHash", true);
await tx.wait();
```

#### Revoke a transferable document

```typescript
const transferableDocumentStore = TransferableDocumentStore__factory.connect(transferableDocumentStoreAddress, signer);
const tx = await transferableDocumentStore.revoke("0xDocTargetHash");
await tx.wait();
```

### Roles and Access

Roles are useful for granting users to access certain functions only. Here are the designated roles meant for the different key operations.

| Role                 | Access                         |
| -------------------- | ------------------------------ |
| `DEFAULT_ADMIN_ROLE` | Able to perform all operations |
| `ISSUER_ROLE`        | Able to issue documents        |
| `REVOKER_ROLE`       | Able to revoke documents       |

A trusted user can be granted multiple roles by the admin user to perform different operations.
The following functions can be called on the token contract by the admin user to grant and revoke roles to and from users.

#### Grant a role to a user

```ts
const issuerRole = await documentStore.issuerRole();
await documentStore.grantRole(issuerRole, "0xIssuerStaff");
```

Can only be called by default admin or role admin.

#### Revoke a role from a user

```ts
const revokerRole = await documentStore.revokerRole();
await documentStore.revokeRole(revokerRole, "0xRevokerStaff");
```

Can only be called by default admin or role admin.

## Deployment

In all the deployment commands, you can replace `network` argument to any of the [supported networks](#supported-networks). Optionally, you can also supply `--verify=1` if you wish to verify the contracts. During deployment, you will be prompted to supply your private key interactively.

> [!IMPORTANT]
> The `DEPLOYER_ADDRESS` in `.env` is required to be the address of the deployer. See [Configuration](#configuration) section.

### Document Store

#### Deploy a Document Store

```sh
npm run -s deploy:ds --network="mainnet" --name="My Document Store" --admin="0x1234"
```

The `name` is the name you want to have for the document store and the `admin` is the address who will be the default admin of the document store.

#### Deploy an upgradeable Document Store

```sh
npm run -s deploy:ds:upgradeable --network="mainnet" --name="My Document Store" --admin="0x1234" --verify=1
```

Note that in the example above, the `--verify=1` is optionally passed to verify the contracts.

### Transferable Document Store

#### Deploy a Transferable Document Store

```sh
npm run -s deploy:tds --network="mainnet" --name="My Transferable Document Store" --symbol="XYZ" --admin="0x1234" --verify=1
```

The `name` and `symbol` are the standard ERC-721 token name and symbol respectively. The `admin` is the address who will be the default admin of the document store.

#### Deploy an upgradeable Transferable Document Store

```sh
npm run -s deploy:tds:upgradeable --network="mainnet" --name="My Transferable Document Store" --symbol="XYZ" --admin="0x1234" --verify=1
```

### Hardware Wallet

To deploy using a hardware wallet, you can set the `OA_LEDGER` environment variable to the HD path of your wallet. For example, `OA_LEDGER=m/44'/60'/0'/0/0`.

### Verification

You can pass `--verify=1` to the deployment commands if you wish to verify the contracts. You will need to include your Etherscan API keys for the respective networks in your `.env` configuration. See [Configuration](#configuration) section for more info.

### Supported Networks

Most EVM-based blockchains should support the document store contracts. For the more common blockchains listed below, we may deploy implementations to help reduce deployment gas fees.

- Ethereum
- Polygon
- Arbitrum One
- Optimism

> [!NOTE]
> For a list of pre-configured network names for passing to `--network` during deployment, refer to the [foundry.toml](https://github.com/Open-Attestation/document-store/blob/master/foundry.toml#L28) file.

If you wish to deploy to a network not configured yet, you can add it to the `foundry.toml` file and pass the name of the network you've added to `--network` during deployment.

## Configuration

Create a `.env` file based on [`.env.example`](https://github.com/Open-Attestation/document-store/blob/master/.env.sample) and provide the information in it.

The `DEPLOYER_ADDRESS` is required to be the address of the deployer during deployment. The Etherscan API keys are only required if you plan to verify the contracts on their respective chains.

## Development

This repository uses [Foundry](https://github.com/foundry-rs/foundry) for its development. To install Foundry, run the following commands:

```sh
curl -L https://foundry.paradigm.xyz | bash
```

## Additional Information

The contracts have not gone through formal audits yet. Please use them at your own discretion.
