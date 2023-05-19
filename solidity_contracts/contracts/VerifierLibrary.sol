// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
library VerifierFinalizeStandard8
    {
        function NegateY( uint256 Y )
            internal pure returns (uint256)
        {
            uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
            return q - (Y % q);
        }
    
    
        //Obtained from EthSnarks
        function Verify ( uint256[14] memory in_vk, uint256[] memory vk_gammaABC, uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
            require( ((vk_gammaABC.length / 2) - 1) == proof_inputs.length );
    
            // Compute the linear combination vk_x
            uint256[3] memory mul_input;
            uint256[4] memory add_input;
            bool success;
            uint m = 2;
    
            // First two fields are used as the sum
            add_input[0] = vk_gammaABC[0];
            add_input[1] = vk_gammaABC[1];
    
            // Performs a sum of gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]
            for (uint i = 0; i < proof_inputs.length; i++)
            {
                require( proof_inputs[i] < snark_scalar_field );
                mul_input[0] = vk_gammaABC[m++];
                mul_input[1] = vk_gammaABC[m++];
                mul_input[2] = proof_inputs[i];
    
                assembly {
                    // ECMUL, output to last 2 elements of `add_input`
                    success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
                }
                require( success );
    
                assembly {
                    // ECADD
                    success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
                }
                require( success );
            }
    
            uint[24] memory input = [
                // (proof.A, proof.B)
                in_proof[0], in_proof[1],                           // proof.A   (G1)
                in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)
    
                // (-vk.alpha, vk.beta)
                in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
                in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)
    
                // (-vk_x, vk.gamma)
                add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
                in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)
    
                // (-proof.C, vk.delta)
                in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
                in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
            ];
    
            uint[1] memory out;
            assembly {
                success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
            }
            require(success);
            return out[0] != 0;
        }
    
        function VerifyFinalizeStandard8 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x2568fe78f8f226d7ce56054246180445bd5bdc18aea5be88d37a3601767fc61,0x2c7173bd5e9fcc40f6fc10b472403572c1c440b63d6d59495915b8f609fac125,0x22ffac608952208cf84ad86398ee9a9999aaf1e46ee044f4b9b859a29ad16820,0x144af18501b1ac8784c41065ae41993d68a0dd6c5ac25173bfcf08b72b3efd51,0x25b416485114e8ac8afbc375ca508d7777480d77803b6d989b2285f68d625948,0x1119a1fcf844e0610c375ae901c85b90c21644bae5ffc37ade34cc65127af0ea,0x39a4a337633132a8cf11089b9977b6aa0c926ffef8483fd564146bacd756b52,0x1202524c9ba9e83fb56b22e5153d3a01ffffcf2c805506ebce3b375928c58851,0x8dd716690d9a30c742dbf196bc12a4aa9283598d880cdede8218ae42710f576,0xd57019de3f96982ec95812919ed95f241a482e2e5bbaca8dc3cda79abebc8a1,0xfcb62fa7a6496fa8fe9a26ebe2f05fb1f1d9cb5cfef91071be1a202da30b95d,0x8dd3f80af4efa9c5e1aa0cb52606838d3c724dd37f1ea35ae059f78e3dba8bd,0x2c64ae1e14005cb4e10391bc23637db36552f5682582643583d73bf40f4776ee,0x246a7ce97c9c1d50104a1b7f99be5af5bb452cd2861f6a182de7d54165936e9b];
    
            uint256[] memory gammaABC = new uint[](148);
    
    
			gammaABC[0] = 0x3010d6cb15ff93a4c35273e09481aa45db12a3d2cf421c0e2027098862c5f6a1;
			gammaABC[1] = 0x2d2a086d3bdb49035ec9af0b9816c1a5dde1af65e30fdb9f30b5d4f1216b92f5;
			gammaABC[2] = 0x2b1f90ff3dc20c6ecd374ae6ba738240651e90dea0201d56522d92735292dd2a;
			gammaABC[3] = 0xbbae81bf469b8bea4f19f8832511f38aaf7a09639e810232326ab436c86b986;
			gammaABC[4] = 0xadf37e0e896a6175c15d49b9e7ca55259a517f6c80a8154c8f679278678ec76;
			gammaABC[5] = 0x66f5ea3e74fb59582ea261a98335643adbf54d7a493f4429c634d39b75f4a42;
			gammaABC[6] = 0x29b0f48ea9deaaf292f0b333aea08c13a2cef2cb1ddd92bb335909c0464c92d1;
			gammaABC[7] = 0x2accf35ba5915962ee632cf1ac4b33dbc1ee39349349dccd589859dfdd6592e4;
			gammaABC[8] = 0x46ba1cbe0fc91f70da8009949248730ed8f21df24153913c1342c797d7d6845;
			gammaABC[9] = 0xd5376cad410c617dca3264a63fe8a647d036edf2fc3a82898c1016af7e46acc;
			gammaABC[10] = 0x123e27bbbd315a488b64bd576a468ecceb8b628352ff770abaaed112ec8847fb;
			gammaABC[11] = 0x1527b1d04604b9df0986800effa5dcdb70643454d9f7712fd6a103753138990e;
			gammaABC[12] = 0x2985155973a73be94cc640a23203f859fc9955e871daee24c9b1b7a7dcb9292f;
			gammaABC[13] = 0x20169c728c18e42a88810bb35d35bad709c49ff6f2f06776144ff666c34065d8;
			gammaABC[14] = 0x18bc7caa0b6c3ad0396ccc82323b773467e4e81bf72bba7764119aee00c8e04a;
			gammaABC[15] = 0x1c6260843107f26addc7b2e4f1ef35d96e4fc6ee24767a15879ce4cc94984580;
			gammaABC[16] = 0x24de779c1ff0f25f3614c7fb93a8afb5a81b475f4435e7d7607515edab453fee;
			gammaABC[17] = 0x19871cf502805db01129f9520667116b9c245bd495a4e654b07add03e27eb7e1;
			gammaABC[18] = 0xd5c31271c0c8cc78986e4ffc54facb975700223d91ea783ba656c960e44cce3;
			gammaABC[19] = 0x2b7287ca6bb77597d9a968571fd1500b2c3cbc5dfc6a877936fec540be7ee6f1;
			gammaABC[20] = 0x7b31377d9cb36268ee8301216e0a87e96ab1591897dc0c4be0c86ca2a25e9b9;
			gammaABC[21] = 0x203d3f435704a884f47274448d9c5896dfbb19228e9e33d98fd5035e2992ef98;
			gammaABC[22] = 0x254e4b63ae55d3e93bc49dedcbec0c2e698098ef741ca1e7d29f9048c72b042d;
			gammaABC[23] = 0x29f6b82c3e30b57960e7cd31876d8c5098cde9f6d590ec0b385d1995b7808fbb;
			gammaABC[24] = 0x19714b893ca22b7d8222a64ef568269f8d9b6c1e6236e2666ac4fff648fc46c4;
			gammaABC[25] = 0x4d56567dbb1f285cb5216bad48785c170bf778625fa22f3bdec14dba71af6fa;
			gammaABC[26] = 0xba2af770b1479c7b57032ca24714f9dc67edc4acdbfd224475a3f1e933a51c1;
			gammaABC[27] = 0x2eaa8b63d0ce12731f8c83c24334390dda94b661129a4528de62506017789c0e;
			gammaABC[28] = 0x81dbd094c9c1b12712e1c6ca3c2935e42f8a8b2b6cb8fdd96df2fe728d05aba;
			gammaABC[29] = 0x2ce6ef645f924b3dafd4cf944996456f0b370a2aa22f05412d0f67037c580bc1;
			gammaABC[30] = 0x2ba83bb7681c265a77f1385167b4f42cdc51da6b6d4e8bf164a1aae251bf4c82;
			gammaABC[31] = 0xd7808111fcc247c6e9806720f789a134ebe273474df97536f6f1df8416fd350;
			gammaABC[32] = 0x1053e84c187e26c55056c3a3830968d52ea0f1d3d4d838cd73beba0b75fe6f0e;
			gammaABC[33] = 0x278e02fb380498cd37f241c546663725fb5121949c098ee0a7b2a1d104056ee2;
			gammaABC[34] = 0x1dbfccaa1ab779146cf71391d348d11932c41c7c94ddcd4704053fc9976285d7;
			gammaABC[35] = 0x2217f6db0ac1c3324e3ebd7d4c97082445774997fa2c587032dc539e5e67bf8d;
			gammaABC[36] = 0x291e2b8e3fc71dc1ac6d245813e0d623d0ef42f33e2eedb29852bf2636cff46e;
			gammaABC[37] = 0xa16d704938547641970d322b82c555964b68f4bfd197e1fc3638ffeb1e43ad8;
			gammaABC[38] = 0x21047609714bd55bfd312af25ebfb2bae973b5b42e1ade887fa256e7fa6059c0;
			gammaABC[39] = 0x510f3b63a65fdd1891b1f32d52b80243f7157557f0fa213f4d292fca3869b31;
			gammaABC[40] = 0x1df656a54a14f105c876faa4e6e447f6861bcaa2a9e3d66f4c42536d8d9e512f;
			gammaABC[41] = 0x96c0908221842b1ed9eee4e86b4aad25341ad9adddf876599754498701d738a;
			gammaABC[42] = 0x120cd5dde4064dd238f314c245a0035bb97817c134c715505661d35fc3dc0b30;
			gammaABC[43] = 0x9ad49e5c2e0a3bd7aab2dc92f4379a5eaf77265b2fd97eb1681ae602f893151;
			gammaABC[44] = 0xef57f8ab91c0bead497315bf46aa999170a8474fb0f43decc3a1d34a98db3aa;
			gammaABC[45] = 0x6580605f5969c0054fb3fec4bcdf5aaa83ed4188a77de2f99e06ca5cdbaa3bf;
			gammaABC[46] = 0x107a3a443ddf4b7a776b96962ccd2c53e17af346965e6ec1dfcd735deb2b476f;
			gammaABC[47] = 0x1ec91a4184a286c0b1e35f8766bffee97b49a09c7ff0dcb66854fd2a8468c88d;
			gammaABC[48] = 0x8f2f317eaf91d5f095fbbd706a6bed1c646ad1dcff6d3ca533f09df8d901d26;
			gammaABC[49] = 0x20263d584d66e3f3a26c6904a5de9786e9cf219b47feb88edbd51a76704adb76;
			gammaABC[50] = 0x1b73d9ac627e2c1bcb50682a98877fe1738de54bbd49c0a654127f4fa9215447;
			gammaABC[51] = 0x2691a28b74a78aa3d01f9a9c3d9eac01982b7be051fb5a462987c363007fedb9;
			gammaABC[52] = 0xe78e7ea27c10b0e5f3cd05eb61b7cfbe5a227c8e02c7359d296a1e8fdbec6fe;
			gammaABC[53] = 0x1f72f21b583dbc8e609e7f48fa869f8fbcdbf965120b11a7839079b0a280d05a;
			gammaABC[54] = 0x24a7d747aa16b7f20ff122cc569f84c07c7472422ab3d57ccc8c8781fe2a9973;
			gammaABC[55] = 0x1c9b3581ffb8226378bcb47e63aca9a3f859289c0dc8a0e6c9b62bb5b43e71d3;
			gammaABC[56] = 0x1c0e620c033286e716fd95dd79c4b04f3a873a663e91f4455ec2c744045d8c80;
			gammaABC[57] = 0xb13d21a5fa6e1c17aab29c56bfa8eaa1151317e2cee834d26ab5ee22472587;
			gammaABC[58] = 0x2f5886c5fe6186dabde87b1ddd0bc1e26a3656d8865a73c8bb0251e8b8487076;
			gammaABC[59] = 0x2af7eb3c4cac347236ccb4470d3c03340868f1eeab1c55004ff78aa705e938e7;
			gammaABC[60] = 0x4074bbb907384c1e948c4b46b98c8f5c2f207d4d86f594ac22436f688bf254a;
			gammaABC[61] = 0x11d7e229d7714339a0a5da283286cc4509459a8be066673e332d77c65e8fd354;
			gammaABC[62] = 0x189a930246c9bea915d6334aaecdf9109d696191812aef6b6bf2bb1c8d3bf9bf;
			gammaABC[63] = 0x13a734e953aea8b7708ffbd5befdb2b560996b6fd95b3100fc1b1f5c83a8bf0d;
			gammaABC[64] = 0x7b3a11a7a8372ac47176fa85d02acc6d93871392ea018e97a6667bbc597581f;
			gammaABC[65] = 0x1f139077e7c4eb1ae1cea320038ba62b492447de917df0cc3665ce68d81f6e2;
			gammaABC[66] = 0x17cdef608c48542ac978177f3efbc625ecd0bad4e8b8a64478eda921fe2248ea;
			gammaABC[67] = 0x2f8b3e780565c65f612a09e6de38bd6a1dce8d84b6ad1ba3016aa06a53c050b8;
			gammaABC[68] = 0x243033d33520042cc471385fb4f7dcf621ade2047ef1edc3885d429b672eaa73;
			gammaABC[69] = 0x2574659994458924fe11d90d5ae168acf12f0c21d04bcb34168c8ec008093f75;
			gammaABC[70] = 0xc5d41834c170373029512d72cdbc73ad1a2f820572a211b0ea2d27d648c13ea;
			gammaABC[71] = 0x1fbc2b8c670ee5ea35f34183d6640aa7da6d92a26c6c00303f79569401f4502b;
			gammaABC[72] = 0x2233c43e998891d03ff0b521f5f5e50500649d028170b957097833fd6e39e467;
			gammaABC[73] = 0x1c60118780f0ac4bd05d2c3c33c12336d3b0f233df422b35670f6a3100e2cfb5;
			gammaABC[74] = 0x18d4460b13ea11001939f9d85367099b150328e1902932f8f4f8cc66c1ff58d5;
			gammaABC[75] = 0xcb038b995f93b730f432f716356263d9b644ee74fa1313da8493faf71220b16;
			gammaABC[76] = 0x250558336afda5697a39ad26ad5ad27b1b29a3b7637e00dc07caefbeaf6680a;
			gammaABC[77] = 0x9e4dd6a41b16ca6a2973d777b719f79fd388c06cb5c8d588b6ae861822685c7;
			gammaABC[78] = 0xa9c72039dd3381f3ceda031a66a1064ccedd26ffee3eb706d52a5d4d7af00d7;
			gammaABC[79] = 0x14abff71b943ada541a3422b5cf5b70e8a17fd97ce315aeea9cfc1666bc89b9d;
			gammaABC[80] = 0x131f041e7857e82278e031cc2ab7f588970ebbebed2bdadcd60c3916db83e494;
			gammaABC[81] = 0x2f42117182a3fec67228e7c9533449d57eeb263d8582539b8ce6bc5690cd1b0a;
			gammaABC[82] = 0x2d437780fa6adab13196a33813f438d3675f5b9b1316ebf21bd16afc479f954f;
			gammaABC[83] = 0x193041d09fb05d0c0f14f446f75eabf42b598653f9d872c0029be39664c34561;
			gammaABC[84] = 0x215499050f23c6da17616955431ca899cca2f1355fb4e1ffc17a68ddfb1efffd;
			gammaABC[85] = 0x114f6ea5a9eb813e87dcfb531027c93dfe7477ef6c240ddaafbf43113bf659bf;
			gammaABC[86] = 0x22258fdad6d472ca32b7f1415d7ee4b12e20e0cb2732e3c6ddd74d65aa6f8f35;
			gammaABC[87] = 0xbd57e9e9f4dacddd47ce45a9e12bc7458cd0021675c3f42bdf078f2a9f3ed23;
			gammaABC[88] = 0xa16c5d8eb7fb32b56ac999f5e98ed9c0245991b16a9b156b3cec63ff2a18723;
			gammaABC[89] = 0x25b3f515039f347799077641cdeaddcfd79a0c56ebfbf75265de4b04256c90dd;
			gammaABC[90] = 0xd76d1b77f49692913af947bd62531982c493596430558f825856e365196df52;
			gammaABC[91] = 0x215b1849b10d91c046a426c742a49018d26c80c76a3e10790c7431902283147f;
			gammaABC[92] = 0x895db9c2ed6a230104f72b8cb604f2e0fc8378ee970f6fd56afef67e74fc96c;
			gammaABC[93] = 0x15b481e2f5ae64770a0f5d3f2c1a67680f0621e7dc9673ca666f15f0c01a0af9;
			gammaABC[94] = 0x151d85fe1286234d6035340f11f40cc158308311dd2d86eee97981223aa8155a;
			gammaABC[95] = 0x19a825a7c1b199eb92a57c2f7fb39914f82253b2d7a78b6170dee57589688030;
			gammaABC[96] = 0x13d06da1a0498fb2ff5454d9c9d36248a22066c3082048006f0ac267ffaf05d1;
			gammaABC[97] = 0x2c9e04eb7417c9bbce2ce19a94333eb89ed8f19662552c795f77069c51b95ec9;
			gammaABC[98] = 0xa15d00700256bb3759457d379def0435c34d1acc006d61d73fa94d2b2c03d28;
			gammaABC[99] = 0x1f5b8f7728f79bde38df29fca3b97c977d53e905b226ac05514a8f1c3450ed14;
			gammaABC[100] = 0x116b822fb75c758940473d61f8785fc580b24cbd02d0c8d32b96309ec834b29f;
			gammaABC[101] = 0x4a4d46f0d0c8aee9ccc9a6d07f963fd2174850eec3ae50fe1e2c82204b9d501;
			gammaABC[102] = 0x1c1efafc6be2ed5bdf613bbbe4caaae07ec9de393b4b2769b4b03e4b6c72cb99;
			gammaABC[103] = 0x158993b83012283150cbc51e20d75b6347895c1199c800cdb7f54a504c4ea127;
			gammaABC[104] = 0x25a1c4a5026db255c99485df8506cf832d640eb8a539a2ab5d046f2adfb7692a;
			gammaABC[105] = 0x2645de08f425ab0e1cefa6ca1b7551355358ae57b09dd5a7cf7d768523eabbff;
			gammaABC[106] = 0x1186aa415774f68cec11926a1611d5fec66818e0010d61969440b0ea1a9d16b0;
			gammaABC[107] = 0x2cec5d680037e1ea91be3bc21996e2552cc1e4c666a8f2303de8138b05825fac;
			gammaABC[108] = 0x1cc13afd1ca9c7138f0fd9f84946c03486f508443babf389a7e744b149736cc1;
			gammaABC[109] = 0x190c771add3209769f992be940fc667e73140efba82f8130bb99d54ef4ebc812;
			gammaABC[110] = 0x1c3350d1b4721ee5b9e15cd6083b8942315a3403a50532e50ceb2537cdd56ce6;
			gammaABC[111] = 0xb64ccf2ebf29d0b507ec1afa9233072e4808e501de65ff2cf1c9a196431d710;
			gammaABC[112] = 0x7f0a74ff4adf2582b2b94c73cee2a94f6821e1467160d2b22ad07aa9c91c770;
			gammaABC[113] = 0x238e33cb49b132b774be134c8bf1d46ae88033cc3a2ba6e082ff1f742f1a458e;
			gammaABC[114] = 0xc5224fa2405465c2732295ac335c4bf07bd12ebc9d2a9e2fee33ce7681258ff;
			gammaABC[115] = 0x9100125f4ea1b8739ae145472b5fb94c67291a2349213e63ccb4dd785a967e2;
			gammaABC[116] = 0x2ad9b08cb9bfc547ce27fb84ef959666e5111aefcb5d95f0542957661fe76062;
			gammaABC[117] = 0x298a27e93597356202b4019829ee035c1cee03ef5a98285840efd36d45d28f48;
			gammaABC[118] = 0x25f7edb85b7be973bd6e398eb986f3c83993bb1e43fe6df775fe08fbd8d2a1cc;
			gammaABC[119] = 0x235806f9d69c86078d44224c890dc9c94c6f22fb0548d6693262e13a34e317bf;
			gammaABC[120] = 0x2fddfabc697c01fe1337e3de4e1428ac2aac7e35804b3de4a7bfa2fb44202373;
			gammaABC[121] = 0xade72501ed694e948b8a6cb535fcae89804151871ae67b5b7dac8c085772cba;
			gammaABC[122] = 0x2bdb9dfb4fed87c0360eef82cbc168838d59617f2dde095f619b23d21afec409;
			gammaABC[123] = 0x201899fc11c478bff0ac869b8eabe38d8a6b06c566afd9a303e078d601525d8f;
			gammaABC[124] = 0x2c11cada5fa76a574a37cdb207ac5b1480f4c2f23bd8f86aec6e262178217f80;
			gammaABC[125] = 0xe5eb55d6f76f879272901e3cc42a3cf9576e9de04382feb3425b084abc3d537;
			gammaABC[126] = 0x11f2be2b4702ba53c6e31920dd00994fba1f89852e1c077ee8a168c5789c10c8;
			gammaABC[127] = 0x2e6c0a2e2ad6eb9e023d7aa9fab18d46cac44857cb734347f8902d6ae21e2f75;
			gammaABC[128] = 0x43d9f87ceacbe081876df15a82b1f365b26b4ea1ae556b853f3927692f30753;
			gammaABC[129] = 0x74a462f017d029f3f577e0b1923b0541eee096f22f663d1551966b8284e491d;
			gammaABC[130] = 0x1bd1a7186c66e13839377e3f53ef460fb5627cc6d0a25fbebce6d7bc10902782;
			gammaABC[131] = 0x2ee8e254ea24720992d3d1164ddfc9368383e35785e51aa3b63b57c7ad6ce3a0;
			gammaABC[132] = 0x1b40d2990356873702a3ec358a2982938a813855d273b24f5f8246ee8a67067d;
			gammaABC[133] = 0x1ac1b5af7a743985cfb0b9effa3954d33177d0f163f4026702e20fa3ffa3099;
			gammaABC[134] = 0x283327bfe2da8428957340174e170cdb0c2de597ad17bf2f91b5aed6b6f740b6;
			gammaABC[135] = 0xe5860909b8135421e4d56a7dd3fd319fe64a10c09be1cb98b1d474417cab11d;
			gammaABC[136] = 0x1b7018e6d15bb8b31f7170817622bbb08cd4bbe9d2df78df0307e68278d1711b;
			gammaABC[137] = 0xfff2c2f48bb19cdf9850c646d67658b22a02a57e1006264afac8f342b4f77f2;
			gammaABC[138] = 0x823c24a49950c6fc82df37f867c3662672e91a3d09be92487b2eed4aca936eb;
			gammaABC[139] = 0x2f4b733b15d2b042b842b8e180206c7bf62ea26ee718b50b581225d9f87e9bfc;
			gammaABC[140] = 0xb5f8c8398fb19096343b4be5cac1d308c0f889dbdaffb7fd6e5b6e96053bd0b;
			gammaABC[141] = 0x76c3a630d1f5e4e5cd0ff20c7e54145cca42366e51021305c0ce752423c09e6;
			gammaABC[142] = 0x1b974c661a2c5adba53d74aa1ff7b614fa59679e0fb96d83e873a991d5d55991;
			gammaABC[143] = 0x1ef6a2f4841ecf32f441b38a7ed474aae242c816e4962e7aa812572e5525a2a6;
			gammaABC[144] = 0x98d9e0543b964e26da02bc0ad01d20a759d05e73d036e22877e5b9e3ad312f0;
			gammaABC[145] = 0x19433c88a6f2b1505e650b02e3b1de4250c9c616e83b633280883dcb521f570a;
			gammaABC[146] = 0x29c2c790e875bb69ed0fa649093a84b9d9d0671b517186be948b7b8f7185e10e;
			gammaABC[147] = 0x2b71e737cedf60aecac5bce28a4a059148e786ef70a51b34911e5a1d0da5708a;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierReveal2048
    {
        function NegateY( uint256 Y )
            internal pure returns (uint256)
        {
            uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
            return q - (Y % q);
        }
    
    
        //Obtained from EthSnarks
        function Verify ( uint256[14] memory in_vk, uint256[] memory vk_gammaABC, uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
            require( ((vk_gammaABC.length / 2) - 1) == proof_inputs.length );
    
            // Compute the linear combination vk_x
            uint256[3] memory mul_input;
            uint256[4] memory add_input;
            bool success;
            uint m = 2;
    
            // First two fields are used as the sum
            add_input[0] = vk_gammaABC[0];
            add_input[1] = vk_gammaABC[1];
    
            // Performs a sum of gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]
            for (uint i = 0; i < proof_inputs.length; i++)
            {
                require( proof_inputs[i] < snark_scalar_field );
                mul_input[0] = vk_gammaABC[m++];
                mul_input[1] = vk_gammaABC[m++];
                mul_input[2] = proof_inputs[i];
    
                assembly {
                    // ECMUL, output to last 2 elements of `add_input`
                    success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
                }
                require( success );
    
                assembly {
                    // ECADD
                    success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
                }
                require( success );
            }
    
            uint[24] memory input = [
                // (proof.A, proof.B)
                in_proof[0], in_proof[1],                           // proof.A   (G1)
                in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)
    
                // (-vk.alpha, vk.beta)
                in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
                in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)
    
                // (-vk_x, vk.gamma)
                add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
                in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)
    
                // (-proof.C, vk.delta)
                in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
                in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
            ];
    
            uint[1] memory out;
            assembly {
                success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
            }
            require(success);
            return out[0] != 0;
        }
    
        function VerifyReveal2048 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x2505fcf3b889379844204f561430b02c84c00d31420fd88253a6124b2d62032a,0x14d8e9628b16faadf4b8927eab4c5f58e46325547f3cc69a4400b46fc529577d,0x3bd2074443448540b8af4819b24509cff7b8c650d4fa81c1c1c33a78dbe72eb,0x6d4cd437e4c6237db27654eee742a5aae99dc63815802cb631d9fd9d72c0829,0x1580643d10cdd8105f4a5583cf95f5e7b3ab54750363b27465cb7dce452a0bf7,0x17785b50b70d9460ee80b2e9ecf753eee745ad917f49716a35a3c92c0c4d6c3e,0x2668ac3b54769ff85635f48d67790631def3bf09145267b4772830ad8a9de307,0x17a611c130e1c38fa72c8df2575664426cb4e8529f5c6821d3134101998391be,0x17ec54c8fa7707e679383d5dcd2b81a15b05c34f7a7f56de8bede264e6ec319,0x1fa869460ebe55ce0651fa1e10af9b73e4f331cf8b431513bcc8fdc5f8259379,0x3d455eaa5f26b91b9ca0f925229415b6aa9f544943dd2146618749d3f809b84,0xde98a1d6386aad1bca1f2a183358d75643500963638d77aa737ab7ba8df65e1,0x2bee024137a81714b40b854dbcbdc0b021fa9648fd80b2fdf8700b963c17a9a1,0x506271ecbc94bd91876a649800fc936384f4d71ffb0faf1783d3b593c8f3afd];
    
            uint256[] memory gammaABC = new uint[](140);
    
    
			gammaABC[0] = 0x12a2006f489e87448eef3901744e2b0bdab6e81180d830c47c27775e5faf2dc1;
			gammaABC[1] = 0x1fab3f35db8575f4199121e69ad9d1b08872b8a08ed06a5638659a18ef876fda;
			gammaABC[2] = 0x2496df7708c4c2020935aa05c5e47c124a19e5bbce876ee9c820118281ebe99;
			gammaABC[3] = 0x96588ed449c92a6a02b24de60d427dedc8ddb05798fbd541cbd26eb0aaa1fc7;
			gammaABC[4] = 0x6c49c916aae501eb049c0d014633f068e0449c176daa3d0b8c7847c66aa5afc;
			gammaABC[5] = 0x1bd00a7aa82837a5ffced9121182471dfd230f2986e0d9b4b6aef2a75e79f71c;
			gammaABC[6] = 0x2ae5aadb70059c7ea1d62de63ea2133a6f40dc28f3b249bcb5b7c38f2a4bf58;
			gammaABC[7] = 0x8057f028a8cd17a76e10425a1ea20b480874d5db52a2af87d5a9d07703c9374;
			gammaABC[8] = 0x11d3ec956055e60a78a3f9fb06082e0f846ee6519a1a3236d3fb6bb5ef39b19f;
			gammaABC[9] = 0xd9679cfa847f375e7ecffb06b165a50272521855e400687523701e837cdbcb0;
			gammaABC[10] = 0x18888b763779bb946262ce123a1608061ed12f03a818965e68913bc733403b0;
			gammaABC[11] = 0x20cb8373f3178a0ae0e2e294d4dc7b169847d5d1d982f68c96b447b73bb5cc25;
			gammaABC[12] = 0x2fabd12d3f3e9b09c71755f3f2169e884d44b917513bbacd5bd41cefcf3b4708;
			gammaABC[13] = 0x35e08d78a4bd494dc4f2bc930742d19a100219a34287e413ee8c502b0f2f2bd;
			gammaABC[14] = 0x17114ce2f25f759bd65a2cc67c6255b1a5ecf2e73fad0022532d25558f60b86a;
			gammaABC[15] = 0x1b4885a176dd719a259f7bd6e82e55325605ea1b469102549b2411e3c8d5e758;
			gammaABC[16] = 0x1de6dbd8961c1ba8b1d0297fefba18bc7da6a7f104430beb9d10c94f49990b4;
			gammaABC[17] = 0x1357944e9c0fc6da06184de3fb631e05c493a62ae8d2cbc159dc30a638cbdfd7;
			gammaABC[18] = 0xb7957fd315677357678d7266a0251993aeb80ffd2de7588462e3763ddd95f60;
			gammaABC[19] = 0x15c080bf0cd8a61ba768690e457b0be8ef27c5deeadf2bb8c8048f0bbddbe8a7;
			gammaABC[20] = 0x3351583b293bbe1fc09ed49858092b409b3cd7bbd5b343a9d8360294ba51dff;
			gammaABC[21] = 0x1135db1242111dd06ef1744ae3a474586ea58558d444df68f2e81c0b2ce39cc2;
			gammaABC[22] = 0xb9d5c33217e93bc8f1f3be41eabdbacc7b3dba64e9c5b480fdf348f60b19b4a;
			gammaABC[23] = 0x199acac75e643b55d0a4135a44280b89cb0bfdcab9691c8193f9c5c24bfffa77;
			gammaABC[24] = 0x313d7def37db3ca1efa71a4db17e9a5555f2f413e92ce653bc76d980a59ab13;
			gammaABC[25] = 0x3015dc3ddf1e6a37d7efb4aa57cca197b3d7dcc9abdd141167e7ce5c290e9ccf;
			gammaABC[26] = 0x1cbba9e6daab840f9d121ecb82caed35b8f2321e79b97d6f56e56e2b53645f78;
			gammaABC[27] = 0x2ed34969cfd426cc40362534bd850f2ab0519d8f8c8cf6ddc481b7ebbf0dfd6d;
			gammaABC[28] = 0x24e387f86ba0eabc349f46c9f06a606b72ee91b093b12a23aa14dcfc9f561db5;
			gammaABC[29] = 0x253571b3f1306a000187251f4030d72c575626c7eb96e061ff3003256c89e670;
			gammaABC[30] = 0x9bd6fea52e3952220c0e7d9139d19aa59366ce5cd2f9f03eb27c3a490dcf2e8;
			gammaABC[31] = 0x2e2e1e15a487f906715b14dfafddd6a3f54820fafb9fc95606ecf931adc387f8;
			gammaABC[32] = 0xab6a97cdb76d1e2f9c0ef23f01ad4e15d03b4bb8c0e1b9852625bb14f26ee14;
			gammaABC[33] = 0x22c17334153eadc2daace5b34ac352e44b0a76fd575beaaa444a28bf73d4e930;
			gammaABC[34] = 0x1f3d277b58a4f1ee9f392688ba7caca22ebe72dcf28c6cd97c94a111c31932e8;
			gammaABC[35] = 0x11630f3c00ccf86595b66284ff610c8e9a9205dcccf9d2ef6e4cbdea103f6308;
			gammaABC[36] = 0x3049527836de973dbef45c88df6242466787da569d18b1cfd48414da71c1ce;
			gammaABC[37] = 0x18db4dbf6bfba956484b7d24d39124e207b435d77df70296a7aa477b6ff9e8f9;
			gammaABC[38] = 0x8bdee0a779dd14967c4e515c4a160045555c8e0b383e4773a06a5d08537b1eb;
			gammaABC[39] = 0x270304ddb3fc7b5dbe4933224adeebecc7db437e39ce8388b0e18d69481fc20;
			gammaABC[40] = 0x10e490b445f6a8755bb2f64b24c2d13c9ebd5e3fec45166fd13046f1555b71c8;
			gammaABC[41] = 0x1c4b86e2d9ede87fed78efe1051ef95fda8bfe7a8455cf3af4157d3cdcc9f473;
			gammaABC[42] = 0xce09b7f90502f165b2999c4266370dbe77263d4646372b5b39312ac6b52fcdf;
			gammaABC[43] = 0x120a288c7faefb3229ae43fba95a92d08299da660fa2aa0f5328243fb2903f49;
			gammaABC[44] = 0x1b80c455e7e34753e01c2e43e4063ff02b51f3add18407fb214359d750577c47;
			gammaABC[45] = 0x100687c0880c21fc8d1155581f832a0d7e67ab919c27daedd3be33aaaafc8726;
			gammaABC[46] = 0xe05721de0979500a0f9c734c85752b93e8283cb90facf86086797e2e4b2ebb;
			gammaABC[47] = 0x24505b4ef1ccf811c9d7c3b34034b7089063b78c4208eac6f65ae6323ed484ad;
			gammaABC[48] = 0x1bf3d8299ddf373fe6f8b87be6b4710ac9ac8e6412631130b79eb56f6eab15ee;
			gammaABC[49] = 0x276c6ab5f55ea08e8f413d58f0f566d31fc86fd6e1e2a261d8955ff58d0a4360;
			gammaABC[50] = 0x25ad07cf0f1e2cba56e23c10ff82b75191cfdc20328cf6b7cb0dee429fc261eb;
			gammaABC[51] = 0xfbcc1c3b2beea27fe385d54f15dcb0969ca7e2c72e29ce4d3f6244f8423e779;
			gammaABC[52] = 0x121a7e2b9081e9803473132b12496add343540a1e3a9e5411d682cd1175d32f8;
			gammaABC[53] = 0x18ad41cdc2298dd5afa227ab4332a795600921dacce4a704387b401f5ac40023;
			gammaABC[54] = 0x24356fc21b1002ea9270d8178d30b008119bf23351e009bc1fec070505bab89;
			gammaABC[55] = 0x160d124cd16a4b953e24b76e882c9f5d4f677b2a21896969fd8719726477f744;
			gammaABC[56] = 0x1fc2bca610de05f0164a335ce50fa1720244a1fad959ad823f480f494972d743;
			gammaABC[57] = 0x1fd76151d34d9c53b3500ecea1ae1c424e46caf0589ee6becfe6365749dbc32a;
			gammaABC[58] = 0x2d642cbe821aef3aa98bd8f554e10a3bfe096d8643bcfe2ce2ded57ea7bb7089;
			gammaABC[59] = 0xba92b9966f6ffa0d72b2c71c2e4094fb9f8419a972349ca97f6e8a0b380ec0d;
			gammaABC[60] = 0x97e4d1bc1c5d3f9996a85958f8eb183f8104e1ef6901ab037861a49c84be312;
			gammaABC[61] = 0x1375b80d535bbdcff79ad5539719f0637e662db7ca4a5cb3ea2a50a9cc32865e;
			gammaABC[62] = 0x4d6659f83967bfccf5f9ac78a6cbea8c90eccf1d2da9ac5dca0da0684f19ff5;
			gammaABC[63] = 0x163a5c44053dc382b916101089e1ad3c4274b581fc760e4b955c6e5f0f7cf5be;
			gammaABC[64] = 0x225024b43d9b291df74dfba495c28417dc3e5e47452a570dd6a831af5c54e1a4;
			gammaABC[65] = 0x5a9fd03c59027de8400faf20b353943db48dc87dc2f2b317ac858efc668c684;
			gammaABC[66] = 0x277d3b19e68f0c8201ea8749c0cff00e521df7379fad6c550b05c037682131dd;
			gammaABC[67] = 0x2004e48855701251320cde179f582d29a13b7768ce61d371c79e41b48589f4d2;
			gammaABC[68] = 0x271ff569150f47c0ea429d11e3a306f9f97c2cf5ad89fbd85618f84e48b8e879;
			gammaABC[69] = 0x2eb399ca5ce6a60ccc3bdf9046d4bfdd1843c044d8c94cb5354d78581cdf602a;
			gammaABC[70] = 0x245ba800cd017688c0a01c61f0ecc728c4ad7bf551b76406f8b771c149ec98b4;
			gammaABC[71] = 0x164fba0d89604ebe35caecfbdf5fb7802b30951c6800be3c7b68290ef73a17d5;
			gammaABC[72] = 0x2ce0f729657af9ffaf6ec7ab7397a2167c0640ef90a167c004d2580cdc98de81;
			gammaABC[73] = 0x22e5dba8e147c086f05391effc4b724b0fa378c853cbc776c1013af7ba21c614;
			gammaABC[74] = 0x2d07befbfdd709cf0aef232e2e53b51bab1c49dabdaf11bf80e24397a3ef7857;
			gammaABC[75] = 0x23b29b1c651e261e7631434c8052e4aed417972a7ab3763d285664194d5fce47;
			gammaABC[76] = 0xb1a25d96f2b5037b59f02facf8a45ecae4c061e7571103ca9810afe87878b56;
			gammaABC[77] = 0x6cb183bc36812c2273750e38ee5f4cac85ab25388b377c4f840fb21d02fafff;
			gammaABC[78] = 0x247a38648fdfc12bd6911a2676837c5aa132e81e17efae4bf4b5c330bbc3063;
			gammaABC[79] = 0xf48121adfd2bd18949613f84c549ffb82d5db8d46f040b134cccc16051e3b99;
			gammaABC[80] = 0x1907e458b8ec4b1ecd1864e212ee66115b93c972a6bbdacabe99b73041ce5d1a;
			gammaABC[81] = 0x283eeb7933f5d41fc23c141aefc09e8abf1ee3de6775aa143017367e8024a838;
			gammaABC[82] = 0x25d343ca03f254331db1747dc27291cb2952841f39d1c9aff86d017f02b33495;
			gammaABC[83] = 0x23945b16c9536b0bff2d78bd6d1e88b9a73255ea4ec8ba52a41dfc1224fc8df;
			gammaABC[84] = 0x2be58a6561820d30245d80a9b8ef0f87c2790ec479e68f4653160222aad757ba;
			gammaABC[85] = 0x1d1336d8410d90a8b109c1545266cbbb10bf08b76544e4fbc6151d5601d346b8;
			gammaABC[86] = 0x2c063f37715008ea213c9379a180fe0294316c99f6c259545a128fde61289225;
			gammaABC[87] = 0xf25870fc43ee7cc25f0ee27eca68ce0eef612ac2b6964d2badc5de25ff66eff;
			gammaABC[88] = 0x2433ffaa4421800289639bc1241aab78b2b0a983c506f88f7e62be03c8203d82;
			gammaABC[89] = 0xf80b7c0016dce6289333b5237cf64ebbbd2e91bbb9b1acb07a8afb8e20c0b00;
			gammaABC[90] = 0xf9d7d7b596a228b277dbc2cf6589933bff6c34fc8c6ba3d62b548eda98c8a3c;
			gammaABC[91] = 0x5a738ceb6089f3097e54f8aceb896735eea2c30b3c2f419575e2d78e99c0d80;
			gammaABC[92] = 0x1dd1bb33c7994feacafca3e953ee221e1b2d35fab5727f6d47621f411ca57fb1;
			gammaABC[93] = 0x22c35774472c0dc048f4f5e0063319b8f211e10a67b753a24cefe4d612e9803c;
			gammaABC[94] = 0x2385867cc56cd42a141cccd40c6595fe764bef4e0a58fa1e9c7eaeff265ca6cd;
			gammaABC[95] = 0x2906692d85ce8e20b1548c04e1bb3873ef79b4b944f97d50a7038b0fcceb0c79;
			gammaABC[96] = 0x128cad3770004d3a17d7d2db7cd7f7b4506f31e7c7df90a711788cac50e887c6;
			gammaABC[97] = 0x8d13592a005843ce071fa45f7de9a1cc7e5c14659cf2e8f9e00a5f5c66c3ca4;
			gammaABC[98] = 0xb6fa015b2a0da44d3dd871ab0ab9902b6d3a8986f44ce0cd482e49a84f64941;
			gammaABC[99] = 0x3b4c8945618e65095f0beb10c0e5c56c8eb5d75c5983939ed2d60402ed10b89;
			gammaABC[100] = 0x252f1ef3ff7e4da2d6a1c44a71f3fac86508657aa807f02b08314695906d6087;
			gammaABC[101] = 0x6dc4e1062c239bef347fdffe8983784dfc84131c47b4a9e535467f395d6f8d0;
			gammaABC[102] = 0x1aa18c1c3a826f5254aba05e8005937dff1f0db71900996645df79385dd306d5;
			gammaABC[103] = 0xadf265180381d9946e4ff768f254544caa43c1d46eb681722672dbf2127f6a5;
			gammaABC[104] = 0x2282b2f1427ba2685909f5c1952b2ef1c750543f209124add952b3524bd78bc3;
			gammaABC[105] = 0x2bcd85d328521f7cbbfad793b3de1e576bb3eb95062d235a014265f2a1dca35e;
			gammaABC[106] = 0x20ee7729d868111059815c25a195cc06f24a1d048ca7b2540af9531bf8ca053c;
			gammaABC[107] = 0xc85204d4981178f50f19a6b6cdb529a0e3b5a87b74786e2754928e912631c42;
			gammaABC[108] = 0x35a5c7c437fbd5ec304eeddb2f8ca9500baa1e492d17eeb02eb144d98862b40;
			gammaABC[109] = 0x30562be7124eec8d268ba4ae7bd2e3ad2870e73c022d7d55fcb6a9ca9fef6a68;
			gammaABC[110] = 0xe228cf7eef772d8fe5a1f8ec9fa7383576b40c55aae8f2b5c6f87c9687a4bef;
			gammaABC[111] = 0x29d588e041454f184d16f8f45b52e3b03aac92fb51295c350ebcd682d576fc69;
			gammaABC[112] = 0x15972109ffd599d08ddb528ac2562fc5d0b5a7b414f009c2a8bcafcc8f1f38db;
			gammaABC[113] = 0x1d504175e6878a2527d9a5d8258a28353404fa5bdc2f184287f33e2844e1c756;
			gammaABC[114] = 0x1b5f4887a85c646298c013f2a5240331ce5b3bd173d7b0682abccb3d46d2f45b;
			gammaABC[115] = 0x2f9b61109f1b2fbb1db3ecf52adcdd4e5f762236399296a866b4e16069cfe3dc;
			gammaABC[116] = 0x1633c9f618534f793853eeee4fd14080a0f90a77751edb30769c83bc8f96374d;
			gammaABC[117] = 0x11154f61d0c471d5f3b1c63a272840b341eff19a47c27000e5f7eff27bc7f24f;
			gammaABC[118] = 0xeb3c65cdb11b15d6d6ed00d68a5ad91ca9d24554a15fd1a7f9f1260e443935e;
			gammaABC[119] = 0x2b6d3dda570cf1e2c4851a76eef4b6541ca4e843294c6ad8b9903ddc72d0d7ab;
			gammaABC[120] = 0x1b72f36bf92817fa2b3aa96dba383cbea07e07899755067a6116f045d83e4997;
			gammaABC[121] = 0x2c3e138d132037d26c0cdeacacec3a364d0fa4a632d0bbf0c0a71498d11f514d;
			gammaABC[122] = 0xeb160e9745befeec6ba755546a4ae9187e3ad00efe968c6f0ad31ebf3a294ca;
			gammaABC[123] = 0x27b9805372c2b6b527de7ee35b1aefe03fb4b749ebafe69c0858e6229ccdcc85;
			gammaABC[124] = 0x71c6229faafc4535ef5fd6cbdb2261ae34536e8088e692270a4d4ff0aa709bb;
			gammaABC[125] = 0x2e1b87d5a588e279b59d08c0f7f0d898e86f335e540de8c2d1819d83b6260851;
			gammaABC[126] = 0x187b1ac78e34744815d787ba191bdb492def2bfb3529723b0d88fc2268c0e5ab;
			gammaABC[127] = 0x2cb41e390d6a8f9e2e137c89791e3a69beb9377a1fd3353ca4ec33a5de6d8fcd;
			gammaABC[128] = 0x172c3232bff3b4c98b2cfe360fc02bed4de629f387ae8dbfd6c0189b0ed2b304;
			gammaABC[129] = 0x5e5036f34ada4193d7b1931ba05bf8b6e4c303603d70ae1370d8acb9481b6a4;
			gammaABC[130] = 0x2f3482c281a79b850a42b71a05d5b5e71c6907e8dcd2a79824df41822da755ab;
			gammaABC[131] = 0x27fc8cc339bcbf49ad44aec7841aa73123a5aec02790068647ce0860e40e6921;
			gammaABC[132] = 0x266ad24a7d3dccb6578bf2b5c8483747f713f99b630d2dafc9d07c02afc86aea;
			gammaABC[133] = 0x1c62507099048f787fe8f5291e5a01bf0043fa3caddc377965108cfec6abafb4;
			gammaABC[134] = 0x12f2acec44913b2f70f32ce68b1f8bcf7eab9a5a5986126a5247c814d7f5854;
			gammaABC[135] = 0x1913f0a121466730ac326c40be0d208f7b90b7e64110f92a31ea95e0e2dc151;
			gammaABC[136] = 0xbe2ab159710d0612a78bb0c6eabf3b153a7829069db6dda142852a31f081643;
			gammaABC[137] = 0x65ab05d8589ab45cf052714aa9fc0800dcf7bd2508c7247a6a4f11f8a35ce3c;
			gammaABC[138] = 0x23815cc195c50ab6188118198a96d288ad5a0e297aee521c7c892b916d0d73ca;
			gammaABC[139] = 0x2d1b7ad3756c1cf573143f58d8bb68217cc1e554cd3e329d2f09d9aa7d7aeab3;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    