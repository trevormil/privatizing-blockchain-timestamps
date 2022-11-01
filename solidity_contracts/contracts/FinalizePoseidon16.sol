// SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    import "./VerifierFinalizePoseidon16.sol";

    // Note that we assume manager is not a participating user
    // One can split Input phase into commit / reveal such as Hawk 
    contract FinalizePoseidon16 {
        /**
            Define inputCommitment scheme here and how pseudo state updates are performed:
            _____
            TODO:
        */
        //Application-Specific Parameters
        //Manager Abort Penalty: TODO
        //Other: TODO:
    
        enum ApplicationState {Init, Input, ManagerChallenge, UserResponse, Finalize}
        
        // User inputs for their commitments
        struct UserInput {
            uint256 hash;
            // uint256[] keyCiphertext; //Encrypted w/ RSA
            // uint256[] inputCiphertext; //Encrypted w/ AES key
            uint timestamp;
            bool valid; //assume it is valid by default
        }
        UserInput[] public userInputs;
        uint constant MAX_USER_INPUTS = 16;
    
    
    
        //Stage Timestamps
        uint public INPUT_DEADLINE;
        uint PRICE_ONE_DEADLINE;
        uint PRICE_TWO_DEADLINE;
        uint public FINALIZE_DEADLINE;
    
        uint[3] prices;
    
        //Valid ranges for users to submit inputs (must be before INPUT_DEADLINE).
        struct TimestampRange {
            uint start;
            uint end;
        }
        TimestampRange[] validTimeRangesForInputs;
    
        //Manager information
        address public managerAddress;
        bool testing = true;
    
        constructor(
            uint _priceOneDeadline, 
            uint _priceTwoDeadline, 
            uint _inputDeadline, 
            uint _finalizeDeadline, 
            uint[3] memory _prices,
            uint[] memory _startTimes, 
            uint[] memory _endTimes
        ) {
            require(_startTimes.length == _endTimes.length);
            for (uint i = 0; i < _startTimes.length; i++) {
                validTimeRangesForInputs.push(TimestampRange(_startTimes[i], _endTimes[i]));
            }
            
            prices = _prices;
    
            managerAddress = msg.sender;
            
            INPUT_DEADLINE = _inputDeadline;
            FINALIZE_DEADLINE = _finalizeDeadline;
            PRICE_ONE_DEADLINE = _priceOneDeadline;
            PRICE_TWO_DEADLINE = _priceTwoDeadline;
        }
    
        // Submit input and reveal to manager via ciphertext
        function SubmitInput(
            // uint256[8] calldata proof, 
            // uint256[] calldata proofInputs
        ) public payable {
            // require(block.timestamp < INPUT_DEADLINE || testing);   //during bidding Interval  
            // bool validTime = false;
            // for (uint i = 0; i < validTimeRangesForInputs.length; i++) {
            //     if (block.timestamp >= validTimeRangesForInputs[i].start && block.timestamp <= validTimeRangesForInputs[i].end) {
            //         validTime = true;
            //     }
            // }
            // require(validTime == true || testing);
    
            // if (!VerifierReveal2048.VerifyReveal2048(
            //     proof,
            //     proofInputs
            // )) {
            //     // revert();
            // }

            require(userInputs.length < MAX_USER_INPUTS);
            userInputs.push(UserInput
                (
                    0x048be8c964448a1172fdf3aca5a6a0ae8f434dfe6ef753f0b9886eb74fba0366, //hardcoded
                    block.timestamp,
                    true
                )
            );     
        }
    
        function FinalizeAll( 
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[32] memory input
        ) public onlyManager {
            require(userInputs.length == MAX_USER_INPUTS);
            require((block.timestamp < FINALIZE_DEADLINE && block.timestamp > INPUT_DEADLINE) || testing);
            

            //Execute proof logic using userInputs
            //For this implementation, we expect the following for inputs:
            // [0] = the hardcoded 1 wire
            // MAX_USER_INPUTS * 16 -> ciphertext bytes
            // MAX_USER_INPUTS -> timestamps
            //TODO: remove testing
            
            // require(1 + userInputs.length * 9 == proofInputs.length);
            for (uint i = 0; i < MAX_USER_INPUTS; i++) {
                require(input[i] == userInputs[i].hash);
                require(input[MAX_USER_INPUTS + i] == userInputs[i].timestamp || testing);
            }
    
    
            if (!VerifierFinalizePoseidon16.verifyProof(
                a,
                b,
                c,
                input
            )) {
    
                revert("Proof failed to verify"); 
            }

            //Can also use plaintext inputs (everything after timestamps in proofInputs)
            
        }
    
        function HandleManagerAbort() public {
            //We handle this bc inputs will never get marked as real and all funds can be withdrawn
        }
    
        modifier onlyManager() {
            require(msg.sender == managerAddress); //by auctioneer only
            _;
        }
    }