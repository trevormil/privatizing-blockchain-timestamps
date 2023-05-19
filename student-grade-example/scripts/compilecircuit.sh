#!/bin/bash
# export PATH_DEPTH=$1
# export PUBLIC_PATH_DEPTH=$2

# rm circuit.circom
# cp abstractcircuit.circom circuit.circom
# sed -i 's/PUBLIC_PATH_DEPTH/'$PUBLIC_PATH_DEPTH'/' circuit.circom
# sed -i 's/PATH_DEPTH/'$PATH_DEPTH'/' circuit.circom

circom circuit.circom --r1cs --wasm --sym
# snarkjs r1cs info circuit.r1cs
# snarkjs r1cs print circuit.r1cs circuit.sym
snarkjs r1cs export json circuit.r1cs circuit.r1cs.json

# Clean up file directory structure
mv ./circuit.r1cs.json ./circuit_files/circuit.r1cs.json
mv ./circuit.r1cs ./circuit_files/circuit.r1cs
mv ./circuit.sym ./circuit_files/circuit.sym