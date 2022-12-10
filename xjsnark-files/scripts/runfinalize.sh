#To be executed in circuits folder as source ../scripts/runfinalize.sh

# If there are no changes to the MPS circuits and you already have the keys and proof files, 
# there is no need to genkeys or prove. 
# Just set SHOULD_PROVE_AND_GENKEYS to false

# Note that we use the ./pinocchio executable which was built with EthSnarks for our OS (Ubuntu) and machine
# Replace this with the built pinocchio executable for your OS and machine, if it doesn't work

# You may need to make a pinocchio_outputs folder within xjsnark-files

SHOULD_PROVE_AND_GENKEYS=true
SHOULD_BENCHMARK=true

if $SHOULD_PROVE_AND_GENKEYS; then
    echo "Running runfinalize.sh..."
    echo "Running genkeys and prove with pinocchio. These keys and proofs will be used for Solidity testing and not our benchmarks (which we use libsnark for)."
    echo "Outputs will be in /xjsnark-files/pinocchio_outputs folder (may need to create this folder if not already created)"

    # User submission circuit for RSA w/ 2048 bit modulus
    ./pinocchio Reveal2048.arith genkeys Reveal2048.pk Reveal2048.vk.json > ../pinocchio_outputs/Reveal2048_genkeys.txt;
    # ./pinocchio Reveal2048.arith prove Reveal2048_Sample_Run1.in Reveal2048.pk Reveal2048Proof.json > ../pinocchio_outputs/Reveal2048_prove.txt;
    printf "Reveal2048 done\n"
    printf "\nNote that we skip Reveal2048 prove due to an issue with pinocchio compatibility with xjsnark. With libsnark (what we use for benchmarks), this will pass. For Solidity testing purposes, we created a sample Reveal2048 proof which was invalid and did not pass the verifyProof() but we just ignored this invalid return value and continued on (thus, not affecting the experiment).\n"

    # Finalization Proofs
    ./pinocchio FinalizeStandard8.arith genkeys FinalizeStandard8.pk FinalizeStandard8.vk.json > ../pinocchio_outputs/FinalizeStandard8_genkeys.txt;
    ./pinocchio FinalizeStandard8.arith prove FinalizeStandard8_Sample_Run1.in FinalizeStandard8.pk FinalizeStandard8Proof.json  > ../pinocchio_outputs/FinalizeStandard8_prove.txt;
    printf "FinalizeStandard8 done\n"

    ./pinocchio FinalizeStandard16.arith genkeys FinalizeStandard16.pk FinalizeStandard16.vk.json > ../pinocchio_outputs/FinalizeStandard16_genkeys.txt;
    ./pinocchio FinalizeStandard16.arith prove FinalizeStandard16_Sample_Run1.in FinalizeStandard16.pk FinalizeStandard16Proof.json > ../pinocchio_outputs/FinalizeStandard16_prove.txt;
    printf "FinalizeStandard16 done\n"

    ./pinocchio FinalizeStandard32.arith genkeys FinalizeStandard32.pk FinalizeStandard32.vk.json > ../pinocchio_outputs/FinalizeStandard32_genkeys.txt;
    ./pinocchio FinalizeStandard32.arith prove FinalizeStandard32_Sample_Run1.in FinalizeStandard32.pk FinalizeStandard32Proof.json > ../pinocchio_outputs/FinalizeStandard32_prove.txt;
    printf "FinalizeStandard32 done\n"

    ./pinocchio FinalizeStandard64.arith genkeys FinalizeStandard64.pk FinalizeStandard64.vk.json > ../pinocchio_outputs/FinalizeStandard64_genkeys.txt;
    ./pinocchio FinalizeStandard64.arith prove FinalizeStandard64_Sample_Run1.in FinalizeStandard64.pk FinalizeStandard64Proof.json > ../pinocchio_outputs/FinalizeStandard64_prove.txt;
    printf "FinalizeStandard64 done\n"

    ./pinocchio FinalizeStandard128.arith genkeys FinalizeStandard128.pk FinalizeStandard128.vk.json > ../pinocchio_outputs/FinalizeStandard128_genkeys.txt;
    ./pinocchio FinalizeStandard128.arith prove FinalizeStandard128_Sample_Run1.in FinalizeStandard128.pk FinalizeStandard128Proof.json > ../pinocchio_outputs/FinalizeStandard128_prove.txt;
    printf "FinalizeStandard128 done\n"

else
    echo "Skipping finalize.sh since SHOULD_PROVE_AND_GENKEYS is false"
    # exit 0
fi

echo "Running genLibraries.js to generate the verification libraries in solidity_contracts/contracts/VerifierLibrary.sol"
node ../scripts/genLibraries.js

echo "Running genproofjson.sh to generate the proof json files in solidity_contracts/scripts/proofInputs"
source ../scripts/genproofjson.sh

echo "Now we will now run the time benchmarks for all zkSNARK circuits using libsnark. Make sure you have a libsnark_outputs folder in xjsnark-files."
if $SHOULD_BENCHMARK; then
    ./run_ppzksnark Reveal2048.arith Reveal2048_Sample_Run1.in > ../libsnark_outputs/Reveal2048.txt;
    ./run_ppzksnark FinalizeStandard8.arith FinalizeStandard8_Sample_Run1.in > ../libsnark_outputs/FinalizeStandard8.txt;
    ./run_ppzksnark FinalizeStandard16.arith FinalizeStandard16_Sample_Run1.in > ../libsnark_outputs/FinalizeStandard16.txt;
    ./run_ppzksnark FinalizeStandard32.arith FinalizeStandard32_Sample_Run1.in > ../libsnark_outputs/FinalizeStandard32.txt;
    ./run_ppzksnark FinalizeStandard64.arith FinalizeStandard64_Sample_Run1.in > ../libsnark_outputs/FinalizeStandard64.txt;
    ./run_ppzksnark FinalizeStandard128.arith FinalizeStandard128_Sample_Run1.in > ../libsnark_outputs/FinalizeStandard128.txt;
    echo "Finsihed benchmarks. Output is in xjsnark-files/libsnark_outputs folder."
else
    echo "Skipping benchmarks since SHOULD_BENCHMARK is false"
    # exit 0
fi

echo "Running genSolidityContracts.js to generate the Solidity contracts in solidity_contracts/contracts/"
cd ../../solidity_contracts/scripts/
node genSolidityContracts.js