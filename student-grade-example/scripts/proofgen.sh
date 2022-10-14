snarkjs groth16 setup ./circuit_files/circuit.r1cs ./keygen/powersOfTau28_hez_final_18.ptau ./keygen/circuit_0000.zkey
snarkjs zkey contribute ./keygen/circuit_0000.zkey ./keygen/circuit_0001.zkey --name="1st Contributor Name" -v -e="adhjkawhjk"
snarkjs zkey contribute ./keygen/circuit_0001.zkey ./keygen/circuit_0002.zkey --name="Second contribution Name" -v -e="Another random entropy"
snarkjs zkey export bellman ./keygen/circuit_0002.zkey ./keygen/challenge_phase2_0003
snarkjs zkey bellman contribute bn128 ./keygen/challenge_phase2_0003 ./keygen/response_phase2_0003 -e="some random text"
snarkjs zkey import bellman ./keygen/circuit_0002.zkey ./keygen/response_phase2_0003 ./keygen/circuit_0003.zkey -n="Third contribution name"
snarkjs zkey beacon ./keygen/circuit_0003.zkey ./keygen/circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"
snarkjs zkey export verificationkey ./keygen/circuit_final.zkey ./keygen/verification_key.json

snarkjs groth16 prove ./keygen/circuit_final.zkey ./circuit_files/witness.wtns ./circuit_files/proof.json ./circuit_files/public.json
snarkjs groth16 verify ./keygen/verification_key.json ./circuit_files/public.json ./circuit_files/proof.json
