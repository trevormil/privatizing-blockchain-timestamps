const csv = require('csv-parser');
const fs = require('fs');
const axios = require('axios');

const filepath = './verifiedetherscancontracts.csv';
const API_TOKEN = ''; //TODO: insert your own API token

const addresses = [];

fs.createReadStream(filepath)
    .on('error', () => {
        // handle error
    })

    .pipe(csv())
    .on('data', async (row) => {
        let contractAddress = row['ContractAddress'];
        addresses.push(contractAddress);
    })

    .on('end', async () => {
        let totalNumErrors = 0;
        let totalBlockTimestamp = 0;
        let totalBlockNumber = 0;
        let totalBlockNumberAndBlockTimestamp = 0;
        let totalBlockNumberOrBlockTimestamp = 0;
        let totalBlock = 0;

        let currentAddressCount = 1;

        for (const address of addresses) {
            await axios
                .get(
                    `https://api.etherscan.io/api?module=contract&action=getsourcecode&address=${address}&apikey=${API_TOKEN}`
                )
                .then((response) => {
                    const sourceCodeString =
                        response.data.result[0]['SourceCode'];

                    const includesBlockTimestamp =
                        sourceCodeString.includes('block.timestamp');
                    const includesBlockNumber =
                        sourceCodeString.includes('block.number');

                    if (includesBlockTimestamp) {
                        totalBlockTimestamp++;
                    }
                    if (includesBlockNumber) {
                        totalBlockNumber++;
                    }
                    if (includesBlockNumber && includesBlockTimestamp) {
                        totalBlockNumberAndBlockTimestamp++;
                    }
                    if (includesBlockNumber || includesBlockTimestamp) {
                        totalBlockNumberOrBlockTimestamp++;
                    }

                    if (sourceCodeString.includes('block')) {
                        totalBlock++;
                    }
                })
                .catch((err) => {
                    console.log('ERROR:', err);
                    totalNumErrors++;
                });

            console.log(
                '#',
                currentAddressCount,
                '(',
                totalBlock,
                totalBlockNumberOrBlockTimestamp,
                totalBlockNumberAndBlockTimestamp,
                totalBlockTimestamp,
                totalBlockNumber,
                totalNumErrors,
                ')'
            );

            currentAddressCount++;

            await new Promise((r) => setTimeout(r, 500));
        }
    });
