import { ethers } from "hardhat";

const hexToDecimal = (hex: any) => parseInt(hex, 16);

const getNetworkTimeEstimates = (gas: number) => {
    const normalBlockLimit = 30000000;
    const blockTime = 12;

    return Number((gas / normalBlockLimit) * blockTime).toFixed(5) + " seconds";
}
const getGasUsed = async (blockNumber: any, print: boolean): Promise<number> => {
    const gasUsed = (
        await ethers.provider.send('eth_getBlockByNumber', [
            ethers.utils.hexValue(blockNumber),
            true,
        ])
    ).gasUsed;

    if (print) {
        console.log(
            hexToDecimal(gasUsed)
        );
    }
    return hexToDecimal(gasUsed);
}

async function main() {
    const MAX_GAS_PER_BLOCK = 100000000000;

    const circuitNames = [
        "FinalizePoseidon2",
        "FinalizePoseidon4",
        "FinalizePoseidon8",
        "FinalizePoseidon16",
        "FinalizePoseidon32",
        "FinalizePoseidon64",
    ]
    const deployedLibraries = [];
    const libraryAddresses: any = {};

    const Library = await ethers.getContractFactory("VerifierReveal2048");
    const library = await Library.deploy({
        gasLimit: MAX_GAS_PER_BLOCK,
    });
    const revealLibAddress = library.address;
    await library.deployed();

    // let firstRevealGas = 0;
    // let secondRevealGas = 0;
    const finalizeGasMap: any = {}


    for (const circuitName of circuitNames) {
        const libraryName = `Verifier${circuitName}`;
        const Library = await ethers.getContractFactory(libraryName);
        const library = await Library.deploy({
            gasLimit: MAX_GAS_PER_BLOCK,
        });
        deployedLibraries.push(library);
        libraryAddresses[libraryName] = library.address;
        await library.deployed();

        const libraries: any = {};
        libraries[libraryName] = library.address;
        // libraries["VerifierReveal2048"] = revealLibAddress;

        const ContractToDeploy = await ethers.getContractFactory(circuitName, {
            libraries: libraries
        });
        const contract = await ContractToDeploy.deploy(10, 10, 10, 10, [1, 2, 3], [1], [1], {
            gasLimit: MAX_GAS_PER_BLOCK,
        });

        await contract.deployed();

        for (let i = 0; i < Number(circuitName.split('eidon')[1]); i++) {
            // console.log(test);
            const reveal = await contract.SubmitInput(
                {
                    gasLimit: MAX_GAS_PER_BLOCK,
                });


            const revealGas = await getGasUsed(reveal.blockNumber, false);
            if (i < 2) {
                // console.log("reveal gas:", revealGas);
                // // console.log(reveal.raw);
                // console.log("reveal data length:", reveal.data.length);
            }
        }

        const finalizeProofJson = require(`./proofInputs/${circuitName}.json`);


        const finalization = await contract.FinalizeAll(
            finalizeProofJson.a,
            finalizeProofJson.b,
            finalizeProofJson.c,
            finalizeProofJson.input,
            {
                gasLimit: MAX_GAS_PER_BLOCK,
            });


        console.log(circuitName);
        // console.log(`contract address: ${contract.address}`);
        // console.log(`deployer address: ${contract.deployTransaction.from}`);
        const contractDeploymentGas = await getGasUsed(contract.deployTransaction.blockNumber, false);
        console.log("contract deployment gas:", contractDeploymentGas, "---", getNetworkTimeEstimates(contractDeploymentGas));

        const libraryDeploymentGas = await getGasUsed(library.deployTransaction.blockNumber, false);
        console.log("library deployment gas:", libraryDeploymentGas, "for", libraryName, "---", getNetworkTimeEstimates(libraryDeploymentGas));

        // const revealGas = await getGasUsed(reveal.blockNumber, false);
        // console.log("reveal gas:", revealGas);

        const finalizeGas = await getGasUsed(finalization.blockNumber, false);
        finalizeGasMap[circuitName] = finalizeGas;
        console.log("finalize gas:", finalizeGas, "---", getNetworkTimeEstimates(finalizeGas));
        console.log("finalize data length:", finalization.data.length);
        console.log()
    }
    // console.log(libraryAddresses);


    for (const circuitName of circuitNames) {
        let currNumber = Number(circuitName.split('eidon')[1]);
        while (currNumber <= 8192) {
            let finalizeGas = finalizeGasMap[circuitName];
            // let revealGas = firstRevealGas + secondRevealGas * (currNumber - 1);
            let finalizeTotalGas = finalizeGas * (currNumber / Number(circuitName.split('eidon')[1]));

            console.log("Joint for", circuitName, "with", currNumber, "inputs")
            // console.log(`reveal gas (~${secondRevealGas} x ${currNumber}) =`, revealGas);
            console.log(`finalize gas (~${finalizeGas} x ${currNumber / Number(circuitName.split('eidon')[1])}):`, finalizeTotalGas, "---", getNetworkTimeEstimates(finalizeTotalGas));
            if (currNumber <= 64) {
                console.log(`non-joint finalize gas (~${finalizeGasMap[`FinalizePoseidon${currNumber}`]} x 1):`, finalizeGasMap[`FinalizePoseidon${currNumber}`], "---", getNetworkTimeEstimates(finalizeGasMap));
            }

            console.log();
            currNumber *= 2;
        }
        // console.log(libraryAddresses);
        console.log("-----------------------------------------------------------------------------");
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});