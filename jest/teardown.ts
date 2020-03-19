// teardown.js
import {teardownBlockchain} from "./utils";

module.exports = async () => {
  await teardownBlockchain();
};
