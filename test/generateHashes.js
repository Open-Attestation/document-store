const startingHash =
  "0x3a267813bea8120f55a7b9ca814c34dd89f237502544d7c75dfd709a659f6432";

const generateHashes = number => {
  let currentHash = BigInt(startingHash);
  let hashes = [];
  for (let i = 0; i < number; i += 1) {
    hashes.push(`0x${currentHash.toString(16)}`);
    currentHash += 1n;
  }

  console.log(hashes);
  return hashes;
};

const formatHashes = hashes => {
    const hashesString = "[" + hashes.join(", ") + "]"
    return hashesString
}

module.exports = {
  generateHashes,
  formatHashes
};
