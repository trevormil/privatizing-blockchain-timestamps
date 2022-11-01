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
pragma solidity >=0.7.0 <0.9.0;
library VerifierFinalizePoseidon8 {
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
    struct VerifyingKey {
        G1Point alfa1;
        G2Point beta2;
        G2Point gamma2;
        G2Point delta2;
        G1Point[] IC;
    }
    struct Proof {
        G1Point A;
        G2Point B;
        G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = G2Point(
            [2904757190753498698418390578051492435459271579060694138866011122818709307617,
             13792916024141529825291322303119933871108764145113972663201555582664250210371],
            [9291387406526079945141183933673086732177305375826235328727353452458127570644,
             3012856483793412707899199532204295093201993360438042343305620505221716278835]
        );
        vk.IC = new G1Point[](17);
        
        vk.IC[0] = G1Point( 
            7746753543431580950336333197084261415855932204202830734358577683385570017928,
            20523199597741961324012362819649868690969969526013206648844716799670396824049
        );                                      
        
        vk.IC[1] = G1Point( 
            9786313057079865103685534132494398623869784006343028451207583240136555860421,
            5883661972595340547575134249694230684615428850115517023490959593598028198016
        );                                      
        
        vk.IC[2] = G1Point( 
            2612932319719993502847415443796240556039526239650419836159731099309404395583,
            4813138272415687660269119497015331412039399778990148847526880947638809339205
        );                                      
        
        vk.IC[3] = G1Point( 
            1217246583053941390492605204904577758109192983223537969694172565865894421010,
            3325078871990405942540709284969058701152103847592844883588777118124550594254
        );                                      
        
        vk.IC[4] = G1Point( 
            10307086452129963389095994679794618245710170220494419698626494992045165018713,
            18938977806992217272704253709820932942727401564504010779774718356851964233788
        );                                      
        
        vk.IC[5] = G1Point( 
            20287252727273469224108789750145240784083573817422187246315920837270178176322,
            19846761392382128225561716177345073403160210624725534445613327639949896381454
        );                                      
        
        vk.IC[6] = G1Point( 
            3765463252696157505329763701693661346880834052163933633190131517479563557420,
            14529069592572439269102423338377607980541372920811342796426375247996545124529
        );                                      
        
        vk.IC[7] = G1Point( 
            11981226497752737981318837949188934553331351735120684965676758968338734982873,
            14941621910980882650011410558444473166036152905324846135609420783968851813020
        );                                      
        
        vk.IC[8] = G1Point( 
            1424766576573177289899089476904087063468655097708675041692295398001911824381,
            13025170061839638409515737518067157091229463751559398923337294516771934835586
        );                                      
        
        vk.IC[9] = G1Point( 
            7293166542408660790394002287134743066115658362606925220180607037064286814088,
            9324333723265201421609617389637118568983144758331457984898296647257484007107
        );                                      
        
        vk.IC[10] = G1Point( 
            4322696675149734409712000675980957200773776228067507683006192400927425023085,
            7542588053257645285324062699449285285928988711170194869368014671743554810325
        );                                      
        
        vk.IC[11] = G1Point( 
            10229523141981544236745863955757883984154079171041776532507337811971757926436,
            10850003547535230859119586252074668941058394834169177470947919799982078048538
        );                                      
        
        vk.IC[12] = G1Point( 
            3054468600013424537247039573913038891636752022225470111221119780851194524361,
            4054105614653913337994659695800737655917261577105760019587953598359971771187
        );                                      
        
        vk.IC[13] = G1Point( 
            21129500020357737732048557098514206543704943010051209666426475015218550590765,
            7502985449286699951029474063115587985946780915218385695363612989342053510157
        );                                      
        
        vk.IC[14] = G1Point( 
            17243201073661544619596679417592995830247543348102653112287003948146070406928,
            10075632618813093751767884431053764432442892236351213937566051663418084493486
        );                                      
        
        vk.IC[15] = G1Point( 
            691505405548233861346507277706379206669294023963277839708596784527013069161,
            12172583354662676590450428178588865082478689279167808932829554464847768355839
        );                                      
        
        vk.IC[16] = G1Point( 
            14981681397599945524728993703856233352753460984212247576510345856284458974962,
            4706488657467405028870710091334993545259973092457030205763280233362001544316
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        G1Point memory vk_x = G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = addition(vk_x, scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = addition(vk_x, vk.IC[0]);
        if (!pairingProd4(
            negate(proof.A), proof.B,
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
            uint[16] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = G1Point(a[0], a[1]);
        proof.B = G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = G1Point(c[0], c[1]);
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
