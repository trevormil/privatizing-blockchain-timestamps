// node scripts/parseXJsnarkVKeyFileForRemix.js ../xjsnarkKeys/sha256.vk.json

const vKeyJson = require(process.argv[2]);
console.log('Parsing Verification Key JSON from ', process.argv[2]);
console.log(vKeyJson);
console.log('_________________________________________________');
const gammaABC = [];
const vKey = [...vKeyJson.alpha];

for (const pairingPointArr of vKeyJson.beta) {
    vKey.push(...pairingPointArr);
}

for (const pairingPointArr of vKeyJson.gamma) {
    vKey.push(...pairingPointArr);
}

for (const pairingPointArr of vKeyJson.delta) {
    vKey.push(...pairingPointArr);
}

for (const pairingPointArr of vKeyJson.gammaABC) {
    gammaABC.push(...pairingPointArr);
}

console.log(
    'VerificationKey',
    '[' + vKey.toString().replaceAll(',', ',') + ']'
);
console.log();
// console.log('GammaABC', '[' + gammaABC.toString().replaceAll(',', ',') + ']');
console.log();
console.log(`uint256[] memory gammaABC = new uint[](${gammaABC.length});`);
for (let i = 0; i < gammaABC.length; i++) {
    console.log(`gammaABC[${i}] = ${gammaABC[i]};`);
}
