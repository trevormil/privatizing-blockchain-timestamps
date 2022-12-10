// This script basically parses the Proof.json and formats in a way that can be used in the Solidity contract.
// It then stors the proof and inputs in a file in the solidity_contracts/scripts/proofInputs folder.

const fs = require('fs');
const proofJson = require(process.argv[2]);
console.log('Parsing Proof JSON from ', process.argv[2]);
console.log(proofJson);
console.log('_________________________________________________');
const inputs = [...proofJson.input];
const proof = [...proofJson.A];

for (const pairingPointArr of proofJson.B) {
    proof.push(...pairingPointArr);
}

proof.push(...proofJson.C);
const proofString = '["' + proof.toString().replaceAll(',', '","') + '"]';
console.log('Proof JSON', proofString);
console.log();
const inputString = '["' + inputs.toString().replaceAll(',', '","') + '"]';
console.log(
    'Inputs JSON',
    '["' + inputs.toString().replaceAll(',', '","') + '"]'
);

const outputJson = {
    proof: proof,
    inputs: inputs,
};
fs.writeFile(
    `../../solidity_contracts/scripts/proofInputs/${process.argv[2]
        .split('/')
        .pop()}`,
    JSON.stringify(outputJson),
    function (err, result) {
        if (err) console.log('error', err);
    }
);
