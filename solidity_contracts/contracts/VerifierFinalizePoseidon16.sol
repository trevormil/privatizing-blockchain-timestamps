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
library VerifierFinalizePoseidon16 {
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
            [5057724729880162433204362502006824851423707290020042570228324884329286464075,
             14160719788089764778674828496091453135950890697279625922237890710597160823785],
            [16564306677224367651023621203766111384721432721177818749112391383287045625290,
             1224572993656036588608850272164081351910679960180814943024474740427515634948]
        );
        vk.IC = new G1Point[](33);
        
        vk.IC[0] = G1Point( 
            4563912066823729407621567767085330670656028643727261770650197614696756631815,
            5056869880832876470175178751977371663559124680733413357525792151604418760452
        );                                      
        
        vk.IC[1] = G1Point( 
            9198236670719544510127767930857132157638941267584428940355202444944988808130,
            2726383619816080084813873683936149968904054365446755391272750095320731190183
        );                                      
        
        vk.IC[2] = G1Point( 
            2937887996643363136229419420956826537067756773173538313321691477315284149457,
            18011850154936095785244734710509431916464414771661377362664155730574548291943
        );                                      
        
        vk.IC[3] = G1Point( 
            15691648164937340271093032501713776552399640006551270943586417023309544440148,
            11742664436847486207664654778841467971773250917050468189567586914469313184514
        );                                      
        
        vk.IC[4] = G1Point( 
            12848151011561874242243156876416893048744337295968600054304983319501667309013,
            12270009523526236518195965404514775312966847267231645888393095610463519800807
        );                                      
        
        vk.IC[5] = G1Point( 
            21103138765360296914323974125499588747564670913841147265545396742604360870274,
            20764757903006087020645869445213393669121258171273140512727496763361733834676
        );                                      
        
        vk.IC[6] = G1Point( 
            18195345257511170909852934562002961010063530216053982840860180257730164828383,
            7122161712959840771342205939596659472113155182505303128823013851713591685130
        );                                      
        
        vk.IC[7] = G1Point( 
            13925195216648954747345968667189237143495745427349188625726744134177452255933,
            9919270159563704369379868940128065359624796575834300847454632603170392140115
        );                                      
        
        vk.IC[8] = G1Point( 
            17027196768912514145894424511316166221189587211766091025927497132517765786985,
            2223634413747186071741873874249751762777509343566674411626042950887502649655
        );                                      
        
        vk.IC[9] = G1Point( 
            12492381931393585579924900991857133261257414373555777309487394850517404134673,
            13378806962510839198667559039202559270713779776203579166177533041161548381534
        );                                      
        
        vk.IC[10] = G1Point( 
            769415556287184246330324394811527847274138106738169715831249809133059636714,
            16601763015674156657566507298769821643003314421448947909207675369458681836297
        );                                      
        
        vk.IC[11] = G1Point( 
            3117274646250668514341112037272334209321961636680309348985733796440548342648,
            20763061348334052560025806065290601173713718621990200334725494921559222384684
        );                                      
        
        vk.IC[12] = G1Point( 
            19776076962239402744508303685938371822263163919368591760496686445178873450601,
            5156970082860173142906463928794244007554172027185029111984265896129104764947
        );                                      
        
        vk.IC[13] = G1Point( 
            13377151574651259433082620229823421276515340834616590564660427787769334481655,
            1675496802349756773907336446723382410222880336025026674828488492352730225801
        );                                      
        
        vk.IC[14] = G1Point( 
            13914129689322297574365351904113797707968706667566656035066643654877769180390,
            21619542153274950584730049006546194440940028853966766884472895211889380623497
        );                                      
        
        vk.IC[15] = G1Point( 
            5552459689215470377248043806575632742688507114119288280080602242091922752112,
            13897590865199265678387764243746048053289892592471576689156896111332844170905
        );                                      
        
        vk.IC[16] = G1Point( 
            13775135199039072079366045891915086042461069143084261759646163337061622351745,
            7756048533086734852446675270933670541802172971104468329599552059915544947653
        );                                      
        
        vk.IC[17] = G1Point( 
            14876093204692560532243731893157773969677274620341077457112179270784122140193,
            9934090847010891521087528621054167066337857567774980135310728338542022595042
        );                                      
        
        vk.IC[18] = G1Point( 
            8539705105883775340941456566785210199610163825948654800853196384613927268747,
            3806685234394174012867537664464430862722685014798690688405333166767601811365
        );                                      
        
        vk.IC[19] = G1Point( 
            7055363327942903319121605974211186293282101789207670104282561605828566744828,
            16621424742019542302704810288402974143866180091762324670942125062403646587368
        );                                      
        
        vk.IC[20] = G1Point( 
            17818964473081244799490751036528191648132041775288011846354783639623303014732,
            17349107600978049049477322850343493701268726512772133145310957386822927867215
        );                                      
        
        vk.IC[21] = G1Point( 
            18406482395726708375024622802492930384859668481432611181915309166238372117756,
            19999634479357107360592481582055657842566846126478235870095622358077437716792
        );                                      
        
        vk.IC[22] = G1Point( 
            9475668656284759599807451011780095923762215231860681391777649436785336475375,
            20304984112972124667574000305233382518474050737147340534093322581659145306077
        );                                      
        
        vk.IC[23] = G1Point( 
            19212661307897007547119619378059388940949145924159316277362747220926205326169,
            20214547421850244541912550864437703225387580057673835406603664529835347329980
        );                                      
        
        vk.IC[24] = G1Point( 
            5138262141990096716531729325224885566491292710768426510202411773745613197977,
            3308790432986917133316424302552892176098613151181937225904515544924536808462
        );                                      
        
        vk.IC[25] = G1Point( 
            19761577593692596648086122360889395542601765709593445593218654885971170049482,
            5829766600538996252486946499372207431673636818006354691654782634560278468311
        );                                      
        
        vk.IC[26] = G1Point( 
            1217740190751728095625540521415982090784364801258816898101907801675526679552,
            10553646291674579473566233858375952558873832796911367232751147158860256437498
        );                                      
        
        vk.IC[27] = G1Point( 
            7618171577170533375736790661360434627793413709580154149477417753996954727353,
            587052200194689897328278304484453907695929021418153070320625683608003081750
        );                                      
        
        vk.IC[28] = G1Point( 
            6151105840716634056367942847116589950780213520007292336415304772502768660075,
            14307248217201499828938897072050256219428319054456962091991746229202438805374
        );                                      
        
        vk.IC[29] = G1Point( 
            18964757101342191588780023574197849322185918637843733640309079166253796176760,
            10625400589699185720571684749488350751984944693166199426781071594040418186569
        );                                      
        
        vk.IC[30] = G1Point( 
            3842487627361353112692247993510940244077349285848804548657031755296011378297,
            16207254843023940873842382909650168308897063347765317203030994245497411261341
        );                                      
        
        vk.IC[31] = G1Point( 
            12359129562281915540733501064842063375161502672958799337340464488453859692853,
            8159208448001469222847597818952365331493634671106153395042273160320426002653
        );                                      
        
        vk.IC[32] = G1Point( 
            15903688826254867163272493967594738436395862388037367443977332515342042524162,
            17760158423957027338278445561096812160335267489107121455920608967723515679946
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
            uint[32] memory input
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
