# Document Store Contract

[![Build Status](https://travis-ci.org/GovTechSG/certificate-contract.svg?branch=master)](https://travis-ci.org/GovTechSG/certificate-contract)

## Setup

```sh
npm install
npm lint
npm test
npm truffle <command>
```

## Package Usage

Deploying new document store

```ts
import {deploy} from "@govtechsg/document-store-contract";

deployAndWait("My Document Store", signer).then(console.log);
```

Connecting to existing document store on Ethereum

```ts
import {connect} from "@govtechsg/document-store-contract";

connect("0x4077534e82c97be03a07fb10f5c853d2bc7161fb", providerOrSigner);
```

Deploying new document store with minimal proxy (TBD)

```ts
import {deployMinimal} from "@govtechsg/document-store-contract";

deployMinimal("My Document Store", signer).then(console.log);
```


## Contract Benchmark

A benchmark is provided to show the different transaction cost of the different variants of the document store.

```sh
npm run benchmark
```

![Benchmark Results](./docs/benchmark.png)

## Notes

If you are using vscode, you may need to link the openzeppelin libraries. See https://github.com/juanfranblanco/vscode-solidity#openzeppelin
