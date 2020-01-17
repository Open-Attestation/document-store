# certificate-contract

[![Build Status](https://travis-ci.org/GovTechSG/certificate-contract.svg?branch=master)](https://travis-ci.org/GovTechSG/certificate-contract)

## Setup

```
$ npm install
$ npm lint
$ npx ganache-cli -h 0.0.0.0 -p 8545 -i 1337 -s foobar -e 100000000000000000000
$ npm test
$ npm truffle <command>
```

## Notes

https://forum.openzeppelin.com/t/source-openzeppelin-not-found-file-import-callback-not-supported/1812
https://github.com/juanfranblanco/vscode-solidity#openzeppelin


Absolutely minimal contract: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
Create 2 for ProxyFactory: https://blog.openzeppelin.com/getting-the-most-out-of-create2/


Stupid owner contract in upgrades is wrong!