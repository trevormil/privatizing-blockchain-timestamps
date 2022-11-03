#in another terminal, run npx hardhat node

cd ./xjsnark-files/
cd ./circuits
source ../scripts/runfinalize.sh #make sure everything you want to run is not commented out

printf "\n\nxjsnark done\n\n"

# cd ../../circom-files/
# source scripts/runall.sh

# printf "\n\nxcircom done\n\n"

cd ../
npx hardhat run --network localhost scripts/aes.ts > ./outputs/aes.txt
printf "\n\naes done\n\n"
# npx hardhat run --network localhost scripts/poseidon.ts > ./outputs/poeidon.txt
# printf "\n\nxposeidon done\n\n"

# npx hardhat run --network localhost scripts/poseidon.ts > ./outputs/poeidon.txt
# printf "\n\nxposeidon done\n\n"