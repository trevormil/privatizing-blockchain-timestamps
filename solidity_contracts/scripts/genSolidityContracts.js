// This script generates the solidity contracts for our generic application with no application-specific logic.

const fs = require('fs');

const filenames = [
    'FinalizeStandard8',
    'FinalizeStandard16',
    'FinalizeStandard32',
    'FinalizeStandard64',
    'FinalizeStandard128',
];

for (const file of filenames) {
    let fileStr = `// SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    `;
    fileStr += `import "./VerifierLibrary.sol";

    // Note that we assume manager is not a participating user
    // One can split Input phase into commit / reveal such as Hawk 
    contract ${file} {
        //TODO: Add any application-specific functionality, such as manager abort penalty and any other parameters

        enum ApplicationState {Init, Input, ManagerChallenge, UserResponse, Finalize}
        
        // User inputs for their commitments
        struct UserInput {
            uint256[] keyCiphertext; //Encrypted w/ RSA
            uint256[] inputCiphertext; //Encrypted w/ AES key
            uint timestamp;
        }
        UserInput[] public userInputs;
        uint constant MAX_USER_INPUTS = ${
            file.split('ard')[1]
        }; //Equivalent to N in our paper

        //Stage Timestamps
        uint public INPUT_DEADLINE;
        uint public FINALIZE_DEADLINE;

        //Valid ranges for users to submit inputs (must be before INPUT_DEADLINE).
        struct TimestampRange {
            uint start;
            uint end;
        }
        TimestampRange[] validTimeRangesForInputs;
    
        //Manager information
        address public managerAddress;
        string public managerRSAAddress;
        bool testing = true;
    
        constructor(
            uint _inputDeadline, 
            uint _finalizeDeadline, 
            string memory rsaAddress,
            uint[] memory _startTimes, 
            uint[] memory _endTimes
        ) {
            require(_startTimes.length == _endTimes.length);
            for (uint i = 0; i < _startTimes.length; i++) {
                validTimeRangesForInputs.push(TimestampRange(_startTimes[i], _endTimes[i]));
            }
    
            managerAddress = msg.sender;
            managerRSAAddress = rsaAddress;
            
            INPUT_DEADLINE = _inputDeadline;
            FINALIZE_DEADLINE = _finalizeDeadline;
        }
    
        // Submit input and reveal to manager via ciphertext
        function SubmitInput(
            uint256[8] calldata proof, 
            uint256[] calldata proofInputs
        ) public payable {
            require(block.timestamp < INPUT_DEADLINE || testing);   //during bidding Interval  

            // Note that invalid inputs can also be inputted but ignored within the applciation target function F via the Finalization proof, 
            // but since timing data is public, we can do it here for efficiency and reject everything in the first place
            bool validTime = false;
            for (uint i = 0; i < validTimeRangesForInputs.length; i++) {
                if (block.timestamp >= validTimeRangesForInputs[i].start && block.timestamp <= validTimeRangesForInputs[i].end) {
                    validTime = true;
                }
            }
            require(validTime == true || testing);
    
            if (!VerifierReveal2048.VerifyReveal2048(
                proof,
                proofInputs
            )) {
                // revert(); // This is due to a pinocchio compatibility error. We provide a sample proof which is invalid, but we simply ignore the invalid return value (thus, not affecting the experiment)
            }

            //Store ciphertexts and timestamps for later use
            require(userInputs.length < MAX_USER_INPUTS);
            userInputs.push(UserInput
                (
                    proofInputs[5:], 
                    proofInputs[1:5],
                    block.timestamp
                )
            );     
        }
    
        function FinalizeAll( 
            uint256[8] memory proof, 
            uint256[] memory proofInputs
        ) public onlyManager {
            require(userInputs.length == MAX_USER_INPUTS);
            require((block.timestamp < FINALIZE_DEADLINE && block.timestamp > INPUT_DEADLINE) || testing);
            require(1 + userInputs.length * 9 == proofInputs.length);

            // Execute proof logic using userInputs
            // For this implementation, we expect the following for proofInputs:
            // [0] = the hardcoded 1 wire
            // [1 : MAX_USER_INPUTS * 4 + 1] -> AES ciphertext bytes 
            // [MAX_USER_INPUTS * 4 + 1 : MAX_USER_INPUTS * 5 + 1] -> timestamps
            // [MAX_USER_INPUTS * 5 + 1 : MAX_USER_INPUTS * 9 + 1] -> encrypted AES outputs

            // Assert that the manager used the correct timestamps and AES ciphertexts within their proof
            for (uint i = 0; i < MAX_USER_INPUTS; i++) {
                for (uint j = 0; j < 4; j++) {
                    require(proofInputs[1 + (i * 4) + j] == userInputs[i].inputCiphertext[j]);
                }
    
                require(proofInputs[1 + (MAX_USER_INPUTS * 4) + i] == userInputs[i].timestamp || testing);
            }
    
            // Execute and verify the proof
            if (!Verifier${file}.Verify${file}(
                proof,
                proofInputs
            )) {
    
                revert("Proof failed to verify"); 
            }

            // Everything after the timestamps in proofInputs is the encrypted outputs of the application target function F
            // We do not actually store this because we assume users can just query this manager's TX and decrypt their respective outputs
            // But for ease of use, an application can store this information here if they want to
            // TODO: Add any application-specific functionality
        }
    
        function HandleManagerAbort() public {
            //TODO: Add application-specific abort logic
        }
    
        modifier onlyManager() {
            require(msg.sender == managerAddress); //by manager only
            _;
        }
    }`;

    fs.writeFile(
        `../contracts/${file}.sol`,
        // 'Ver.sol',
        fileStr,
        function (err, result) {
            if (err) {
                console.log('error', err);
            }
        }
    );
}

// const poseidonFilenames = [
//     'FinalizePoseidon2',
//     'FinalizePoseidon4',
//     'FinalizePoseidon8',
//     'FinalizePoseidon16',
//     'FinalizePoseidon32',
//     'FinalizePoseidon64',
// ];

// for (const file of poseidonFilenames) {
//     let fileStr = `// SPDX-License-Identifier: GPL-3.0
//     pragma solidity >=0.7.0 <0.9.0;
//     `;
//     fileStr += `import "./Verifier${file}.sol";

//     // Note that we assume manager is not a participating user
//     // One can split Input phase into commit / reveal such as Hawk
//     contract ${file} {
//         /**
//             Define inputCommitment scheme here and how pseudo state updates are performed:
//             _____
//             TODO:
//         */
//         //Application-Specific Parameters
//         //Manager Abort Penalty: TODO
//         //Other: TODO:

//         enum ApplicationState {Init, Input, ManagerChallenge, UserResponse, Finalize}

//         // User inputs for their commitments
//         struct UserInput {
//             uint256 hash;
//             // uint256[] keyCiphertext; //Encrypted w/ RSA
//             // uint256[] inputCiphertext; //Encrypted w/ AES key
//             uint timestamp;
//             bool valid; //assume it is valid by default
//         }
//         UserInput[] public userInputs;
//         uint constant MAX_USER_INPUTS = ${file.split('eidon')[1]};

//         //Stage Timestamps
//         uint public INPUT_DEADLINE;
//         uint PRICE_ONE_DEADLINE;
//         uint PRICE_TWO_DEADLINE;
//         uint public FINALIZE_DEADLINE;

//         uint[3] prices;

//         //Valid ranges for users to submit inputs (must be before INPUT_DEADLINE).
//         struct TimestampRange {
//             uint start;
//             uint end;
//         }
//         TimestampRange[] validTimeRangesForInputs;

//         //Manager information
//         address public managerAddress;
//         bool testing = true;

//         constructor(
//             uint _priceOneDeadline,
//             uint _priceTwoDeadline,
//             uint _inputDeadline,
//             uint _finalizeDeadline,
//             uint[3] memory _prices,
//             uint[] memory _startTimes,
//             uint[] memory _endTimes
//         ) {
//             require(_startTimes.length == _endTimes.length);
//             for (uint i = 0; i < _startTimes.length; i++) {
//                 validTimeRangesForInputs.push(TimestampRange(_startTimes[i], _endTimes[i]));
//             }

//             prices = _prices;

//             managerAddress = msg.sender;

//             INPUT_DEADLINE = _inputDeadline;
//             FINALIZE_DEADLINE = _finalizeDeadline;
//             PRICE_ONE_DEADLINE = _priceOneDeadline;
//             PRICE_TWO_DEADLINE = _priceTwoDeadline;
//         }

//         // Submit input and reveal to manager via ciphertext
//         function SubmitInput(
//             // uint256[8] calldata proof,
//             // uint256[] calldata proofInputs
//         ) public payable {
//             // require(block.timestamp < INPUT_DEADLINE || testing);   //during bidding Interval
//             // bool validTime = false;
//             // for (uint i = 0; i < validTimeRangesForInputs.length; i++) {
//             //     if (block.timestamp >= validTimeRangesForInputs[i].start && block.timestamp <= validTimeRangesForInputs[i].end) {
//             //         validTime = true;
//             //     }
//             // }
//             // require(validTime == true || testing);

//             // if (!VerifierReveal2048.VerifyReveal2048(
//             //     proof,
//             //     proofInputs
//             // )) {
//             //     // revert();
//             // }

//             require(userInputs.length < MAX_USER_INPUTS);
//             userInputs.push(UserInput
//                 (
//                     0x048be8c964448a1172fdf3aca5a6a0ae8f434dfe6ef753f0b9886eb74fba0366, //hardcoded
//                     block.timestamp,
//                     true
//                 )
//             );
//         }

//         function FinalizeAll(
//             uint[2] memory a,
//             uint[2][2] memory b,
//             uint[2] memory c,
//             uint[${Number(file.split('eidon')[1]) * 2}] memory input
//         ) public onlyManager {
//             require(userInputs.length == MAX_USER_INPUTS);
//             require((block.timestamp < FINALIZE_DEADLINE && block.timestamp > INPUT_DEADLINE) || testing);

//             //Execute proof logic using userInputs
//             //For this implementation, we expect the following for inputs:
//             // [0] = the hardcoded 1 wire
//             // MAX_USER_INPUTS * 16 -> ciphertext bytes
//             // MAX_USER_INPUTS -> timestamps
//             //TODO: remove testing

//             // require(1 + userInputs.length * 9 == proofInputs.length);
//             for (uint i = 0; i < MAX_USER_INPUTS; i++) {
//                 require(input[i] == userInputs[i].hash);
//                 require(input[MAX_USER_INPUTS + i] == userInputs[i].timestamp || testing);
//             }

//             if (!Verifier${file}.verifyProof(
//                 a,
//                 b,
//                 c,
//                 input
//             )) {

//                 revert("Proof failed to verify");
//             }

//             //Can also use plaintext inputs (everything after timestamps in proofInputs)

//         }

//         function HandleManagerAbort() public {
//             //We handle this bc inputs will never get marked as real and all funds can be withdrawn
//         }

//         modifier onlyManager() {
//             require(msg.sender == managerAddress); //by auctioneer only
//             _;
//         }
//     }`;

//     fs.writeFile(
//         `../contracts/${file}.sol`,
//         // 'Ver.sol',
//         fileStr,
//         function (err, result) {
//             if (err) {
//                 console.log('error', err);
//             }
//         }
//     );
// }
