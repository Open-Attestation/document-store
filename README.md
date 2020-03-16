# Document Store Contract

[![Build Status](https://travis-ci.org/GovTechSG/certificate-contract.svg?branch=master)](https://travis-ci.org/GovTechSG/certificate-contract)

## Setup

```sh
npm install
npm lint
npm test
npm truffle <command>
```

## Benchmark

A benchmark is provided to show the different transaction cost of the different variants of the document store.

```sh
npm run benchmark
```

![Benchmark Results](./docs/benchmark.png)

## Notes

If you are using vscode, you may need to link the openzeppelin libraries. See https://github.com/juanfranblanco/vscode-solidity#openzeppelin
