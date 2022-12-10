// This file generates the VerifierLibrary.sol file from the .vk.json files
// Basically, this implements all the zkSNARK proof verification logic using the verification keys
// and creates a Solidity library to verify each of the circuits' proofs.
// We call these libraries from our application contracts.

const fs = require('fs');

let fileStr = `// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
`;

const filenames = [
    'FinalizeStandard8.vk.json',
    'FinalizeStandard16.vk.json',
    'FinalizeStandard32.vk.json',
    'FinalizeStandard64.vk.json',
    'FinalizeStandard128.vk.json',
    'Reveal2048.vk.json',
];

for (const file of filenames) {
    const jsonFile = require(`../circuits/${file}`);
    const gammaABC = [];
    const vKey = [...jsonFile.alpha];

    for (const pairingPointArr of jsonFile.beta) {
        vKey.push(...pairingPointArr);
    }

    for (const pairingPointArr of jsonFile.gamma) {
        vKey.push(...pairingPointArr);
    }

    for (const pairingPointArr of jsonFile.delta) {
        vKey.push(...pairingPointArr);
    }

    for (const pairingPointArr of jsonFile.gammaABC) {
        gammaABC.push(...pairingPointArr);
    }

    let gammaStr = `\n`;
    for (let i = 0; i < gammaABC.length; i++) {
        gammaStr += `\t\t\tgammaABC[${i}] = ${gammaABC[i]};\n`;
    }

    const str = `[${vKey.toString().replaceAll(',', ',')}];
    
            uint256[] memory gammaABC = new uint[](${gammaABC.length});
    
    ${gammaStr}`;

    fileStr += `library Verifier${file.split('.')[0]}
    {
        function NegateY( uint256 Y )
            internal pure returns (uint256)
        {
            uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
            return q - (Y % q);
        }
    
    
        //Obtained from EthSnarks
        function Verify ( uint256[14] memory in_vk, uint256[] memory vk_gammaABC, uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
            require( ((vk_gammaABC.length / 2) - 1) == proof_inputs.length );
    
            // Compute the linear combination vk_x
            uint256[3] memory mul_input;
            uint256[4] memory add_input;
            bool success;
            uint m = 2;
    
            // First two fields are used as the sum
            add_input[0] = vk_gammaABC[0];
            add_input[1] = vk_gammaABC[1];
    
            // Performs a sum of gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]
            for (uint i = 0; i < proof_inputs.length; i++)
            {
                require( proof_inputs[i] < snark_scalar_field );
                mul_input[0] = vk_gammaABC[m++];
                mul_input[1] = vk_gammaABC[m++];
                mul_input[2] = proof_inputs[i];
    
                assembly {
                    // ECMUL, output to last 2 elements of \`add_input\`
                    success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
                }
                require( success );
    
                assembly {
                    // ECADD
                    success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
                }
                require( success );
            }
    
            uint[24] memory input = [
                // (proof.A, proof.B)
                in_proof[0], in_proof[1],                           // proof.A   (G1)
                in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)
    
                // (-vk.alpha, vk.beta)
                in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
                in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)
    
                // (-vk_x, vk.gamma)
                add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
                in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)
    
                // (-proof.C, vk.delta)
                in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
                in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
            ];
    
            uint[1] memory out;
            assembly {
                success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
            }
            require(success);
            return out[0] != 0;
        }
    
        function Verify${
            file.split('.')[0]
        } ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = ${str}
    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    `;
}

fs.writeFile(
    `../../solidity_contracts/contracts/VerifierLibrary.sol`,
    // 'Ver.sol',
    fileStr,
    function (err, result) {
        if (err) {
            console.log(err);
        }
    }
);
