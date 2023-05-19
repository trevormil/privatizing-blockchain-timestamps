// SPDX-License-Identifier: GPL-3.0

//with minor changes -> pseudonymity

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

contract PseudoStateUpdateAuction {
    enum VerificationStates {Init, Challenge,ChallengeDelta, Verify, VerifyDelta, ValidWinner}
    struct Bidder {
        uint bidCommitX;
        uint bidCommitY;
        uint proofOfBidderForRevealCommitX;
        uint proofOfBidderForRevealCommitY;
        uint proofOfBidderForWithdrawCommitX;
        uint proofOfBidderForWithdrawCommitY;
        bytes cipher;
        bool validProofs;
        bool paidBack;
        bool existing;
        uint timestamp;
    }
    Pedersen pedersen;
    bool withdrawLock;
    VerificationStates public states;
    uint private challengedBidder;
    uint private challengeBlockNumber;
    bool private testing; //for fast testing without checking block intervals
    uint8 private K = 10; //number of multiple rounds per ZKP 
    uint public Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint public V = 5472060717959818805561601436314318772174077789324455915672259473661306552145;
    
    uint[] commits;
    uint[] deltaCommits;
    Bidder[] public bidders;
    uint mask =1;
    //Auction Parameters
    address public auctioneerAddress;
    uint    public bidBlockNumber;
    uint    public revealBlockNumber;
    uint    public winnerPaymentBlockNumber;
    uint    public maxBiddersCount;
    uint    public fairnessFees;
    string  public auctioneerRSAPublicKey;
    
    struct TimestampRange {
        uint start;
        uint end;
    }
    TimestampRange[] validTimeRanges;

    //these values are set when the auctioneer determines the winner
    uint public winner;
    uint public highestBid;    
    //Constructor = Setting all Parameters and auctioneerAddress as well
    function Auction(uint _bidBlockNumber, uint _revealBlockNumber, uint _winnerPaymentBlockNumber, uint _maxBiddersCount, uint _fairnessFees,  string memory _auctioneerRSAPublicKey, address pedersenAddress, uint8 k, uint[] memory _startTimes, uint[] memory _endTimes, bool _testing) public payable {
        require(msg.value >= _fairnessFees);
        auctioneerAddress = msg.sender;
        bidBlockNumber = block.number + _bidBlockNumber;
        revealBlockNumber = bidBlockNumber + _revealBlockNumber;
        winnerPaymentBlockNumber = revealBlockNumber + _winnerPaymentBlockNumber;
        maxBiddersCount = _maxBiddersCount;
        fairnessFees = _fairnessFees;
        auctioneerRSAPublicKey = _auctioneerRSAPublicKey;  
        pedersen = Pedersen(pedersenAddress);
        K= k;
        testing = _testing;
        require(_startTimes.length == _endTimes.length);
        for (uint i = 0; i < _startTimes.length; i++) {
            validTimeRanges.push(TimestampRange(_startTimes[i], _endTimes[i]));
        }
    }
    function Bid(
        uint bidCommitX, 
        uint bidCommitY, 
        uint proofOfBidderForRevealCommitX,
        uint proofOfBidderForRevealCommitY,
        uint proofOfBidderForWithdrawCommitX,
        uint proofOfBidderForWithdrawCommitY
    ) public payable {
        require(block.number < bidBlockNumber || testing);   //during bidding Interval  
        require(bidders.length < maxBiddersCount); //available slot
        require(msg.value >= fairnessFees);  //paying fees

        bool validTime = false;
        for (uint i = 0; i < validTimeRanges.length; i++) {
            if (block.timestamp >= validTimeRanges[i].start && block.timestamp <= validTimeRanges[i].end) {
                validTime = true;
            }
        }
        require(validTime == true);

        // require(bidders[msg.sender].existing == false); 
        bidders.push(Bidder(
            bidCommitX, 
            bidCommitY, 
            proofOfBidderForRevealCommitX,
            proofOfBidderForRevealCommitY,
            proofOfBidderForWithdrawCommitX,
            proofOfBidderForWithdrawCommitY,
            "", false, false, true, block.timestamp)
        );
    }
    function Reveal(bytes memory cipher, uint _bidIdx, uint _revealProof, uint _r) public {
        require(block.number < revealBlockNumber && block.number > bidBlockNumber || testing);
        require(pedersen.Verify(_revealProof, _r, bidders[_bidIdx].proofOfBidderForRevealCommitX, bidders[_bidIdx].proofOfBidderForRevealCommitY)); //valid open of winner's commit
        bidders[_bidIdx].cipher = cipher;
    }
    function ClaimWinner(uint _winner, uint _bid, uint _r) public challengeByAuctioneer {
        require(states == VerificationStates.Init);
        require(bidders[_winner].existing == true); //existing bidder
        require(_bid < V); //valid bid
        require(pedersen.Verify(_bid, _r, bidders[_winner].bidCommitX, bidders[_winner].bidCommitY)); //valid open of winner's commit        
        winner = _winner;
        highestBid = _bid;
        states = VerificationStates.Challenge;
    }
    function ZKPCommit(uint y, uint[] memory _commits, uint[] memory _deltaCommits) public challengeByAuctioneer {
        require(states == VerificationStates.Challenge || testing);
        require(_commits.length == K *4);
        require(_commits.length == _deltaCommits.length);
        require(bidders[y].existing == true); //existing bidder
        challengedBidder = y;
        challengeBlockNumber = block.number;
        for(uint i=0; i< _commits.length; i++)
            if(commits.length == i) {
                commits.push(_commits[i]);
                deltaCommits.push(_deltaCommits[i]);
            } else {
                commits[i] = _commits[i];
                deltaCommits[i] = _deltaCommits[i];
            }
        states = VerificationStates.Verify;
    }
    function ZKPVerify(uint[] memory response, uint[] memory deltaResponses) public challengeByAuctioneer {
        require(states == VerificationStates.Verify || states == VerificationStates.VerifyDelta);
        uint8 count =0;
        uint hash = uint(blockhash(challengeBlockNumber));
        mask =1;
        uint i=0;
        uint j=0;
        uint cX;
        uint cY;
        while(i<response.length && j<commits.length) {
            if(hash&mask == 0) {
                require((response[i] + response[i+2])%Q==V);
                require(pedersen.Verify(response[i], response[i+1], commits[j], commits[j+1]));
                require(pedersen.Verify(response[i+2], response[i+3], commits[j+2], commits[j+3]));
                i+=4;
            } else {
                if(response[i+2] ==1) //z=1
                    (cX, cY) = pedersen.ecAdd(bidders[challengedBidder].bidCommitX, bidders[challengedBidder].bidCommitY, commits[j], commits[j+1]);
                else
                    (cX, cY) = pedersen.ecAdd(bidders[challengedBidder].bidCommitX, bidders[challengedBidder].bidCommitY, commits[j+2], commits[j+3]);
                require(pedersen.Verify(response[i], response[i+1], cX, cY));
                i+=3;
            }
            j+=4;
            mask = mask <<1;
            count++;
        }
        require(count==K);
        count =0;
        i =0;
        j=0;
        while(i<deltaResponses.length && j<deltaCommits.length) {
            if(hash&mask == 0) {
                require((deltaResponses[i] + deltaResponses[i+2])%Q==V);
                require(pedersen.Verify(deltaResponses[i], deltaResponses[i+1], deltaCommits[j], deltaCommits[j+1]));
                require(pedersen.Verify(deltaResponses[i+2], deltaResponses[i+3], deltaCommits[j+2], deltaCommits[j+3]));
                i+=4;
            } else {
            (cX, cY) = pedersen.CommitDelta(bidders[winner].bidCommitX, bidders[winner].bidCommitY, bidders[challengedBidder].bidCommitX, bidders[challengedBidder].bidCommitY);
            if(deltaResponses[i+2]==1) 
                (cX, cY) = pedersen.ecAdd(cX,cY, deltaCommits[j], deltaCommits[j+1]);
            else
                (cX, cY) = pedersen.ecAdd(cX,cY, deltaCommits[j+2], deltaCommits[j+3]);
            require(pedersen.Verify(deltaResponses[i],deltaResponses[i+1],cX,cY));
            i+=3;
            }
            j+=4;
            mask = mask <<1;
            count++;
        }
        require(count==K);
        bidders[challengedBidder].validProofs = true;
        states = VerificationStates.Challenge;
    }
    function VerifyAll() public challengeByAuctioneer {
        for (uint i = 0; i<bidders.length; i++) 
                if(i != winner)
                    if(!bidders[i].validProofs) {
                        winner = maxBiddersCount + 1; //precondition: this doesn't overflow
                        revert();
                    }

        states = VerificationStates.ValidWinner;
    }
    function Withdraw(uint _bidIdx, uint _withdrawProof, uint _r) public {
        require(states == VerificationStates.ValidWinner || block.number>winnerPaymentBlockNumber);
        require(pedersen.Verify(_withdrawProof, _r, bidders[_bidIdx].proofOfBidderForWithdrawCommitX, bidders[_bidIdx].proofOfBidderForWithdrawCommitY)); //valid open of winner's commit
        require(_bidIdx != winner);
        require(bidders[_bidIdx].paidBack == false && bidders[_bidIdx].existing == true);
        require(withdrawLock == false);

        withdrawLock = true;
        payable(msg.sender).transfer(fairnessFees);
        bidders[_bidIdx].paidBack = true;
        withdrawLock = false;
    }
    function WinnerPay(uint _bidIdx, uint _withdrawProof, uint _r) public payable {
        require(states == VerificationStates.ValidWinner);
        require(_bidIdx == winner);
        require(pedersen.Verify(_withdrawProof, _r, bidders[_bidIdx].proofOfBidderForWithdrawCommitX, bidders[_bidIdx].proofOfBidderForWithdrawCommitY)); //valid open of winner's commit
        require(msg.value >= highestBid - fairnessFees);
    }
    function Destroy() public {
        selfdestruct(payable(auctioneerAddress));
    }
    modifier challengeByAuctioneer() {
        require(msg.sender == auctioneerAddress); //by auctioneer only
        require(block.number > revealBlockNumber && block.number < winnerPaymentBlockNumber || testing); //after reveal and before winner payment
        _;
    }
}