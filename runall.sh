#First, in another terminal, run npx hardhat node

cd ./xjsnark-files/circuits
source ../scripts/runfinalize.sh # if you do not want this to run, set SHOULD_EXECUTE to false within this file. this will skip the proof and key generation

printf "\n\nrunfinalize.sh has finished\n\n"

# Change localhost to geth if you want to run on geth
# Double check your hardhat.config.ts file to make sure you have the right settings
cd ../
npx hardhat run --network localhost scripts/simulate.ts > ./outputs/simulate.txt
printf "\n\nfinished testing simulated application. output is in solidity_contracts/outputs\n\n"

cd ../
