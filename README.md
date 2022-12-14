# Privatizing the Timing and Volume of Transactions for Blockchain Applications

I apologize for the messy code. I am looking to clean it up in the near future.

Paper Link - TBD

## Setup 
Make sure all dependencies for 
[jsnark/libsnark](https://github.com/akosba/jsnark), [ethsnarks](https://github.com/HarryR/ethsnarks),
[xjsnark](https://github.com/trevormil/xjsnark-circuits), and [Hardhat](https://hardhat.org/) are installed. Note we have only executed this on Ubuntu. 

We built libsnark with the ALT_BN_128 and MULTICORE flags turned on.

Note that I hard copied my ./pinocchio and ./run_ppzksnark files from [jsnark/libsnark](https://github.com/akosba/jsnark) and [ethsnarks](https://github.com/HarryR/ethsnarks) respectively. These may not work on your machine, so you will need to copy over your built executables to the circuits folder and replace mine, if this is the case.

We provided our circuit files (.arith and .in), but the source code for the circuit files were generated with MPS and can be found at [https://github.com/trevormil/xjsnark-circuits](https://github.com/trevormil/xjsnark-circuits). Follow xjsnark setup for reconstructing these circuits. Currently, the generic application contracts are provided. The Dutch auction contracts are almost exactly the same, so we didn't explicitly provide them here, but within FinalizeStandard8 in MPS, you can see the Dutch auction circuit generation code.

Note that this repository also uses Git LFS (large file storage) to fetch the .arith and .in circuit files. All other large files should be generated with the runall.sh script

## Generating Keys / Proofs, Verification Libraries, Application Contracts, and Running Benchmarks

```source runall.sh``` is the main script that should build and benchmark everything by calling every other script. See this file for how to run individual scripts.

Note that in runfinalize.sh, there are two flags for skipping the proof/key generation and also skipping the benchmark outputs. These are typically the longest, and once you run them once, they do not have to be run again (i.e. the flags can be turned off).

```npx hardhat node``` must always be running in another terminal from the solidity_contracts folder for testing blockchain gas metrics.

Follow the comments in script files and error messages within all script files for debugging.

Output text files will be in libsnark_outputs, pinocchio_outputs, and solidity_contracts/outputs folder.

## Repository Overview

```xjsnark-files``` - Main folder which holds everything for the zkSNARK circuits (circuit files, proof outputs, generated keys, and output of scripts)

```solidity_contracts``` - Hardhat project which is used to test blockchain metrics. Can use either local Hardhat node or Geth nodes from ```local-eth-testnet```. Change hardhat configuration dependent on your choice.

```thesis-etherscan``` - Script that took in source code of Etherscan verified contracts and checked how many included block.timestamp or block.number. Not used in benchmarking.

