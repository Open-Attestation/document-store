const ganache = require("ganache-cli");

let server: any;

export async function setupBlockchain() {
  server = ganache.server();
  server.listen(8545, () => {});
}

export async function teardownBlockchain() {
  await server.close();
}
