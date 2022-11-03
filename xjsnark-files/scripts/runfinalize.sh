#To be executed in circuits folder
#If there are no vhanges to the MPS circuits, there is no need to genkeys or prove. Just comment these commands out


# pinocchio Reveal.arith genkeys Reveal.pk Reveal.vk.json;
# pinocchio Reveal.arith prove Reveal_Sample_Run1.in Reveal.pk RevealProof.json;

# pinocchio Reveal2048.arith genkeys Reveal2048.pk Reveal2048.vk.json > ../pinocchio_outputs/Reveal2048_genkeys.txt;
# pinocchio Reveal2048.arith prove Reveal2048_Sample_Run1.in Reveal2048.pk Reveal2048Proof.json > ../pinocchio_outputs/Reveal2048_prove.txt;
printf "Reveal2048 done\n"

# pinocchio FinalizeStandard2.arith genkeys FinalizeStandard2.pk FinalizeStandard2.vk.json > ../pinocchio_outputs/FinalizeStandard2_genkeys.txt;
# pinocchio FinalizeStandard2.arith prove FinalizeStandard2_Sample_Run1.in FinalizeStandard2.pk FinalizeStandard2Proof.json > ../pinocchio_outputs/FinalizeStandard2_prove.txt;
# printf "FinalizeStandard2 done\n"

# pinocchio FinalizeStandard4.arith genkeys FinalizeStandard4.pk FinalizeStandard4.vk.json > ../pinocchio_outputs/FinalizeStandard4_genkeys.txt;
# pinocchio FinalizeStandard4.arith prove FinalizeStandard4_Sample_Run1.in FinalizeStandard4.pk FinalizeStandard4Proof.json > ../pinocchio_outputs/FinalizeStandard4_prove.txt;
# printf "FinalizeStandard4 done\n"

pinocchio FinalizeStandard8.arith genkeys FinalizeStandard8.pk FinalizeStandard8.vk.json > ../pinocchio_outputs/FinalizeStandard8_genkeys.txt;
pinocchio FinalizeStandard8.arith prove FinalizeStandard8_Sample_Run1.in FinalizeStandard8.pk FinalizeStandard8Proof.json  > ../pinocchio_outputs/FinalizeStandard8_prove.txt;
printf "FinalizeStandard8 done\n"

pinocchio FinalizeStandard16.arith genkeys FinalizeStandard16.pk FinalizeStandard16.vk.json > ../pinocchio_outputs/FinalizeStandard16_genkeys.txt;
pinocchio FinalizeStandard16.arith prove FinalizeStandard16_Sample_Run1.in FinalizeStandard16.pk FinalizeStandard16Proof.json > ../pinocchio_outputs/FinalizeStandard16_prove.txt;
printf "FinalizeStandard16 done\n"

pinocchio FinalizeStandard32.arith genkeys FinalizeStandard32.pk FinalizeStandard32.vk.json > ../pinocchio_outputs/FinalizeStandard32_genkeys.txt;
pinocchio FinalizeStandard32.arith prove FinalizeStandard32_Sample_Run1.in FinalizeStandard32.pk FinalizeStandard32Proof.json > ../pinocchio_outputs/FinalizeStandard32_prove.txt;
printf "FinalizeStandard32 done\n"

pinocchio FinalizeStandard64.arith genkeys FinalizeStandard64.pk FinalizeStandard64.vk.json > ../pinocchio_outputs/FinalizeStandard64_genkeys.txt;
pinocchio FinalizeStandard64.arith prove FinalizeStandard64_Sample_Run1.in FinalizeStandard64.pk FinalizeStandard64Proof.json > ../pinocchio_outputs/FinalizeStandard64_prove.txt;
printf "FinalizeStandard64 done\n"



pinocchio FinalizeStandard128.arith genkeys FinalizeStandard128.pk FinalizeStandard128.vk.json > ../pinocchio_outputs/FinalizeStandard128_genkeys.txt;
pinocchio FinalizeStandard128.arith prove FinalizeStandard128_Sample_Run1.in FinalizeStandard128.pk FinalizeStandard128Proof.json > ../pinocchio_outputs/FinalizeStandard128_prove.txt;


node ../scripts/genLibraries.js
source ../scripts/genproofjson.sh
cd ../../solidity_contracts/scripts/
node genSolidityContracts.js