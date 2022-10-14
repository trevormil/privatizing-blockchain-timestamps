//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
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


// {
     
    "delta" :[["0x1145eb39cc9ff82ca251c8740e25e83355577b8637cd791260801ad4cde885b0", "0x172ac15f11b8f8d183665ad0addff8a17d3941d902b1a3944e32dad9804023e0"],
//  ["0x1a1ffbba47da0b4e57ea2052890abb51a84f52d7a0c030e78580bd4d99134ba5", "0x2c16310785beb04d77f0b996108e3953f38739a5507e37695becc362a68730e8"]],
// "gammaABC" :[
    ["0xc62cc8f016903db5323f083b958480ae781e6e1ebf6e36bbcbc678cf61ace25", "0x106187fe80ce01ae5ba372cd34ba931a87be18aed6a020b136d212d5b228fc88"],["0x146f92e21b9c9321bb9592beecd59befa66b2b91e011d>


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
            20249559011249543597834221842557669029490255335460934091562171037548838239722,
            16834112946643546654375102360304424721876892153098507564227836883330061667968
        );

        vk.beta2 = Pairing.G2Point(
            [21853465597455931541994105873957476010127751529489543221309827216925878185251,
             20172885146004494540926916654744464792958207264388476509119952604987363828209],
            [17304396699021880521024495735369977064819139656607721235740680355063783644864,
             404736289976164602216865241914163813828610145355633075597966664406899300503]
        );
        vk.gamma2 = Pairing.G2Point(
            [68444239957528873863623371513776906527640075067171418345138022048610033750,
             18643646569942674820714619743073343315816898277951250369997162404029193366861],
            [12418764663980806350269776707560437214683811766652445623007894726662352910723,
             21820914581461028735051611344910470561575372168245515911931617215123486708352]
        );
        vk.delta2 = Pairing.G2Point(
            [7812854342043208038510972026683973489129118870171860051275017957444283827632,
             10478737694242085036324110448572346518685933843290198180019154755125411587040],
            [11816643682623051408382805146575289413260791963570046992748185789417194212261,
             19940974361464444517121573162938254334303371039006136199574006019794183598312]
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
