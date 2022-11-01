// SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    import "./VerifierLibrary.sol";

    // Note that we assume manager is not a participating user
    // One can split Input phase into commit / reveal such as Hawk 
    contract Finalize32 {
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
            uint256[] keyCiphertext; //Encrypted w/ RSA
            uint256[] inputCiphertext; //Encrypted w/ AES key
            uint timestamp;
            bool valid; //assume it is valid by default
        }
        UserInput[] public userInputs;
        uint constant MAX_USER_INPUTS = 32;
    
    
    
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
            uint256[8] calldata proof, 
            uint256[] calldata proofInputs
        ) public payable {
            require(block.timestamp < INPUT_DEADLINE || testing);   //during bidding Interval  
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
                // revert();
            }

            require(userInputs.length < MAX_USER_INPUTS);
            userInputs.push(UserInput
                (
                    proofInputs[5:], 
                    proofInputs[1:5],
                    block.timestamp,
                    true
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

            //Execute proof logic using userInputs
            //For this implementation, we expect the following for inputs:
            // [0] = the hardcoded 1 wire
            // MAX_USER_INPUTS * 16 -> ciphertext bytes
            // MAX_USER_INPUTS -> timestamps
            //TODO: remove testing
            for (uint i = 0; i < MAX_USER_INPUTS; i++) {
                // TODO: 
                for (uint j = 0; j < 4; j++) {
                    require(proofInputs[1 + (i * 4) + j] == userInputs[i].inputCiphertext[j]);
                }
    
                require(proofInputs[1 + (MAX_USER_INPUTS * 4) + i] == userInputs[i].timestamp || testing);
            }
    
    
            if (!VerifierFinalize32.VerifyFinalize32(
                proof,
                proofInputs
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