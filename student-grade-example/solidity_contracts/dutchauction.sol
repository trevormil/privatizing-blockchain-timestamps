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
    Verifier finalizeVerifier;

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
    uint public constant MAX_INPUTS = 10000;


    //Constructor = Setting all parameters
    function Auction(uint _inputDeadline, uint _managerChallengeDeadline, uint _userResponseDeadline, uint _finalizeDeadline, string memory _managerAsymmetricPublicKey, address pedersenAddress, address verifierAddress, uint[] memory _startTimes, uint[] memory _endTimes) public payable {
        require(_startTimes.length == _endTimes.length);
        for (uint i = 0; i < _startTimes.length; i++) {
            validTimeRangesForInputs.push(TimestampRange(_startTimes[i], _endTimes[i]));
        }
        
        managerAddress = msg.sender;
        managerAsymmetricPublicKey = _managerAsymmetricPublicKey;
        
        pedersen = Pedersen(pedersenAddress);
        finalizeVerifier = Verifier(verifierAddress);

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
        require(userInputs.length < MAX_INPUTS);
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
    function ChallengeCiphertext(uint _challengeIdx) public challengeByManager {
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

    function Finalize(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[10] memory publicSignals
    ) public challengeByManager {
        require(block.timestamp < FINALIZE_DEADLINE && block.timestamp > USER_RESPONSE_DEADLINE);

        //TODO: verify inputs are validly formed with userInputs

        if (!finalizeVerifier.verifyProof(a, b, c, publicSignals)) {
            revert();
        }

        //Execute logic based on the outputs

        //Execute proof logic using validUserInputs
        //Note manager must be able to prove they know committed values
    }

    function HandleManagerAbort() public {
        //TODO: handle the case where the manager aborts

    }

    modifier challengeByManager() {
        require(msg.sender == managerAddress); //by auctioneer only
        _;
    }
}

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [13893253862882797172040056079802058599720741726436228759945582801725277638649,
             16190579373173608198400927777237649529648979069684684092112340742931050118192],
            [8451286079606532944467159761108087628840976715371383803799387073903315565359,
             3249481832754372036482249753856696720629006894595768908515812196854364759892]
        );
        vk.IC = new Pairing.G1Point[](11);
        
        vk.IC[0] = Pairing.G1Point( 
            8598593365309930731425917435759936154357616178374966863571353157656853730001,
            13490439743760944250764016542430247188380288535680544994188407350834318857662
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            1301046411208773663116774063752687606467446952893416306592031654152233223791,
            2323904326415367762516507619984376518991490984378974749581580464932476285165
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            1334052628445560474254512788341005247634017572501022223620206372507152024938,
            14106797417095783249249208137837717017099980816505990566112174550563236947049
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            6301726595389133360622546725784886283719879765790651931786019388185006714024,
            14967325488557057169542172516408260874794343385971311749787112151195713455309
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            1886440645451258767715014751919496914057144813845766776510384974321063040978,
            655222923449997625101533735362241039848576506134704021556019120166778517964
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            17878439772393893570123022402156898925044362234864018184301397239421539442899,
            6522081624936499158312286025356577869162046306077660043995833513703603254209
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            8879706044950097353702472842521328290485501124884035503463381510695909279962,
            669026801806057882911946782792247749580950119359265725250243255417381323688
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            1548712768588183795626520506885444291784115372719055552908375212366900985106,
            4112013540893825039379023054145926467725809671817952874738613818227607661347
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            2525902817117084029651321424744408966352285332206682192542879862281376701155,
            8835657175271342890470857426542020205500290910864039793172440966782534211395
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            5499894683837688929965204959699001591164511103827907020096225007145721525251,
            9372502145306859623166072073993031312274897227154137808790164994999857811926
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            14622512040809878894304689640974462479798620638942717131243269612195893044272,
            21515609444655856608779057000091637333242166500304230748108108809322538483651
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[10] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
