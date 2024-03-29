import { ethers } from "hardhat";

const TOTAL = 64;
const NUMFORSALE = 64;

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
    const MAX_GAS_PER_BLOCK = 100000000;

    const circuitNames = [
        "AuctionWithPseudo"
    ]
    const deployedLibraries = [];
    const libraryAddresses: any = {};

    const Library = await ethers.getContractFactory("VerifierReveal2048");
    const library = await Library.deploy({
        gasLimit: MAX_GAS_PER_BLOCK,
    });
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

        const libraryName = `VerifierFinalize${TOTAL}`;
        const Library = await ethers.getContractFactory(libraryName);
        const library = await Library.deploy({
            gasLimit: MAX_GAS_PER_BLOCK,
        });
        deployedLibraries.push(library);
        libraryAddresses[libraryName] = library.address;
        await library.deployed();

        const libraries: any = {};
        libraries[`VerifierFinalize${TOTAL}`] = library.address;
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


        const revealProofJson = require(`./proofInputs/RevealProof2048.json`);
        let revealGasTotal = 0;
        // console.log(revealProofJson.inputs.length)
        for (let i = 0; i < TOTAL; i++) {
            // console.time('TEST')
            const reveal = await contract.SubmitInput(
                revealProofJson.proof,
                revealProofJson.inputs,
                {
                    gasLimit: MAX_GAS_PER_BLOCK,
                });
            // console.timeEnd('TEST')


            const revealGas = await getGasUsed(reveal.blockNumber, false);
            if (i == 0) {
                firstRevealGas = revealGas;
            }
            if (i == 1) {
                secondRevealGas = revealGas;
                console.log("reveal gas:", revealGas, " --- first: ", firstRevealGas, "---  ~", getNetworkTimeEstimates(revealGas));
                // console.log(reveal.raw);
                console.log("reveal data length:", reveal.data.length);
            }
            revealGasTotal += revealGas;
        }
        console.log("reveal gas total:", revealGasTotal);

        const finalizeProofJson = require(`./proofInputs/Finalize${TOTAL}Proof.json`);

        // console.time('FINALIZE TIME')
        const finalization = await contract.FinalizeAll(
            finalizeProofJson.proof,
            finalizeProofJson.inputs,
            {
                gasLimit: MAX_GAS_PER_BLOCK,
            });

        // console.timeEnd('FINALIZE TIME')



        // console.log(`contract address: ${contract.address}`);
        // console.log(`deployer address: ${contract.deployTransaction.from}`);

        // const revealGas = await getGasUsed(reveal.blockNumber, false);
        // console.log("reveal gas:", revealGas);

        const finalizeGas = await getGasUsed(finalization.blockNumber, false);
        finalizeGasMap[circuitName] = finalizeGas;
        console.log("finalize gas:", finalizeGas, "---", getNetworkTimeEstimates(finalizeGas));
        console.log("finalize data length:", finalization.data.length);
        console.log()

        let claimGasCount = 0;
        for (let i = 0; i < NUMFORSALE; i++) {
            const claim = await contract.ClaimPrizes(
                i,
                {
                    gasLimit: MAX_GAS_PER_BLOCK,
                });

            const claimGas = await getGasUsed(claim.blockNumber, false);

            if (i < 2) {
                // console.log("claim gas:", claimGas, "---", getNetworkTimeEstimates(claimGas));
                // console.log("claim data length:", claim.data.length);
                // console.log()
            }
            claimGasCount += claimGas;
        }

        console.log("total claim gas:", claimGasCount, "---", getNetworkTimeEstimates(claimGasCount));
        // console.log("claim data length:", finalization.data.length);
        console.log()
    }

    //--------------------------------------------------------------------------------

    const ContractToDeploy = await ethers.getContractFactory("AuctionWithoutPseudo", {
    });
    const contract = await ContractToDeploy.deploy({
        gasLimit: MAX_GAS_PER_BLOCK,
    });

    await contract.deployed();

    const baseContractDeploymentGas = await getGasUsed(contract.deployTransaction.blockNumber, false);
    console.log("contract deployment gas:", baseContractDeploymentGas, "---", getNetworkTimeEstimates(contractDeploymentGas));

    let claimGasCount = 0;
    for (let i = 0; i < NUMFORSALE; i++) {
        const claim = await contract.ClaimPrizes(
            i,
            {
                gasLimit: MAX_GAS_PER_BLOCK,
            });

        const claimGas = await getGasUsed(claim.blockNumber, false);

        if (i < 2) {
            console.log("claim gas:", claimGas, "---", getNetworkTimeEstimates



                (claimGas));
            console.log("claim data length:", claim.data.length);
            console.log()
        }
        claimGasCount += claimGas;
    }

    console.log("total claim gas:", claimGasCount, "---", getNetworkTimeEstimates(claimGasCount));
    // console.log("claim data length:", finalization.data.length);
    console.log()
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});