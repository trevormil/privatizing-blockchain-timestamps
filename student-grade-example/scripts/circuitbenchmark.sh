#!/bin/bash
for i in 2 4 8 16 32 64 128
do
   source compilecircuit.sh $i 1
   source genkey.sh
   node index.js > "benchmark_outputs/output_${i}.txt"
done