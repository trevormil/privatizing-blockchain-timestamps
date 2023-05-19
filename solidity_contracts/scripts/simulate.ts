// I apologize for all this mess of code. This is the code we used to test gas costs
// and other blockcahin metrics for our system. Not all relevant code may be here.

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
        "FinalizeStandard8",
        "FinalizeStandard16",
        "FinalizeStandard32",
        "FinalizeStandard64",
        "FinalizeStandard128",
    ]
    const deployedLibraries = [];
    const libraryAddresses: any = {};
    console.log("ASFKJHSDF");
    const Library = await ethers.getContractFactory("VerifierReveal2048");
    console.log('sfjhas')
    const library = await Library.deploy({
        gasLimit: MAX_GAS_PER_BLOCK,
    });
    console.log('sfjhas')
    const contractDeploymentGas = await getGasUsed(library.deployTransaction.blockNumber, false);
    console.log("reveal library deployment gas:", contractDeploymentGas, "---", getNetworkTimeEstimates(contractDeploymentGas));
    console.log();

    const revealLibAddress = library.address;
    await library.deployed();
    let firstRevealGas = 0;
    let secondRevealGas = 0;
    const finalizeGasMap: any = {}

    for (const circuitName of circuitNames) {
        console.log(circuitName);

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
        libraries["VerifierReveal2048"] = revealLibAddress;

        const ContractToDeploy = await ethers.getContractFactory(circuitName, {
            libraries: libraries
        });
        const contract = await ContractToDeploy.deploy(10, 10, 10, 10, [1, 2, 3], [1], [1], {
            gasLimit: MAX_GAS_PER_BLOCK,
        });

        await contract.deployed();

        const contractDeploymentGas = await getGasUsed(contract.deployTransaction.blockNumber, false);
        console.log("contract deployment gas:", contractDeploymentGas, "---", getNetworkTimeEstimates(contractDeploymentGas));

        const libraryDeploymentGas = await getGasUsed(library.deployTransaction.blockNumber, false);
        console.log("library deployment gas:", libraryDeploymentGas, "for", libraryName, "---", getNetworkTimeEstimates(libraryDeploymentGas));


        // const revealProofJson = require(`./proofInputs/RevealProof2048.json`);

        // // console.log(revealProofJson.inputs.length)
        // for (let i = 0; i < Number(circuitName.split('ard')[1]); i++) {
        //     const reveal = await contract.SubmitInput(
        //         revealProofJson.proof,
        //         revealProofJson.inputs,
        //         {
        //             gasLimit: MAX_GAS_PER_BLOCK,
        //         });


        //     const revealGas = await getGasUsed(reveal.blockNumber, false);
        //     if (i == 0) {
        //         firstRevealGas = revealGas;
        //     }
        //     if (i == 1) {
        //         secondRevealGas = revealGas;
        //         console.log("reveal gas:", revealGas, " --- first: ", firstRevealGas, "---  ~", getNetworkTimeEstimates(revealGas));
        //         // console.log(reveal.raw);
        //         console.log("reveal data length:", reveal.data.length);
        //     }
        // }

        // const finalizeProofJson = require(`./proofInputs/${circuitName}Proof.json`);


        // const finalization = await contract.FinalizeAll(
        //     finalizeProofJson.proof,
        //     finalizeProofJson.inputs,
        //     {
        //         gasLimit: MAX_GAS_PER_BLOCK,
        //     });


        // // console.log(`contract address: ${contract.address}`);
        // // console.log(`deployer address: ${contract.deployTransaction.from}`);

        // // const revealGas = await getGasUsed(reveal.blockNumber, false);
        // // console.log("reveal gas:", revealGas);

        // const finalizeGas = await getGasUsed(finalization.blockNumber, false);
        // finalizeGasMap[circuitName] = finalizeGas;
        // console.log("finalize gas:", finalizeGas, "---", getNetworkTimeEstimates(finalizeGas));
        // console.log("finalize data length:", finalization.data.length);
        // console.log()


    }

    // for (const circuitName of circuitNames) {
    //     let currNumber = Number(circuitName.split('lize')[1]);
    //     while (currNumber <= 8192) {
    //         let finalizeGas = finalizeGasMap[circuitName];
    //         let revealGas = firstRevealGas + secondRevealGas * (currNumber - 1);
    //         let finalizeTotalGas = finalizeGas * (currNumber / Number(circuitName.split('lize')[1]));

    //         console.log("Joint for", circuitName, "with", currNumber, "inputs")
    //         console.log(`reveal gas (~${secondRevealGas} x ${currNumber}) =`, revealGas, "--- ~", getNetworkTimeEstimates(secondRevealGas));
    //         console.log(`finalize gas (~${finalizeGas} x ${currNumber / Number(circuitName.split('lize')[1])}):`, finalizeTotalGas, "---", getNetworkTimeEstimates(finalizeTotalGas));
    //         if (currNumber <= 64) {
    //             console.log(`non-joint finalize gas (~${finalizeGasMap[`Finalize${currNumber}`]} x 1):`, finalizeGasMap[`Finalize${currNumber}`], "---", getNetworkTimeEstimates(finalizeGasMap[`Finalize${currNumber}`]));
    //         }

    //         console.log();
    //         currNumber *= 2;
    //     }
    //     // console.log(libraryAddresses);
    //     console.log("-----------------------------------------------------------------------------");
    // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});