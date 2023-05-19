// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Pedersen { 
    //uint public q =  21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint private q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint private gX = 19823850254741169819033785099293761935467223354323761392354670518001715552183;
    uint private gY = 15097907474011103550430959168661954736283086276546887690628027914974507414020;
    uint private hX = 3184834430741071145030522771540763108892281233703148152311693391954704539228;
    uint private hY = 1405615944858121891163559530323310827496899969303520166098610312148921359100;
    function Commit(uint b, uint r) public returns (uint cX, uint cY) {
        uint cX1;
        uint cY1;
        uint cX2;
        uint cY2;
        (cX1, cY1) = ecMul(b, gX, gY);
        (cX2, cY2) = ecMul(r, hX, hY);
        (cX, cY) = ecAdd(cX1, cY1, cX2, cY2);
    }
    function Verify(uint b, uint r, uint cX, uint cY) public returns (bool) {
        uint cX2;
        uint cY2;
        (cX2, cY2) = Commit(b,r);
        return cX == cX2 && cY == cY2;
    }
    function CommitDelta(uint cX1, uint cY1, uint cX2, uint cY2) public returns (uint cX, uint cY) {
        (cX, cY) = ecAdd(cX1, cY1, cX2, q-cY2); 
    }
    function ecMul(uint b, uint cX1, uint cY1) private returns (uint cX2, uint cY2) {
        bool success = false;
        bytes memory input = new bytes(96);
        bytes memory output = new bytes(64);
        assembly {
            mstore(add(input, 32), cX1)
            mstore(add(input, 64), cY1)
            mstore(add(input, 96), b)
            success := call(gas(), 7, 0, add(input, 32), 96, add(output, 32), 64)
            cX2 := mload(add(output, 32))
            cY2 := mload(add(output, 64))
        }
        require(success);
    }
    function ecAdd(uint cX1, uint cY1, uint cX2, uint cY2) public returns (uint cX3, uint cY3) {
        bool success = false;
        bytes memory input = new bytes(128);
        bytes memory output = new bytes(64);
        assembly {
            mstore(add(input, 32), cX1)
            mstore(add(input, 64), cY1)
            mstore(add(input, 96), cX2)
            mstore(add(input, 128), cY2)
            success := call(gas(), 6, 0, add(input, 32), 128, add(output, 32), 64)
            cX3 := mload(add(output, 32))
            cY3 := mload(add(output, 64))
        }
        require(success);
    }
}

// Note that we assume manager is not a participating user
// One can split Input phase into commit / reveal such as Hawk 
contract PseudoStateUpdateTemplate {
    enum ApplicationState {Init, Input, ManagerChallenge, UserResponse, Finalize}
    Pedersen pedersen;

    // User inputs for their commitments
    struct UserInput {
        uint inputCommitmentX;
        uint inputCommitmentY;
        uint[] identityXCommitments; //for identity proofs
        uint[] identityYCommitments; //for identity proofs
        bool[] haveUsed;
        bytes ciphertext;
        uint timestamp;
        bool valid; //assume it is valid by default
    }
    UserInput[] public userInputs;
    /**
        Define inputCommitment scheme here and how pseudo state updates are performed:
        _____
        TODO:
    */

    //Stage Timestamps
    uint public INPUT_DEADLINE;
    uint public MANAGER_CHALLENGE_DEADLINE;
    uint public USER_RESPONSE_DEADLINE;
    uint public FINALIZE_DEADLINE;

    //Valid ranges for users to submit inputs (must be before INPUT_DEADLINE).
    struct TimestampRange {
        uint start;
        uint end;
    }
    TimestampRange[] validTimeRangesForInputs;

    //Manager information
    address public managerAddress;
    string  public managerAsymmetricPublicKey;

    //Application-Specific Parameters
    //Manager Abort Penalty: TODO
    //Other: TODO:


    //Constructor = Setting all parameters
    function Auction(uint _inputDeadline, uint _managerChallengeDeadline, uint _userResponseDeadline, uint _finalizeDeadline, string memory _managerAsymmetricPublicKey, address pedersenAddress, uint[] memory _startTimes, uint[] memory _endTimes) public payable {
        require(_startTimes.length == _endTimes.length);
        for (uint i = 0; i < _startTimes.length; i++) {
            validTimeRangesForInputs.push(TimestampRange(_startTimes[i], _endTimes[i]));
        }
        
        managerAddress = msg.sender;
        managerAsymmetricPublicKey = _managerAsymmetricPublicKey;
        
        pedersen = Pedersen(pedersenAddress);

        INPUT_DEADLINE = _inputDeadline;
        MANAGER_CHALLENGE_DEADLINE = _managerChallengeDeadline;
        USER_RESPONSE_DEADLINE = _userResponseDeadline;
        FINALIZE_DEADLINE = _finalizeDeadline;
    }

    // Submit input and reveal to manager via ciphertext
    function SubmitInput(
        uint inputCommitmentX, 
        uint inputCommitmentY, 
        uint[] memory identityXCommitments,
        uint[] memory identityYCommitments,
        bytes memory cipher
    ) public payable {
        require(block.timestamp < INPUT_DEADLINE);   //during bidding Interval  
        bool validTime = false;
        for (uint i = 0; i < validTimeRangesForInputs.length; i++) {
            if (block.timestamp >= validTimeRangesForInputs[i].start && block.timestamp <= validTimeRangesForInputs[i].end) {
                validTime = true;
            }
        }
        require(validTime == true);
        require(identityXCommitments.length == identityYCommitments.length);
        
        // require(bidders[msg.sender].existing == false); 
        userInputs.push(UserInput
            (
                inputCommitmentX, 
                inputCommitmentY, 
                identityXCommitments,
                identityYCommitments,
                new bool[](identityXCommitments.length),
                cipher, 
                block.timestamp,
                true
            )
        );
    }
    function ChallengeCiphertext(uint _challengeIdx) public challengeByAuctioneer {
        require(block.timestamp < MANAGER_CHALLENGE_DEADLINE);
        require(_challengeIdx < userInputs.length);

        userInputs[_challengeIdx].valid = false;
    }

    function ProvideValidityProof(uint _challengeIdx) public {
        require(block.timestamp < USER_RESPONSE_DEADLINE);
        require(_challengeIdx < userInputs.length);

        //TODO: provide validity proof of encryption to manager
        //set valid to true
    }

    function Finalize() public challengeByAuctioneer {
        require(block.timestamp < FINALIZE_DEADLINE && block.timestamp > USER_RESPONSE_DEADLINE);
        
        uint count = 0;
        for (uint i = 0; i<userInputs.length; i++)  {
           
            if (!userInputs[i].valid) {
                //ignore this. User did not provide a valid proof in time
            } else {
                count++;
            }
        }
        UserInput[] memory validUserInputs = new UserInput[](count); 
        count = 0;
        for (uint i = 0; i<userInputs.length; i++)  {
            if (!userInputs[i].valid) {
                //TODO: ignore this. User did not provide a valid proof in time
            } else {
                validUserInputs[count] = userInputs[i];
                count++;
            }
        }


        //Execute proof logic using validUserInputs
        //Note manager must be able to prove they know committed values

    }

    function HandleManagerAbort() public {
        //TODO: handle the case where the manager aborts
    }

    modifier challengeByAuctioneer() {
        require(msg.sender == managerAddress); //by auctioneer only
        _;
    }
}