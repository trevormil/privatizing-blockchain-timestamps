#To be executed in circuits folder
#If there are no vhanges to the MPS circuits, there is no need to genkeys or prove. Just comment these commands out


# pinocchio Reveal.arith genkeys Reveal.pk Reveal.vk.json;
# pinocchio Reveal.arith prove Reveal_Sample_Run1.in Reveal.pk RevealProof.json;

pinocchio Reveal2048.arith genkeys Reveal2048.pk Reveal2048.vk.json > ../pinocchio_outputs/Reveal2048_genkeys.txt;
pinocchio Reveal2048.arith prove Reveal2048_Sample_Run1.in Reveal2048.pk Reveal2048Proof.json > ../pinocchio_outputs/Reveal2048_prove.txt;
printf "Reveal2048 done\n"

pinocchio Finalize2.arith genkeys Finalize2.pk Finalize2.vk.json > ../pinocchio_outputs/Finalize2_genkeys.txt;
pinocchio Finalize2.arith prove Finalize2_Sample_Run1.in Finalize2.pk Finalize2Proof.json > ../pinocchio_outputs/Finalize2_prove.txt;
printf "Finalize2 done\n"

pinocchio Finalize4.arith genkeys Finalize4.pk Finalize4.vk.json > ../pinocchio_outputs/Finalize4_genkeys.txt;
pinocchio Finalize4.arith prove Finalize4_Sample_Run1.in Finalize4.pk Finalize4Proof.json > ../pinocchio_outputs/Finalize4_prove.txt;
printf "Finalize4 done\n"

pinocchio Finalize8.arith genkeys Finalize8.pk Finalize8.vk.json > ../pinocchio_outputs/Finalize8_genkeys.txt;
pinocchio Finalize8.arith prove Finalize8_Sample_Run1.in Finalize8.pk Finalize8Proof.json  > ../pinocchio_outputs/Finalize8_prove.txt;
printf "Finalize8 done\n"

pinocchio Finalize16.arith genkeys Finalize16.pk Finalize16.vk.json > ../pinocchio_outputs/Finalize16_genkeys.txt;
pinocchio Finalize16.arith prove Finalize16_Sample_Run1.in Finalize16.pk Finalize16Proof.json > ../pinocchio_outputs/Finalize16_prove.txt;
printf "Finalize16 done\n"

pinocchio Finalize32.arith genkeys Finalize32.pk Finalize32.vk.json > ../pinocchio_outputs/Finalize32_genkeys.txt;
pinocchio Finalize32.arith prove Finalize32_Sample_Run1.in Finalize32.pk Finalize32Proof.json > ../pinocchio_outputs/Finalize32_prove.txt;
printf "Finalize32 done\n"

pinocchio Finalize64.arith genkeys Finalize64.pk Finalize64.vk.json > ../pinocchio_outputs/Finalize64_genkeys.txt;
pinocchio Finalize64.arith prove Finalize64_Sample_Run1.in Finalize64.pk Finalize64Proof.json > ../pinocchio_outputs/Finalize64_prove.txt;
printf "Finalize64 done\n"

# pinocchio Finalize128.arith genkeys Finalize128.pk Finalize128.vk.json;
# pinocchio Finalize128.arith prove Finalize128_Sample_Run1.in Finalize128.pk Finalize128Proof.json;

node ../scripts/genLibraries.js
source ../scripts/genproofjson.sh
cd ../../solidity_contracts/scripts/
node genSolidityContracts.js