# Document Store

The [Document Store](https://github.com/Open-Attestation/document-store) repository contains the following: 

* The smart contract code for document store in the `/contracts` folder
* The node package for using this library in the `/src` folder

## Installation

To install OpenAttestation document store on your machine, run the command below:

```sh
npm i @govtechsg/document-store
```

---

## Usage

Provide one of the following depending on your needs:

* To use the package, provide your own Web3 [provider](https://docs.ethers.io/v5/api/providers/api-providers/).

* To write to the blockchain, provide the [signer](https://docs.ethers.io/v5/api/signer/#Wallet) instead.

### Deploying a new document store

The following shows a code example to deploy a new document store:

```ts
import { deployAndWait } from "@govtechsg/document-store";

const documentStore = await deployAndWait("My Document Store", signer).then(console.log);
```

### Connecting to an existing document store

The following shows a code example to connect to an existing document store:

```ts
import { connect } from "@govtechsg/document-store";

const documentStore = await connect("0x4077534e82c97be03a07fb10f5c853d2bc7161fb", providerOrSigner);
```

### Interacting with a document store

The following shows a code example to interact with a document store:

```ts
const issueMerkleRoot = async () => {
  const documentStore = connect("0x4077534e82c97be03a07fb10f5c853d2bc7161fb", signer);

  const tx = await documentStore.issue("0x7fe0b58ed760804eb7118988637693c4351613be327b56527e55bcd0a8d170d7");
  const receipt = await tx.wait();
  console.log(receipt);

  const isIssued = await instance.isIssued("0x7fe0b58ed760804eb7118988637693c4351613be327b56527e55bcd0a8d170d7");
  console.log(isIssued);
};
```

### List of available functions

The following is a list of available functions to be used with document store:

- `documentIssued`
- `documentRevoked`
- `isOwner`
- `name`
- `owner`
- `renounceOwnership`
- `transferOwnership`
- `version`
- `initialize`
- `issue`
- `bulkIssue`
- `getIssuedBlock`
- `isIssued`
- `isIssuedBefore`
- `revoke`
- `bulkRevoke`
- `isRevoked`
- `isRevokedBefore`

## Provider & signer

The following code example shows different ways to get the provider or signer:

```ts
import { Wallet, providers, getDefaultProvider } from "ethers";

// Providers
const mainnetProvider = getDefaultProvider();
const sepoliaProvider = getDefaultProvider("sepolia");
const metamaskProvider = new providers.Web3Provider(web3.currentProvider); // Will change network automatically

// Signer
const signerFromPrivateKey = new Wallet("YOUR-PRIVATE-KEY-HERE", provider);
const signerFromEncryptedJson = Wallet.fromEncryptedJson(json, password);
signerFromEncryptedJson.connect(provider);
const signerFromMnemonic = Wallet.fromMnemonic("MNEMONIC-HERE");
signerFromMnemonic.connect(provider);
```

## Setup

You can install dependencies, check source code, test your project, and use the Truffle development framework with the commands below:

```sh
npm install
npm lint
npm test
npm truffle <command>
```

## Contract benchmark

To show the different transaction costs of the different variants of the document store, run the contract benchmark with the command below:

```sh
npm run benchmark
```

## Additional information

If you are using Visual Studio Code, you may need to link the OpenZeppelin libraries. Refer to [here](https://github.com/juanfranblanco/vscode-solidity#openzeppelin) for more information.
