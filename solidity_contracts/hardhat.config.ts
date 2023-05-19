import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";

const config: HardhatUserConfig = {
    solidity: "0.8.17",

    networks: {
        hardhat: {
            blockGasLimit: 100000000429720, // whatever you want here
            allowUnlimitedContractSize: true,
            // Depends on whether you want to use automine mode or not
            // mining: {
            //     auto: false,
            //     interval: 12000,
            // },
        },
        geth: {

            url: `http://localhost:8545`,
            // accounts: [GOERLI_PRIVATE_KEY]
            blockGasLimit: 100000000429720, // whatever you want here
            allowUnlimitedContractSize: true,
            accounts: ["0x0185b5e2c3dad4c85a4418e6a52bed0849e128b9db9e5c5249c67e78ff9cce40"],
            gasPrice: 1,
            // gas: 25e6,
        }
    }
};

export default config;
