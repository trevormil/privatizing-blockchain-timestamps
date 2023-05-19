// This contract is not as well documented and has some outdated comments compared to the FinalizeStandard* contracts but inherits from the same template.
// Refer to those contracts for more details.

// This contract was not actually used in the experiment. It is provided more so as an example of the Dutch auction contract.
// This contract reveals if each bid was successful or not for claiming purposes but can easily be switched to just send the ciphertexts (like in our paper).
// For our actual experiment, we just generated a new VerifierLibrary.sol with Dutch auction circuits instead of the generic contracts
// and tested our FinalizeStandard* contracts with the new VerifierLibrary.sol.

// SPDX-License-Identifier: GPL-3.0
    pragma solidity >=0.7.0 <0.9.0;
    import "./VerifierLibrary.sol";

    import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
    import "@openzeppelin/contracts/utils/Counters.sol";

    contract SampleNFT is ERC721URIStorage {
        using Counters for Counters.Counter;
        Counters.Counter private _tokenIds;

        constructor() ERC721("GameItem", "ITM") {}

        function awardItem(address player, string memory tokenURI)
            public
            returns (uint256)
        {
            uint256 newItemId = _tokenIds.current();
            _mint(player, newItemId);
            _setTokenURI(newItemId, tokenURI);

            _tokenIds.increment();
            return newItemId;
        }
    }

    // Note that we assume manager is not a participating user
    // One can split Input phase into commit / reveal such as Hawk 
    contract AuctionWithPseudo {
        /**
            Define inputCommitment scheme here and how pseudo state updates are performed:
            _____
            TODO:
        */
        //Application-Specific Parameters
        //Manager Abort Penalty: TODO
        //Other: TODO:
    
        enum ApplicationState {Init, Input, ManagerChallenge, UserResponse, Finalize}
        SampleNFT public nft;
        
        // User inputs for their commitments
        struct UserInput {
            uint256[] keyCiphertext; //Encrypted w/ RSA
            uint256[] inputCiphertext; //Encrypted w/ AES key
            uint timestamp;
            bool valid; //assume it is valid by default
            address sender;
        }
        UserInput[] public userInputs;
        uint constant NUM_FOR_SALE = 8;
        uint constant MAX_USER_INPUTS = 8;

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

            nft = new SampleNFT();
            
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
                    true,
                    msg.sender
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

            for (uint i = 0; i < MAX_USER_INPUTS; i++) {
                // TODO: 
                for (uint j = 0; j < 4; j++) {
                    require(proofInputs[1 + (i * 4) + j] == userInputs[i].inputCiphertext[j]);
                }
    
                require(proofInputs[1 + (MAX_USER_INPUTS * 4) + i] == userInputs[i].timestamp || testing);
            }
    
    
            if (!VerifierFinalizeStandard8.VerifyFinalizeStandard8(
                proof,
                proofInputs
            )) {
    
                revert("Proof failed to verify"); 
            }

            uint sold = 0;
            for (uint i = 1 + MAX_USER_INPUTS * 5; i < proofInputs.length; i+=4) {
                if(sold < NUM_FOR_SALE && proofInputs[i] == 1 || i < 1 + MAX_USER_INPUTS * 5 + NUM_FOR_SALE) {

                    userInputs[i - (1 + MAX_USER_INPUTS * 5)].valid = true;
                    sold++;
                }
            }
        }

        function ClaimPrizes(uint idx) public {
            require(userInputs[idx].valid == true);
            require(userInputs[idx].sender == msg.sender);
            // require(block.timestamp > FINALIZE_DEADLINE || testing);

            nft.awardItem(msg.sender, "https://game.example/item-id-1.json");
        }
    
        function HandleManagerAbort() public {
            //We handle this bc inputs will never get marked as real and all funds can be withdrawn
        }
    
        modifier onlyManager() {
            require(msg.sender == managerAddress); //by auctioneer only
            _;
        }
    }