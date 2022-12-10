# Privatizing the Timing and Volume of Transactions for Blockchain Applications

I apologize for the messy code. I am looking to clean it up in the near future.

```source runall.sh``` is the main script that should build and benchmark everything for the zkSNARK circuits.

```npx hardhat node``` must be run from the solidity_contracts folder for testing blockchain gas metrics.

Note that I hard copied my ./pinocchio and ./run_ppzksnark files from jsnark/libsnark and ethsnarks respectively. These may not work on your machine, so you will need to copy over your built executables, if this is the case.

Also, follow the comments and error messages within all script files for debugging.

Circuit files were generated with MPS and can be found at [https://github.com/trevormil/xjsnark-circuits](https://github.com/trevormil/xjsnark-circuits). Follow xjsnark setup for reconstructing these circuits.

Note that this repository also uses Git LFS (large file storage) to fetch the .arith and .in circuit files. All other large files should be generated with the runall.sh script

## Repository Overview

```xjsnark-files``` - Main folder which holds everything for the zkSNARK circuits (circuit files, proof outputs, generated keys, and output of scripts)

```solidity_contracts``` - Hardhat project which is used to test blockchain metrics. Can use either local Hardhat node or Geth nodes from ```local-eth-testnet```. Change hardhat configuration dependent on your choice.

```thesis-etherscan``` - Script that took in source code of Etherscan verified contracts and checked how many included block.timestamp or block.number

