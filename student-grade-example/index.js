const snarkjs = require("snarkjs");
const fs = require("fs");
const inputJson = require('./input.json');

const NUM_INPUTS = 1; //number of unique proofs to generate, each with their own input parameters
const USE_ONLY_INPUT_DOT_JSON = true; //if true, we will override any inputs from this program and just use the input.json file

const NUM_PROVING_RUNS = 1; //per input
const NUM_VERIFICATION_RUNS = 5; //per input

//Main function that runs everything
async function run(inputs) {
    let count = 1;

    for (const inputPromise of inputs) {
        const input = await inputPromise;
        console.log('Proof #:', count);
        count++;

        let proofObj = undefined;
        let publicSignalsArr = undefined;

        for (let i = 0; i < NUM_PROVING_RUNS; i++) {
            console.time('Proving Time');
            let { proof, publicSignals } = await snarkjs.groth16.fullProve(
                input, 
                "./circuit_js/circuit.wasm",
                "./keygen/circuit_final.zkey"
            );
            console.timeEnd('Proving Time');
            
            if (i == 0) {
                proofObj = proof;
                publicSignalsArr = publicSignals;
            }
        }

        const vKey = JSON.parse(fs.readFileSync("./keygen/verification_key.json"));
        for (let i = 0; i < NUM_VERIFICATION_RUNS; i++) {
            console.time('Verification Time');
            const res = await snarkjs.groth16.verify(vKey, publicSignalsArr, proofObj);
            if (res != true) {
                console.log("WARNING: Invalid proof. Verification failed.");
            }
            console.timeEnd(`Verification Time`);
        }
        
        console.log()
        console.log("Proof Information: ");
        // console.log(JSON.stringify(proofObj, null, 1));
        console.log("Input", `(${USE_ONLY_INPUT_DOT_JSON ? 'input.json' : 'generated'}):`, input);
        console.log("Public Signals: ", publicSignalsArr);
        console.log()
        console.log('-------------------------------------------------------------------------------------')
    }
}

function randomString(len, base) {
    let str = '';
    for (let i = 0; i < len; i++) {
        str += `${Math.floor(Math.random() * base)}`;
    }
    return str;
}

async function generateInput() {
    return {
        "a": randomString(1, 10),
        "b": randomString(1, 10),
    }
}

const generatedInputsArr = Array.from({length: NUM_INPUTS}, async () => {
    const input = await generateInput();
    return input;
});

run(!USE_ONLY_INPUT_DOT_JSON ? [
    ...generatedInputsArr
] : [
    inputJson
]).then(() => {
    process.exit(0);
});


/**
 * {
 "pi_a": [
  "16045604486309224740830845904297536584494529015949039945369732920170040075072",
  "290418874861295684897786223399033791963329760793151911727434447917876602150",
  "1"
 ],
 "pi_b": [
  [
   "7028125407729703655335227918452707464662526735794456388942040115351518202502",
   "9816267526218857929729767923349305174088351783257215590411645304920948339755"
  ],
  [
   "6095752016420165486242449690080692285708127293444900274244497967091835858149",
   "9069574526802304491680020605209900818114271825516177885241852871538753134141"
  ],
  [
   "1",
   "0"
  ]
 ],
 "pi_c": [
  "19784250875966718996486139842892023502248497717816849306810859621096722573961",
  "6623262082532571272405900755628613196071516908830799782316647956479891674696",
  "1"
 ],
 "protocol": "groth16",
 "curve": "bn128"
}
 */

//[
//  "13137592086492735317203908856150578832578737366149620572148091802269967423068"
// ]