// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
library VerifierFinalize2
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
    
        function VerifyFinalize2 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x215076d2e708369bdaa2c2af968b7b709bb0c69ae10b28dfd67452301b7ef7ed,0x132dad716295d4e7454bd7fb04c3d1f8178f495c519c1184bbbffa6a4819a3a4,0x38f090e61c63b0929e831e57d3f7a3b78fec2e5b83c280048a90c7036b1aff8,0x2026ce630a7e45cf048843cea842001cd8a8b8fb8bdaae36869f2bcce9f83ea6,0x5bde01ab2cd55eb20c2e8947b1b10b1b61a0cabd65ec29dd0a3432324055c8b,0x8789cf98aff3c943b0ef414b975f8d8170150556f8b42170d62b39613e3c81f,0x2c49ea75815ca58b8773502ff88934a42fbe05e87ffe162617243a3f97bfcd51,0x13bc760af381ccb4399b7ff6e77c14f543bd200218582f282d5f380fd05fd9a5,0x139174e39372c4f635693cfa007a051fb04d61b9a74e26614974361e1bc24c02,0x2ce5118ed42209c7f68f806f23465ca4f9729a68fb12c2a7960327a14bf56244,0x1d7cdf2f9a3875ea4028098d8b36b671760881d7528b68f08bfe326ffef3a90d,0xb21f9f13a63004513f64e8d0e58fe08624e65d28c9c5d0b09ee6e060c8ff283,0x2cd2c23684428720592773db3d96631b7854b5d237562d5eb2b07f7552d0a3a3,0x49957ec7300aa3e4b7734225d3669885c35342bd8a1f93e79b0fd65ca947a51];
    
            uint256[] memory gammaABC = new uint[](40);
    
    
			gammaABC[0] = 0x1c407e2a99ddad921f237ae48314ce95cf207b227df4f23f5391c039dd73485a;
			gammaABC[1] = 0xf22cba927e8728b99cba4a71c25b387fb1267b1ccb7ceb973b27372a02d1db0;
			gammaABC[2] = 0x2b6d81e5941e282054dc1dc95b626537deddf188a718ff0288aacb46ee02ca22;
			gammaABC[3] = 0x2c794285314e032b42917bdbed0881451ad009e6461835cb5dee6a3848a5ea24;
			gammaABC[4] = 0x2cfccf829d383c21ca5b5853f8895e96510096547194030d9d9ad7c6fd794c77;
			gammaABC[5] = 0x2fa61e60d578376c5c142e1647d8de5a279f903faf73e920006cb4705ee1efd5;
			gammaABC[6] = 0x85f08094f8b42d5ae33ffdf561455b8cc0fd7c8c0eaae7cc3a894a45634d175;
			gammaABC[7] = 0x1957f9ddac519155e782db53ee69c8f55943d8e3240a807e7ac25303156ffa77;
			gammaABC[8] = 0x2e1e2b8c29839a9ae97d0e9a45d15eb6bc6330b1e4d7fe801f2fb97321bbf849;
			gammaABC[9] = 0x22a6b57a057754c098f8c1a5bcc17c95135d4b091bbf172f2b1277003dbfe514;
			gammaABC[10] = 0x90401337f319ab52710ac2310ab668458608274b731ffba2d2c0fdce3acfed;
			gammaABC[11] = 0x2260bf09acedb96f726cbc88c0a100370b6a2df7d2d4674dc9877c91aa341e16;
			gammaABC[12] = 0x18de75750642f65a83d29de409af7cb8ab7339776cea395a7e009a24fb8951a7;
			gammaABC[13] = 0x187ba72b55b620209dd794144e1863f5fdf81885d64a64727f0b1bf94f32f28d;
			gammaABC[14] = 0x156e3755b01870e235b9328b3326c61e6cd5c68aeec48efaec608c1fa935acde;
			gammaABC[15] = 0x264c073e2f446616d27a7e7d391922186ccf6e9f24f0c440ffaae3be26789122;
			gammaABC[16] = 0xa3ba7774cb1da021fd94195d83b8df6249a424140e2720749940ac94b23de5f;
			gammaABC[17] = 0x12bd353a73277c26923a6720ac64cc7a106a184e5e9a53c30d720ae9aff2bd13;
			gammaABC[18] = 0x2c954fcd9dff1be477e6325bc90209334ca802825dceec8610f783edd587cd23;
			gammaABC[19] = 0x245f32eca8b1a7236d8b9f6f4c0786bee2db58ff7f82f091dfbb905ac3987d7a;
			gammaABC[20] = 0x91ce6b658ab64542f51717055debb428b5a79edb2e78d8df9a7aa4278ae372c;
			gammaABC[21] = 0x10eff38bebedfd496aaddd62ee9e9b757ac893f92683de6018b10dfd837c8218;
			gammaABC[22] = 0xbf1295be266b5ef4d94a8fed509717c23f4b1b6fe30a403885a6305060aa6f3;
			gammaABC[23] = 0x2760260606502e6ca60f83f958eb5304d67ef1869e350f605beb8bcef41a4da;
			gammaABC[24] = 0x18c8418a09c57135afc01c5c82042efa75d6f1c283b03db727c0a4fe4623d3f1;
			gammaABC[25] = 0x18238dc0f7051b6773583ba7559c23bc337d805e1e0ef3f1d5982f8bb6fdafe8;
			gammaABC[26] = 0xf37c8d343add3e751347a57ba22c6d000fe62b7c4180ce649c0541ca0247288;
			gammaABC[27] = 0x130465df3d3f095211c783af9af2a0b0e33e06ecc8b7cd968223b5d7849a9f2c;
			gammaABC[28] = 0xa8edc0d7a9e854cd103bde504c8cebc4432a71c87130bf399b20b55b4ca45e2;
			gammaABC[29] = 0x224b90e9a7116e329352bb9bbe06824a9b6a7d8eddcbe4afbb05086f6281af85;
			gammaABC[30] = 0x28ebde7fd31bbed462b65d628fef087c27213da835da18e3465402a85cc90163;
			gammaABC[31] = 0x8bbfc6cbd2bdedd181869e68b87740ba7ea9e9f7170455e5b4404c010443cfe;
			gammaABC[32] = 0xe216007c31c4dcff3d2ba63db6510a0147dcff40efc256b4352b3a3bda18aaa;
			gammaABC[33] = 0xcd0f254aedc65b155a4164dea714d3109d5ef64d8ad9829d57c2aaa5acb8b99;
			gammaABC[34] = 0x23670c91329b5a0b6bf87da5aa8a8bcc86cd1c35b2e53306360fde28ba1beea1;
			gammaABC[35] = 0x2ea43047340a03401a8cd52562e705d57762863065193f9aa30e5010558ac82e;
			gammaABC[36] = 0x2a49a6ff71a447dcdf2aaa8e056377690af0b78fad6d364485e099dbfe08b172;
			gammaABC[37] = 0x135cfdf8274baf49f769658ab06bfe0bc9aa18bad1d55254611abcf0c6965d89;
			gammaABC[38] = 0x21d7839b82e5399202b96441cb8c912c478d3321a6e3c8e08d4cec8cc4c87e47;
			gammaABC[39] = 0x2fdab2ad2dc14fac2e4d22d14d53c87dc274d0785bbfb5913e071fbcea253af9;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierFinalize4
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
    
        function VerifyFinalize4 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x1031e073020d8e9b86ef0bd42acc1e7ff1bbaf07c68eefda394184767325413a,0x1b72b667a7fd78b309c780cb9e6a3d513a57e100832340251083723dfbdf81c2,0x1184fe72f7fd26458d675003617fd1392c565a0233bd5f958dd4b7c61b1225cc,0x496b5751b1f70bc55e3ddb75a6d319cb930b09ef9884a27c21b71740dcfcbb1,0x1fd15d303d50353d487dc1f7a34db310e3ddc968331c612321045046e4541894,0x2af64960bc90b1759fd81e2d09ce41f178314dbb29b0af000abe017a113e7eef,0x187121f0e373c337e6fcdd058c4487c5cde928b753affd8d7e1629e30688921d,0x4338510eb1e2afa89423fb84e49b820fb6625d4cb63a374d514b2afb4d3bbc1,0x710479b00c8b3b79d1dc72b5629d21edcb115bd77a7f82cd3b6b59b1a314b54,0x88da4776be54522db95976e87a1ac1e1b93fb33ae7fb8c5684bf8aa470064dc,0x2011726e820ffe46213819c3110dc2fc5a94a0d420d6065b99e97c9c2d8a44d6,0x702953341b8225fa194addd62f9408c916da01e9e4473b6c66b530bf2af3c43,0xa511e01b4d88bfe94ea1e5e712b4ac2421169c305485c932a213e4a24756275,0x1a18e7c39cac80c4c73f10c40560ad4fba069b9904f384afcd0f8f3db07401e4];
    
            uint256[] memory gammaABC = new uint[](76);
    
    
			gammaABC[0] = 0x2222a6685838bd6acf848883e2775d9b8e07b9886377a564f8801f8f314ea59e;
			gammaABC[1] = 0x2cf91b7b0312031d44099e99fbebfbc514078d7e978c7572f84889cde6966d70;
			gammaABC[2] = 0x166078265f0b1daf0988b2fb213ca1335224890f88eaf1637c3d756b0ff9854b;
			gammaABC[3] = 0x10c31f2b267c8de72eebaeca3ab8921a29c15d46abc56417b08ea59f042ccba1;
			gammaABC[4] = 0x20dc4102aead1a483ab5f0c1c638667885da03470611dab3714d3819af7536cf;
			gammaABC[5] = 0x28fa88889bd38aee17e894df8b3853696f6f6e218ed2a0cf20dc16b4141c240f;
			gammaABC[6] = 0x1fe950c2b180b0f1b748c4ffc78cbe616ffbf5958a518248bdec07cd16a7ec30;
			gammaABC[7] = 0x1a761c68c4f6218fdf0a8714267fc5fe1e123b3a3cc2c678bdd566e821f39807;
			gammaABC[8] = 0x18bb4eb39c3393ae080d107d48aba840a3114179e3a40ad765abed1c612ebd1e;
			gammaABC[9] = 0x841fdb12e02d331bb7458b9fb4db0938d34b8e33c514562fffcdd39d2a6fad9;
			gammaABC[10] = 0x58201e9183242a95e95e1aa4eb158dc770ae6bc33fd06e5828a1ed327acce9c;
			gammaABC[11] = 0x2e21d38799b7c9afdc5d42db78886e2d74f4139bdf1b1dbd3a29065f2aa28687;
			gammaABC[12] = 0x249e349e114f6b30bbf3f5d985e7258cf15fad93251377832c3e31f7f0169c5f;
			gammaABC[13] = 0x18d12ed25eeb4d5d2f10235c9620cb7162345b967252c065e904f8fa8669344b;
			gammaABC[14] = 0x212ad5efc00ff792c5f1dcebfdb674c3fea09cb1329e8748a0d79950a4fb7f69;
			gammaABC[15] = 0x2480e4c88da3ebba14fcf7772da6c3a6bdc06a1dc141e3edfa9e2f6b19e8fddd;
			gammaABC[16] = 0xd1e0df9f083238c6865de49e747676270219b217faf14adfeb6c12ec3c16144;
			gammaABC[17] = 0x10289011abb40c5985eec8210107b1d0c1744616371d443edc3693ce4dfe06e0;
			gammaABC[18] = 0x2570560862cf7988bfc5176ad0223bbf28c50923a5b7adbdc584fdb5a4bd2ca2;
			gammaABC[19] = 0xfaa64f33332bb24d2131979af99326c773da4b7e7aead95f392ba208931c333;
			gammaABC[20] = 0x161f0f4ebba4cf6fc74c6ac6a1f2df1e557c6815adceb992bc6a822de54b5f69;
			gammaABC[21] = 0x1498683f3dc945d50abc9b89a33fb8959b1bd2389f029528ea67ff1a5d76e00;
			gammaABC[22] = 0x103520ba2f3cdd2e47fc5fe59cc74efeccb8dc508cd6c00d02039f3dfdad16b3;
			gammaABC[23] = 0xbaf57cabf6c8046eb5ef675bc2eefe3868d5c598e03cadf3d3e3f2bae3638e2;
			gammaABC[24] = 0x29458e8d8854498bf3e755829cdab80fae2b3fa24192727337b2c71a4bbbe4f;
			gammaABC[25] = 0x1ce884605d7af18d2f3be6e456da950eaf18d4890e2f7e0356be2f9c1658aa6c;
			gammaABC[26] = 0x1875d73a4efe92a9fd760dca71a24f66ffe1dc25729ca8b566b8f1a0b1cba098;
			gammaABC[27] = 0x248557106475707620a5508fbc77d9dbf06d39ecbf2fcb737baf3e3c5e0414cc;
			gammaABC[28] = 0xca47a2daa71c40e44af04a94134236a475526502e5bcc1c6b2120ffeccfc472;
			gammaABC[29] = 0xa898e02d51dbcfad5cb1d3eed8c0ca8362a4ce82f47bb22e79e7b4f40bb2174;
			gammaABC[30] = 0x2a6365a230fb54ae414589af995957f3aeb2e3e78818ed3e2ff4c90e92f59446;
			gammaABC[31] = 0xb6e44b2bac33627cb3a75f025ce7b46e41b1e060e2366fb6d0d897fefd43bd8;
			gammaABC[32] = 0xede10b7906d1f88039b9f49303fd7dbce0bb7761f478c3d65281163d559c8e7;
			gammaABC[33] = 0x23d19f702c0c32571a1bea79ee5af3aa1279ce169daadd446697740df467c2aa;
			gammaABC[34] = 0x282a00e15e6dd83c06055a9eec8cff0cc405cfa52477d318a2b71b8aab70834e;
			gammaABC[35] = 0xcf0bf89341a4c0ade1743c20006d6a7809154ae4499dba71c63bb4ac7a3fbe6;
			gammaABC[36] = 0xf846b91f6804aad8af65789306bd1661ba806aa9b7b0dcca535df276173f8d8;
			gammaABC[37] = 0x2474ec83d9a6507df32048e3f8d620dcde862a52af6e850583c10bb0e4793f48;
			gammaABC[38] = 0x2353aa6f5310c78254e9f3a6ddf9969e2d6b6add8c07fb2f0b88055b1fb6b132;
			gammaABC[39] = 0x57339e3699d0dbdc54933294352901a2144f10bd44eb90201a167a95ebebdf1;
			gammaABC[40] = 0xd284dd5a1c3ad7316d0784a588b7830185a3522e28039a83a2da7a1d0221ab4;
			gammaABC[41] = 0x630200714228d4b50c011ab8645e9f9150d597f63a15b7bf7e7586542cdd040;
			gammaABC[42] = 0x1997163433f0f5672c223726da8c37fc473a30db3fd90deb725cdc5e346c1df0;
			gammaABC[43] = 0xf1a63db1ca082a183bc6117d6b8458d9b21e1de34e700221e11248e8b265fab;
			gammaABC[44] = 0x2d2291acc15e61b00cf4f21b650a20708d658d62b5f77238f7f871c0b9ebde18;
			gammaABC[45] = 0x2270bbe196d11102611d24c9684a114383ba76156d4930cf2e6dcec414232182;
			gammaABC[46] = 0x2cebcbf3450442b785161a86d0e0b5659df6f904ee4e8c6e06f4454e276e812d;
			gammaABC[47] = 0x115818f9ae316990a6fcf8419f0a6f84bd3eaa8bcf2d0519581238d51bbd8700;
			gammaABC[48] = 0x155fcecee1c486d474fb429f5e40d0acd4d1b0f2c1426911898b3192e700b49d;
			gammaABC[49] = 0x115183257f46cd3f1a0459b4518e186e61fd4be5df1bf25cc33d988b3614df95;
			gammaABC[50] = 0x2f73202049638eb58dd9e26863e85665342079109acb4fe0034a64de84f2802d;
			gammaABC[51] = 0xcb475e89e66f474d07168feb7ce06ab226cee7afb7b23d216b678f0b750f4eb;
			gammaABC[52] = 0xbedecf0358895fce4c9ee06ea73bd3e526ab1ac82ad2925c92b9b4d6d1d9bee;
			gammaABC[53] = 0x14a0bca49496dc938ffa6bb45cc506c5243f57f70be6db650c1b56a53cc2aff;
			gammaABC[54] = 0xf33e1336a6700ff89ef07925aac14f535861a7561610a87d6757df86c8fb563;
			gammaABC[55] = 0x7468a8cadaec0357ab6962873373601c6e940568a7060c4d5555f0f1325c5d5;
			gammaABC[56] = 0x289927525eef1d9657c6cff1b98241e13990e3597ff5f59efb6806a5ef7eb5c8;
			gammaABC[57] = 0x1e11cbc567e2a6ef767028e7f5ee863d5536414463181ea1af1b5e337b0c23c5;
			gammaABC[58] = 0x3ab496de450a1c03d428ff67559ce4c475e043842e4769c5d19e3e0ef229a91;
			gammaABC[59] = 0xe755c8e4a044d9f52f9a8bdd01e5e91475944216a932c22fb4eaa2e082423f3;
			gammaABC[60] = 0x85769d330b8c85aff075316c1360eda0bdbc6949a99935264e8f3de98398978;
			gammaABC[61] = 0x28eb571190f7072333db3e150934ce3f087d637c48f02db0668e5456c5559449;
			gammaABC[62] = 0x15161ecae7f32d3cf5f29f8f4fb8f939e5287ee21baf5ae339509a6f53c5128d;
			gammaABC[63] = 0x2ec94501d6262362e5fc222c7693b160d979b5d1e218d8fd9c7d9d74ff5aad41;
			gammaABC[64] = 0x1601d88760ce80051a0ec92e6ff0b9e9d125d14e2f448d18a7fdf67bf08155b5;
			gammaABC[65] = 0x1db9f51c2d075028da8152586c7cd1fcef53087c54c48a6098b456730b483e53;
			gammaABC[66] = 0xa34f926616bc83403937a3a23c615ae35af58ca6c47c26fbec25537b45a281e;
			gammaABC[67] = 0x76639d50011df339b7fbbcea42e7abdf8b35a0d0834a6fd4f355de41dd3a3e5;
			gammaABC[68] = 0x11be2613e04fb364ade492b901c210dd28dec9ade9a6918f71d956ac85f0bc01;
			gammaABC[69] = 0x2725ac40a4cc9a278399b3daf888c1b8a203e5af8e06c5fae7384f21aaca96e5;
			gammaABC[70] = 0x98d772a3271ec18238b3b1f3965954a89e1304acd6cffcfbbb937b5eac4c3a;
			gammaABC[71] = 0x2aaef1cc0108ead3bd86503c536325ebf9d3773248101ffbcaaba5bf8db11434;
			gammaABC[72] = 0x25d1688a029cdc252a3025c3355fdc99dd763ff8d875ea4c623e78c963750671;
			gammaABC[73] = 0x2b18602f6daa00311a9b3d8294f573abfd766a3e4952ee0adda0d21e7e292ffd;
			gammaABC[74] = 0x2939574aa6e2aa4deaf8d043a66507ca369516494f097bc425c13d55cb355070;
			gammaABC[75] = 0x2f25cf8fd04bfd78b287a00dc3d57450a13e805150c8ea8ed2922dfead9f4d6e;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierFinalize8
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
    
        function VerifyFinalize8 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x10f6f8f6f0a63e8e3c836576d6cea12d9b193ade5be44362b2bedf1e231f8c30,0x24347b931e8a00f7a8dc0bff5965c535130f898d8d2c1547c8b5f7c377194b34,0x16a7f1412d8ce2a931c43ee3fe3c2def260ea94b1aa956847b68a077f8ebbbb6,0xb649632012fc5ecd967de432bf7e69d52366780f711aa6e0cd84a85c4669973,0x20b961ef1bdb54f2602ed33ce881da5936b540e843b558ac27af40bf59684d61,0x2b1728e5e19742ed3d289549bf3199b88ceafd7c2203b19f1416b10615b023c0,0x23a3f8d506794cea344e528a1b7fc9f979428b6be17ddc0ac4dbdef9cc57e74e,0x27b281c7707aeb3675a72a69e03ad12d04fdede75050b5ed0c8446b94b45a992,0x26ae8a2e5dde3c3d97d278b17dcc00c013c54b0145845bddd0969b1ce95c9f08,0x24d281fee47cf31bcd3bb64d4a0e792bf7438436ee048dbbe64f11c5ab493e45,0x2672f0f89d75ae42b48f2569be9fea8398ba2af9f88a416f306e853c747fd9dc,0x111d22f7305186230b530536be1c1ca54b4672c328a865fe8a57c362f728fcbf,0x218cb89f1a054f73e0577ef0ce6cdab56775c435de1b6cb5320017a473b8e00b,0x1a95b1a0d879cc4efe890879c7153fd915ba914c5e508b9f394610261c696cb9];
    
            uint256[] memory gammaABC = new uint[](148);
    
    
			gammaABC[0] = 0xf9df67e36ef4d0e8d2f3e0758de87fb12183571b282da24fb60cdbd1289a26c;
			gammaABC[1] = 0x114a6f5eccc06aaab9ca34b2f0829a937231e3a13c7e2555614d4a2b5298e53a;
			gammaABC[2] = 0x1cd536c8e04f3a2d98fc5f93587503d31ff81ace1e932b9758570421412a3095;
			gammaABC[3] = 0x28ad1886bc7002dd53106a23dc05dd155c63bcdf709c158ab642ac521703c45a;
			gammaABC[4] = 0x2f13b5e279480419ad53f7cef2b7c00037acfa1e8b201c29b72a6ade55022d7b;
			gammaABC[5] = 0x2b40b0f57637b0e652790e244aa35eeebb1285e6c2d90dfe11a3fd7922f9021b;
			gammaABC[6] = 0x2b645483d7e86e2cb5113daff754d0b075ba79d94aabd19f697452ada62c809;
			gammaABC[7] = 0xcf99f69b79727d0faf4e3e80290ac1d18491331056bdb57f2feb8e0b46814fe;
			gammaABC[8] = 0x2ee15508960846b4e4715a0ed8263c11363c752b8cf9bdc4936a99c6ba739bb3;
			gammaABC[9] = 0x110db25eaeb1556e9ae5614f23be17161203b1da6143e27b5e0b3a381b8d72f8;
			gammaABC[10] = 0x13c13c8a227f2678a7740f5ecee36746783bcbd9d3c847380e1e67a384d1fdf0;
			gammaABC[11] = 0x2ef5a27c17ddab3ec819b9711618147ef6417a27f55e4c342e2add86e8f9c64b;
			gammaABC[12] = 0x257ce0ffdea64d54ba9aaefac2526961b74549557c9db0b333f49579ca6ef8d6;
			gammaABC[13] = 0x2bbba7ae6d0048771050148861fbf0571a9581277ec774bc14044764b26a694c;
			gammaABC[14] = 0x21ccfd5efefd679d53103e9e6ea214761a75d991760503945905ebe1442270bd;
			gammaABC[15] = 0x9e5034cbe6259c57c5ed7f6124b3d6329e7cd5f2cca268124b4a0b641226bbb;
			gammaABC[16] = 0x2328b3a2c91cb0bec0be2971f9155a515820be71ee5419c12566215d3edad57c;
			gammaABC[17] = 0x3cc0785fdbae7d736d6c971ace636e128fdba73fec165e30c7dff7d36ab022c;
			gammaABC[18] = 0x4a0613739f17b5b3a390e9845c7e3f4a5ddde84305f18fde0de91345f212108;
			gammaABC[19] = 0x59fce1c5b98da89a78a9719df772e7438e8d5e4f83d0c208e34b34c44ed5d09;
			gammaABC[20] = 0x8623e956a7bc86d79839c44656bea9fc57d49553bd97ee5198867bcaf7aa34e;
			gammaABC[21] = 0x1bc1b23e756b9bcd418c8b31d0758e086e85bf67ff038a36b85a236f4dc4256b;
			gammaABC[22] = 0x29c6f037be5fd0fd670e02747c0b99f3c01e624a145c5cc616c7ca0349df60c2;
			gammaABC[23] = 0x1f2758c642ed6c5a14e21a7ced7ea7d8e85dc4d0c8cfd2df59eebb20c985c;
			gammaABC[24] = 0x2b25df7f3c406425edd11c6d4e01684b60799caa95d43d1cdf2174a6021784b1;
			gammaABC[25] = 0xfcd2a5784de4f0a04bf3d2ec0327b7fb7b3b7d5ad6c40c25e8f75f07616d7a0;
			gammaABC[26] = 0x105120bcbbec430c86a1292b42c4c5f1eb53db49bfef88081369feba07f47d55;
			gammaABC[27] = 0x9dc7697d6eae20955e721edfab568d0383504ce656d70df144bbb81e90f32cc;
			gammaABC[28] = 0x2cd0a315ec67d99c20f63adbd80c201bbbad7e1c891fc5fbb51e446d7b0e8cfd;
			gammaABC[29] = 0x15bb0ab6b428f7d57570b19c59bfe70fae726721e15f5f2628d56395bffb6443;
			gammaABC[30] = 0x1fcc4c3e018d24b18f55afc3f2ec5ec5b584e39ba481d07b8a893299402d1a4;
			gammaABC[31] = 0x943c0e94328abe88a55d1df21f4f1492a5242b7a66e7292316181330f839a2f;
			gammaABC[32] = 0x28e24c26840f429b36dcb5d6a4ed45828ebe3b6d78fd76d936f7f1d6e2997b44;
			gammaABC[33] = 0xb9622816e2877564e97bc94d332661a4b1d8e4d425eb4b170aa7918f3b0eef2;
			gammaABC[34] = 0x1a7f0be81d80b4955eb937b98ac2387be1315b4ccef2f8ded453ba9a1c48aee7;
			gammaABC[35] = 0x10fee2aebdb7316e40ac7e6f5ffe465916bb7cdbd8491c3e24170d01aa628b10;
			gammaABC[36] = 0x1d0ad80810e5225c23d6c2b4b274f4228ed8e3578e45fdca1dc7aa225676f866;
			gammaABC[37] = 0xaf94de756b842abe2ec73e4a7ff1061eca7843ba2b0ebe051900a3801ddb61b;
			gammaABC[38] = 0x218a79b72cada5bbd309ecd177c524ef0ac2461b45adcd1b13ccc2858ee1ffc4;
			gammaABC[39] = 0x6af93046c503358d420f2a1c57650d04208adeaaebac7d9a2174befb8bb816f;
			gammaABC[40] = 0x214bf3b3f7a7c8aec66e9562d41d7007799a62351f08159e0eed63b601bd4008;
			gammaABC[41] = 0x27c6fc42b358b63ee3500ee2ecaf8ffbac46c196572273ec564bcd1c259ae613;
			gammaABC[42] = 0x261b5cd57fb30a3d52f1fad293584442c3622b0fd3ecedcae46aec640ec8fb9e;
			gammaABC[43] = 0x39b04a46a2efd4c0408a16d3aeb5c09495d71057ca0c6a35513cf60eabded4;
			gammaABC[44] = 0x211a117586004b19eda15d7a93d82057926bdda473111107221841e10ae7b010;
			gammaABC[45] = 0xf813ec4be25aa5f0534538ffabe9f7ad517578aa6c049d20df65cdd49c200c0;
			gammaABC[46] = 0xfef7da52429c54bc135b317563ef4991bcedfd331d03a51c939f2ec51922af2;
			gammaABC[47] = 0x1a094be8862eac810b71d1fb2285d2bc06cf8f2b32b13171603a7cb0941441f6;
			gammaABC[48] = 0x28eace936a1de830e8e3e5fa7532c287658ec4b5dc596252464e519f3428542f;
			gammaABC[49] = 0x210115867a09af571c6c0850dee5cdff0020752bb3253c1610aedbbb953ceaee;
			gammaABC[50] = 0x190ac8d0aec7a3e96a908200dd127683af503ac1b3ae6c48333e92671e24781e;
			gammaABC[51] = 0x1124ea9d495646433b53214dab5a529940578f0ed6607c969d27d7b7769340e7;
			gammaABC[52] = 0x199fe465ef427966fd5707e18d492526a1b83aafadfe0952abab41bbd40d6c13;
			gammaABC[53] = 0xb01aa7df5fa361f7ccefd2af94e693de5fa3a19d25de9b4707342863469f18f;
			gammaABC[54] = 0x2db2fce738dfcd387354e299a2f8826d893e13b093e1adbe04d3cf285393a709;
			gammaABC[55] = 0x1447465674dc3248b8dfe4b72ae4ac00436c36b36dcfc0b6e998d7acd7cfbfd4;
			gammaABC[56] = 0xa53cb98a20b6fc571e3d36a7eb260e27d3e0bf14a32f7ab64314ae63bf4a11e;
			gammaABC[57] = 0x9b5d69efb96a9d6212d1d6418f687e1ec804d0757f848affdc7775ee6c48cc2;
			gammaABC[58] = 0x1430663da2c4d8e6777473a667882efb69e114bee23c18b13353ad936f823d4f;
			gammaABC[59] = 0x24f95ba391429baa1ca10f93a17b8fe455b5c1503a6e98d569c8265b549d2968;
			gammaABC[60] = 0x19a027aa605e3a4102bf78fe7e840494d2a8eb9d03b9a008f876f05dd5ea8f72;
			gammaABC[61] = 0x1093054cc561b9d82653424f8fc377925cba53256b6f6943569f4a0b8e33c96a;
			gammaABC[62] = 0x15dd5fd94810bd4609aef7ea96d311b9d97869bdc5b6735d2566f6ea6585704a;
			gammaABC[63] = 0x1aba2990b63b488c2a709613d0f94470a99c692d2bcbc1e9aa16a8fe1c890e7f;
			gammaABC[64] = 0x10dd00378d0a557b238666a39bfdbefe19e1cf3524410f99edace7a51d9f78ac;
			gammaABC[65] = 0x27d31b5d8e9df5cf480fdfd644e7c7c1d5bf4fc7fdf4126828c35455bd1a5da;
			gammaABC[66] = 0x2912a857e7e11ab7ac0f0434d09228d9b060b4d7c02ff28d3079e327342937f2;
			gammaABC[67] = 0x4bd887ceb954c582c263e01e2b1fdc237a4c0f008a50bc0fd016a36f533ae5;
			gammaABC[68] = 0x1d0fff2c6bce72e93df2ebcb8a64247bb056fd0fb93a72cb1a880b4fe61afb8f;
			gammaABC[69] = 0x3f5c8301e13f75e31d9c31acb23480fdb7300c48d727d0199457c2e052764ba;
			gammaABC[70] = 0x1e0b7750cc91797ce0c5106affaf199d8a594015dba89b04bf96c23afbb9b388;
			gammaABC[71] = 0x1f1d946ecddecc3456eb001817e671409efbdf4163fdba73d4ea739d2356fa96;
			gammaABC[72] = 0x4224dfcc2320067289fe58291de2c98be21b6a14468230e4bf23afd7204961c;
			gammaABC[73] = 0xe9ea0f8254606425291383072ea1352302a30df22a019695de5c998772fac94;
			gammaABC[74] = 0x1e057fc131b3c87a740ee79c8a06407a25301d46a9fcb8cd1da0c6ae0aa14bce;
			gammaABC[75] = 0x18397d48b16469e7829a9fd2d34d04f273257f08909997eb56d189258c215035;
			gammaABC[76] = 0x5a7506b665d44469cf0eeb8b62d66aa57a6d2b414c9b6e63d2520fd1b971eb8;
			gammaABC[77] = 0x3eb4551484cfc7590376d4d23b00f436057d4c12cfe7a84a5abdbd05dbe764a;
			gammaABC[78] = 0x226a41c92fc2178a4f2ada1aa1edbdd5d136e533b459911e1498813585078ab3;
			gammaABC[79] = 0x2cc901ceae501d9ec4e4798ae2cffd4e3f971b929ab15fc8283a7caeb2444aa8;
			gammaABC[80] = 0x1c0d2f7ae3934e0d03e27baa0ab3d6dcebb27e041869185665df87464862550f;
			gammaABC[81] = 0xa33b58f5dc27d5415d41a509eaa1802ca81ead9514410e89a55cda1683fe4cc;
			gammaABC[82] = 0xd437c3bcbd34d22498be6501eab27adf07e815bf5635a757b854391cd1bbdae;
			gammaABC[83] = 0x18bfc61db208b232cc8f1449274ba0d78b374a41c99a1a8d0ecfd911a8e6b408;
			gammaABC[84] = 0x2b32e7976c593753079dacdda1f25e04ca0df7c7bcc8bb1abb5c30a19bb14d1f;
			gammaABC[85] = 0x2953a7056a5531ad44619f7eea1a0bbedcb96a3eeec74e1792cd029c9f4eee13;
			gammaABC[86] = 0xc18c06c20413f2be94926bf8955a5d6b8e2b652db14148f510c1f5844b68115;
			gammaABC[87] = 0x17f5fab48c34fffd3449eacc809ff63e9d38d8f6c66edda0ec36bed528d89b34;
			gammaABC[88] = 0x1990ffa30015537e7bff679e77172e85bf0feb58dac7976b862bdfced4d7cb6d;
			gammaABC[89] = 0xa89de4dc44e455d7eaa52bf92be7aacaf6b99006c71c22129778ff0b0b64cd4;
			gammaABC[90] = 0x27352dbefb4d6396da0ab7eb513935a9ff50f4050cdd2e1e1d5bc38db693d3a4;
			gammaABC[91] = 0x1011ccd1e9b78cb79b0bd29b65e41d385e3bad52f11343ba881ad628e9ba304;
			gammaABC[92] = 0xace9a5df5bac1cb6d4e4b5092ede18bd3bea3729acfaa50acf2d3cd3a0bede1;
			gammaABC[93] = 0x222c27bd74ba8338ddb0652c9ac54633d741b236cd506f3cf71b10674e41de11;
			gammaABC[94] = 0x298f672dcb245d2cfe702feefb9a2d019e394ac72ca4e29a8910ffc07b6d21ef;
			gammaABC[95] = 0x26d38fc4b774aef9ddd7c3341ea8ff142e655d2f41617a7852869d4a1841c710;
			gammaABC[96] = 0x255b47e3e70e65f62c83b00eaac10868035d52e6b44632bde2cffe9582cc87a;
			gammaABC[97] = 0x283851303c4e3393d1b52c4c1d232de08674bcade018303dca6d3451a192013d;
			gammaABC[98] = 0x61bbb1111115fe0620878f11114476a7d9a5a12bb2b66597e87b560a4715508;
			gammaABC[99] = 0x2030f4945632c1cae2354c4073479c1b2dc89c0835000ff4df93e1cd17d209ef;
			gammaABC[100] = 0xcbbca0d73a8159ecda52505208193c30931fffcd5e80bf7fa64f3e9d4c05740;
			gammaABC[101] = 0x236a69d5036902f1d5b383ecbc1911dd7d2f3f078b0f84066ae3312e50bb3458;
			gammaABC[102] = 0x20f010359c4128e20b2e83db2cb0a75725dcaca2dac7881295d4040bfbcb144e;
			gammaABC[103] = 0x24d387a1d526fef79dcc553c467a3dd8511bae5d35c4441792954586350741dd;
			gammaABC[104] = 0x28da83781a488537e8e698974c60d021a6ce3013066ad0e12b25ccde739ff7f4;
			gammaABC[105] = 0x474fb6bec69690f1def6deae55ef5123489e478e597aaf4d6948a6021e428c7;
			gammaABC[106] = 0xf2426fbcc69c18605da66c4d21fc4897f6260b2c8f8945ce3d516fb498aed26;
			gammaABC[107] = 0x2c5bf8532cd883577083c3fcc99c1d3f46d2058550bcd1b4a2041d603ddb16e1;
			gammaABC[108] = 0x2e02ed28528b15daacc266eb8ff1d53eb0297959edbbfd78e2c3f354992bca0c;
			gammaABC[109] = 0x2798c4a03166eb5829e5e545a5850c044c456279ee88b67835ec3dae7140651;
			gammaABC[110] = 0x1263b5d9af85a2cd5d17c3a4c86993c8320911c097dea7fd796158a3b8ce316e;
			gammaABC[111] = 0x50af417ab2bfd67cd70e72f62e84d5f31d28b6a9960b2174d8160410b265225;
			gammaABC[112] = 0x29ffc066b5ba140ed63d1d611f40fa6467463658e1173d4b62f78e0a572f363b;
			gammaABC[113] = 0x1abfa04ff9ec7a52430fbf8bb21d46583509b39bfc60a90ef78c8e664dbc86fd;
			gammaABC[114] = 0x68179fb9d4c291bd8ef5a657959a4734d73766d6c00a59994eda0c985296a43;
			gammaABC[115] = 0x26bdfd178dde731e83b86a3f61f2c9a7c010c749a733f1cccc2ce239a3ea0eac;
			gammaABC[116] = 0x1e6cc556595304e4f199cb0f7dc0d1fc1db47300e89165ad671b0bc3345a0e38;
			gammaABC[117] = 0xc460c3d8734a024e20567eef7f5600a682bb7b0add9db1a92113a4563bbce7e;
			gammaABC[118] = 0x43b408dca23a4b3b8dc6d0e69353e41c661d7cc3188ad1462a22f36b458b57f;
			gammaABC[119] = 0xe547e3273aa654ccd15d51b750ec169161e91f6d5229f73062de3c1498e701f;
			gammaABC[120] = 0x2a6d84b3b1ef2b90d432cfcfbf8d1f9d0a8a1f48462271fc276ee8776f639978;
			gammaABC[121] = 0x2652944d240dd8712d9fe26d146402ef4663e21ad4dbabe1501360b9d38742ff;
			gammaABC[122] = 0x1d2642025db138315f5ed9794e13f0c6f5b3599e62243d8c3bfff71f8763a26d;
			gammaABC[123] = 0xea18d2af00de5ea5f6c816e90ce80b0c56bc7b4a7f00f07e4de68aab0d90480;
			gammaABC[124] = 0x18065e024637e6f8ea2517f14a5a966d3df74fddfa03d520854c7503e02cad46;
			gammaABC[125] = 0x1f5d333346cda59c0d68083f3139c563f44b247616dce4d2542b2a726493e632;
			gammaABC[126] = 0xfc7a3fe88a0c3a8d8b08de35827530487765b65660f2cbb50568f395b1c7ba7;
			gammaABC[127] = 0x2d33c60bf704dcd9f56ff055a75ce95e71c047c6bf872fa467b1dfc78b65a79e;
			gammaABC[128] = 0x2c4dafefead0898e817fa91be0e40352b7faf82b50d436a1dc258d5d5cf32936;
			gammaABC[129] = 0x24d84707effb974166a3ce9b57c253214763b4ed49205c4ec5646be6bbb4da43;
			gammaABC[130] = 0x2bce0f9da51e37225822ea8a5c831b40f236063b8292f20df0e931fa669e0d1b;
			gammaABC[131] = 0x179e067f3279d4e7d0e59b13cf08345d0734033ba9fe6264aa2543710525669f;
			gammaABC[132] = 0x3049d9958a595534f38f7fcada670ad7166025ca26b029ccd21bdc08d4d3a27;
			gammaABC[133] = 0x6149297cad6fce52983d24e14831d63c8cf05b23a7208f452f1bdad7b4adbbe;
			gammaABC[134] = 0x21baa02292ae78a8d1cc4f0e0cc637eb5f9f27cc0a391cf6b963620b088a3a32;
			gammaABC[135] = 0x237532614c12e0661ec6f57800974d990c825306f46ed81c5c4eb1228a7fbbb9;
			gammaABC[136] = 0xdd5294b4b99e508781a42f1a239307e696af8349a70d51c0afea00f4ea5cf60;
			gammaABC[137] = 0x1d76448aca5a0ad61aeff53cdb196d47be997ab4c212b0a085fa28c29859a792;
			gammaABC[138] = 0x1d13e1a2e2dd00feb0017858936955d4f3c813db986fcd49fdf2f0082b84423f;
			gammaABC[139] = 0x3e95fe968208a75cd71c722be11f0bf7e3d6dde47c66865ab9ba60a9c0239df;
			gammaABC[140] = 0xb97a4ea3845544f7dbdcef4a7880374260954bee86ac5586d942da743eaf5be;
			gammaABC[141] = 0x1959e6938c8c29cb762a543b178aa0dc44fd11e35ab56f051b60838315f422fd;
			gammaABC[142] = 0xa4b3f9f6e915aa8a05f3d8c6a1ca0aef6fab273296382342c6a524cd81eafb8;
			gammaABC[143] = 0x2843527a014303b2a412e3dd2a54f5c4f5e1f23be4b749b941a229c1d4faa393;
			gammaABC[144] = 0x299d23a0aab560ac54d862711494e22275ba25c460e6f548f99ae32c1b26ae08;
			gammaABC[145] = 0x2fddd6a747acd52ee0b6dde9197c731402f181d8cdc908197f72eb5d6b734f2f;
			gammaABC[146] = 0x4a55b0f6e10248f41fae9357283a4d8e9fe0c33aa04450b442556ef8ce0db45;
			gammaABC[147] = 0x16a3c36bac2ea8a3259f3b682b98f3f7a55ee635727e8c6deb2e73769a28b7f9;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierFinalize16
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
    
        function VerifyFinalize16 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x305bcfb20730f993e3421a15b5aa35a2c0bc63f833b7587c480261595e5115b,0x28d82ef33e08f536d498343ca425cc615d2e50ef4c58411fd53e7bcaa1e75ab3,0x10aa9d7864b569af494b272017dc1ad9870195a8cce37eb762dab6a23c1bc614,0x2db49da263dd085c2cbf82457b5788493b73553972e05765cee0ad40d9a91b03,0x12d6a1565b297700bc41c754e72be7124e21cf18be36239f361c73a8896bb492,0x5492769123d532b4ee6d385400be46cc677c0ba34af32772c068c17e8510762,0x18e475f66686991523c11672f53bf3bb52b1dd75dac4c064a060d8f9f7cc8ab4,0xe5645a0fbec451a7c26352a1b4aea99de96e73f80a79e15a5f0a090b5aceb4,0x1fa6b8075a5e9fc97906c568cc72b302dc5ee8d9ac3822fe7aa4403e906b69b3,0x20f410c6a5cda72ad8831e586ed3b0782140dbe744ab8101452e0e9ea7560f50,0x10931c5170cd851821417f3435c5015de2901119c6424d363f6a8557ed40738d,0x2871bb0b5f3abfe1558a555e121f3cacd15520b3d7504d63acae0d1688dac495,0x2ec083cfb7febfab9c24d5b2cab0711cf0356dba856dad777bb4570e54fe2580,0x1fe301d909ba81c2b06f10f2d823b9b31afd0847c72ba6f61f9dc21aabe4826e];
    
            uint256[] memory gammaABC = new uint[](292);
    
    
			gammaABC[0] = 0x2a372f9d52c8804525e21a69865f06c84fc6596f0ae8486f364d7d3dc041df0a;
			gammaABC[1] = 0x2bff53cb2ede387b3972c796719b13271d95df82b3787c16635f9c24626e82d3;
			gammaABC[2] = 0x74f1b8aac42028980877a5155969ef9c7033e1e32ddff20096eecfa0289e719;
			gammaABC[3] = 0x925ea0533928ec1f67f640fa96c290641475727f7e311e37e78d6a1874ed516;
			gammaABC[4] = 0x2a9c68b235bd8b23114126a06bea3da49a9ff27148245824d3042d48d0e60cf9;
			gammaABC[5] = 0x226ede3e3a058653186ce37e5664eb50220d8b8a956884ccbc404babf8436e7f;
			gammaABC[6] = 0xe4402abea068206ab88f093b28b21f7d98e3b58f23f339836169d38f07eaf0c;
			gammaABC[7] = 0x1a5870e82d88ddb095feaf4ffd311c0b759ee874de8b50baac026b924bf35630;
			gammaABC[8] = 0x23f9c5591660838e24a6b6f5e0423be1e552f914f6b6dbdba74af94f74f1d60b;
			gammaABC[9] = 0x11bd97a95f262378a2c3db68af6abc32fcdd41a8cc670828d20e503a183313fa;
			gammaABC[10] = 0x28fcb1027235cddea23338dc1f8f75720efb274c0367f34ed1c9f71189ca5e82;
			gammaABC[11] = 0x2c87c8a5860aa46f6ef976d03987579877276a338d54c6d6ad58f421daa128b0;
			gammaABC[12] = 0x206d77e8c8f1d283b85e7cfe19c40bad1172d97725032983c8b37c2fb448c912;
			gammaABC[13] = 0x2ef695ee103d3ad67ade74c2bca62b7eb5bf40483cda82ed66b75387f452eee3;
			gammaABC[14] = 0x1d99e15e6588d2509cfe6ef38fa3cc251a39270174a811d2da73dc1dda54e6db;
			gammaABC[15] = 0x19bc5b68ec72c9c079e275666f06dd5932c7780223e598def9269e4aa85677c6;
			gammaABC[16] = 0x1288d6d38982633245bb4f13110d0cc8ea55c4c4515c8e6d5f44ddfb5d89bfe;
			gammaABC[17] = 0x6217193ad97ebe8a8862df6ec44af4a99ca4411c02f93def34aac1847109152;
			gammaABC[18] = 0x287ce9778435ea2e38ac918a53f3da5ed3d98f33398e5c40765591ebe02996ff;
			gammaABC[19] = 0x214a2fde3aedff1625ea06dc3a76a5f517f5a67f102774bdf02b979264dfd8c1;
			gammaABC[20] = 0xda55316d83efc9b435db15cbba64b3a4fc23d9290aaa485fa2f6c63d0fb947b;
			gammaABC[21] = 0x1ea6833a9e5b8fe13984f477267bff1a25e9de753d72ceb54ec9bc7e2c0fef1a;
			gammaABC[22] = 0x2edf04cf1d11480ff64b849f729dda4e857677b9ee3520886cab81645941764;
			gammaABC[23] = 0xddb073bfe26b8390ba604439b3c2f7dde129b28a7bf80af7f7d563b60d507b0;
			gammaABC[24] = 0x1069cfc8d4b2b13d89a911bb93b5068a677f25e2509d4ff7c71a2d472304ed99;
			gammaABC[25] = 0x21f583c8bfc5f68ef54f3b449c525ec836a66008b802d6aac92980afd5bc585a;
			gammaABC[26] = 0x211c9df314b4c6bc03a815cf28f586d3e4d9c2d5bbfa342f3ee6a21195c184ae;
			gammaABC[27] = 0x272f45c7778c2da75b80b68e9115fffd85ff682d367790b46aca38aa83cff46e;
			gammaABC[28] = 0x1c357fecbead61175e682ecae138d9380c3a80d7785e1ae2797ef7df1caaad4e;
			gammaABC[29] = 0x2a52423b7bbc024aa68a42182e058245c2521ffcf7f96cb4e7faf43dac825efe;
			gammaABC[30] = 0xdad2654d0f0cc6ce46e0599ec4255b1682e296391b0e082cefe1102f9ccf9e8;
			gammaABC[31] = 0x1c9f3e027b36b1d09b728bdd71486abc2266ce02333fd5822348fd7d76ef1563;
			gammaABC[32] = 0x1224eec4f9612d4d0e977c5bb0a8a269772bc123614b8a6632adfe3807fa1315;
			gammaABC[33] = 0x1de84ad33eae589b41d96faaaa3e54d55186e476df0fa7270373a732d184d5bb;
			gammaABC[34] = 0xeeb165c7af0b3514f10549c9846254f0ac984a17e53ecbc53bc5e2a5894f503;
			gammaABC[35] = 0xb23f7ca16615a5d402416a8260d044aee6333a5820d3a04d1bff55aa4dd2998;
			gammaABC[36] = 0x22848cb6a0d28df1dbd459dade4aeaa830f171cbdf1b57636bfdb42afbcc3fe1;
			gammaABC[37] = 0x1c85071ab7dcc51c414b41bc249cf8ca431bb353ceceada69f791e73f0bacb9f;
			gammaABC[38] = 0x1f409aff38d8d3c1b3801fee1114e3a507c0da704d857573eb21a2dcece7e5e2;
			gammaABC[39] = 0xe995b2d59e80cea3420ef8eae8d17b85b97ff2dd3d0edbc9b1f117fc4231820;
			gammaABC[40] = 0x1c714c04b00953bbde64dffa4e0dfe139aa1b953fec9bc1735d41e5e1aa270bd;
			gammaABC[41] = 0xfb8f04d3d37d30a68a1fddbb219e0e1ee88c183f89211b3e81c76fea1177d12;
			gammaABC[42] = 0x1d190ab6e2ae9f6296969a781672b971f282f7970bab249fdec8dd2b1bd729a8;
			gammaABC[43] = 0x143d1bbb900dbc6e89fbab4f9742442de86e8ced9c9db0696daae31b4c9c08e2;
			gammaABC[44] = 0xd29485f2e93405c81e61244a015f02afeb60f4d910e10639a35abf89ae848da;
			gammaABC[45] = 0x11e277f05d6dd6d87cfda02e7eb65db889a2703855b13b94ce07a2588ad64d4c;
			gammaABC[46] = 0x2beb43540b4abfd4f0ac1ab896ae0f26efcb0e4bab14321d21d528c4251911ca;
			gammaABC[47] = 0x24bf24753532ba1cc0da21f2f81806489be37be0535b726a40ac75f7910eab63;
			gammaABC[48] = 0xe481b598e27939023e07d350516311507e0c622868786e6e0564884b9f66e74;
			gammaABC[49] = 0x2723bdff1937346c2713ed559f8686433a6aa8fbfd27c175ee0340d8ac486b94;
			gammaABC[50] = 0xc5df61ed92c49e3c0631a4fdd1d7e80a714ded67c782b07cf285e910a4b3050;
			gammaABC[51] = 0x219cc9f7eb6885d0848c83b5d46b4e62723140a456d43188f9ec451b9a424a34;
			gammaABC[52] = 0x29c06cdf23ffa2ba05581b694d3f7f70a252ce782c16a4eb3e2354e23459a5f8;
			gammaABC[53] = 0x1c621f05dd84bd897ecb2632e09b5f1c77be8a31f8bc919b2adf8eccfa904a43;
			gammaABC[54] = 0x19fff89857731a4b118f91abf8785fc1b67d1f07e3e65ad75c1ae3342f21d294;
			gammaABC[55] = 0x2fbdecc5cd0ce4f60c5bbe52c14aab986a593e878d1e97dd97e60a06cfc0d889;
			gammaABC[56] = 0x2328d7dab6eb21b7a9dc346f8769b852c35ac7c4899ef44763d9fed0c39cb4b2;
			gammaABC[57] = 0x188e79c2d04ab9f6ad47dd8a7bafd20338ae50df0b0e6e4d00c0813958d110de;
			gammaABC[58] = 0x80a05f3cea8293ecb3e9ec1539c5ec96b6fc1091333cefe33d8c6b499620bf8;
			gammaABC[59] = 0x2e52cd3676fdb1e96ccac454948450daad5b9707c0d32391fad02fc8e3637d23;
			gammaABC[60] = 0x1f3cdae41bb47aa8054453e42596f71d78e124e81d9467e47f0030e5096804cb;
			gammaABC[61] = 0x29483039a27442cde9b4c60d0d8fe8c7c6cbef6c48fc13fb47d926043a44a206;
			gammaABC[62] = 0x6b9a722dfa95a994d6bd2e8f2646dc8206851b66d052c8dd3a539250defdce0;
			gammaABC[63] = 0x10d1b2f2f2f2904dbbf00972feea6cdb8f201cd63a2819c477eb62b7a7b352b0;
			gammaABC[64] = 0x69bdd790a62275f1f668d5dce186742ce5a3e6ad817bc7b583afbedfeb3d43f;
			gammaABC[65] = 0x21607e8e340a6f6eca9d8b5b2dd84999bd81a53502ff052b529040cf238348a8;
			gammaABC[66] = 0xba3289d05615ef14ca7c3f7bc471180d6441ac8c7b413e211e272e87e3e74d6;
			gammaABC[67] = 0x288663ab5cc237734e5275e987f30590bb49e9bfee39c5df7a9a4409761ff502;
			gammaABC[68] = 0x2967f130653c38d38f16fc6e1136d644e2da19e2b0680bdf7b43cfb536942848;
			gammaABC[69] = 0x249a514676d5b44d153d2a4f25bc8c799787f5148217fda30236bcf2cc39e5ad;
			gammaABC[70] = 0x23eb62af14a00321708749791885821f7879e11f5a9afde8b80c2bad442f9811;
			gammaABC[71] = 0x2581b444de870811f730d68140e16050144c2de63c244ed4f914e6746eaf1bab;
			gammaABC[72] = 0x1f9f31c0973729a4efe45632ced3fae8aa6c60c50a5169db87d9e3117b710c14;
			gammaABC[73] = 0x18823f2a53762b2a6a5522a87dec8a729b3e2f5ae8a27d8ce350ca14e12c9c05;
			gammaABC[74] = 0x261f5c630ba52ffcd57accca17b1935391e9ffb2fb80b1cee9233c610a8f2ecb;
			gammaABC[75] = 0x22bc6ce4cf72ab9373f08ad24273343845ebb293ae6b55cd8a1b68e5710cc888;
			gammaABC[76] = 0x25cc5cf9c1ef1f470b537cbf0cfc64cc9016a58cd9fd0599777b81449e21c5e6;
			gammaABC[77] = 0x1f4fe04290c5dfe8a3c7b29e127230342fa088ea413d42b41dd0ea323585b299;
			gammaABC[78] = 0x2a7ad7740c4fda9af1fd61c9bab04fa6fcf5768ddb03fb0eb1254d25db02b718;
			gammaABC[79] = 0x1aeedcd0793e63792ad94940eaf3fb026d650360f76514a07145da41192a8822;
			gammaABC[80] = 0x1db168dbc59e59671392c9282c096cea308ac6d4a14f62aa76747da2efbd0c01;
			gammaABC[81] = 0x1ac4331d822bccb94fc80386512eac00092c6bfc1d5a265fdad150e95d5846a7;
			gammaABC[82] = 0x4d20a145e3d6b6f23971245bcd7b9199faca79cdcc68a575369bed2deb3ca29;
			gammaABC[83] = 0x2290be46d7e81c2aad48bc3eb29fe7d2949a61532a7eb8bae51f630882b6183c;
			gammaABC[84] = 0xe2e499c9aeeee96ebe8b8d2c5d7c26835ccb3d9a4fb5ed2ed8e009757400aa;
			gammaABC[85] = 0x22efe335a2429b90e9e984615002b75edae9066337f1c96debf8da07f36748f7;
			gammaABC[86] = 0x2d711a0790ca6363de7e2fa75b964e53c0b1c09b20b86ac8b8cb163123e0fbcb;
			gammaABC[87] = 0x16ae969d64569383e6b0a25021da33b7c5aec7868db48e11418db29f4569e4ec;
			gammaABC[88] = 0x20efc0ce4a86d68a2705e7c06c9b1dd4b8487a9737c02c750a2df65e7d13dbce;
			gammaABC[89] = 0xd64523fc1cea15558ee07cdd31af433bd6a86081ff9551518c7cf39c5ea09d;
			gammaABC[90] = 0x26ea9ae30cfd7d2797cd30258efd3c5260635171d2a3ae774a8dbc4e4d167991;
			gammaABC[91] = 0x248f2abb883dd3d2d0bf923d16d8afeda78047fc491d44b1ac368ea48dd1cd09;
			gammaABC[92] = 0x2cb89cb5c2394240c4ffc559181cae71a199f36633f84c0ec1259f8eebdd2bea;
			gammaABC[93] = 0x233680d625ea79928404619246ad44b6cd4c7d89de5c81aec000e953bbe2cdb5;
			gammaABC[94] = 0x26f6428a7f8549917174f79288c3f55cba91b3581bb7505e4b8d8278e5644f5a;
			gammaABC[95] = 0x2b484a660250c888a54d4467faebfd77669d7c5504ba7f2361fbc33f225c7a11;
			gammaABC[96] = 0x2b39ac2635aa674195349d9864639e6e58fe844269353bb2fc0a4bc4a3b76bca;
			gammaABC[97] = 0x1e8be88c428ebc3292913f757eb4c129226d53949b1a7e751d90c44b5b53fc2c;
			gammaABC[98] = 0x227709ae8f73ed59b467ce7228c92924f60a48d09f24feccc0c5efdd31c9f899;
			gammaABC[99] = 0xd5eb1f24d86cb511762bd87b35a5ea747a656d6abc7d4b686c13848e455effb;
			gammaABC[100] = 0x15c3ebea77212cfc559a3e6826d1cbeb95af1409b351b4fee8d46f3db78e4436;
			gammaABC[101] = 0x29ae6e97428f778a11b2776e0ad69e2555050f2eb822631ccbbf9b08ad66194c;
			gammaABC[102] = 0x25beaf706faf2fb8c0fca56e37b7154a3604f3feff3d6d77fb073111edd8e81;
			gammaABC[103] = 0x19b7f0c1a74ed8ad88f2852a92e08764c66e5688b772c1df6cdd0fa43534cc8a;
			gammaABC[104] = 0x1d8d14cbcb6f33ac730d82522d4405b8453d5b9076aaa322211d3de3d8ed80d6;
			gammaABC[105] = 0x3048fe243263609bfdd4de20d93f8f6861eb188ad39c66bb28136e52550bcc22;
			gammaABC[106] = 0x9ae728aeced663437a4c634ec46048781109a29a9d7ec3822443dcce7bc6d6d;
			gammaABC[107] = 0x301acd56d5eb25eb8571fbe22bbceb2070ce0dfa617c467e4decad9c942d864d;
			gammaABC[108] = 0xab6a0c1448f25ec2f0c045b9070929a9080c3cac1c951521b1fa58ef1d40daa;
			gammaABC[109] = 0x26c3ae0f3de73205b0af65493413f769571cf36b88774724264f44013d79fbdf;
			gammaABC[110] = 0xcb474d146ebb7cb3490f1ac8231a5aebce174d7db31035d746f6fe2a88fa2f6;
			gammaABC[111] = 0x10679c210f5df2db4d664b2058bacacc0ce4189304b80423bf56203b06a72114;
			gammaABC[112] = 0x2571a77f897a09a45b40e74220b4f230200166124edb7e1f6e5c9485a8b75443;
			gammaABC[113] = 0x20692224f7967d8bab9fb2e4b4e7414bc7adc5098464e37ce3ecf9c9a1d9b64e;
			gammaABC[114] = 0x287955dec8ba7925a2d11c9b0eeeb3c20b556c67af0c6d522ad06fa21f7673ec;
			gammaABC[115] = 0x194a5d8f0de100cb9e8253a3ec984a86c6bab4f802812525f848d1377463ed99;
			gammaABC[116] = 0x28ae49ccd6eae471fc82cd7a4a44cfe1d070dccb4c51ad663a55729db1f6b4d0;
			gammaABC[117] = 0x291efcfd278eee53a8d9fc09afe3a431a77f1490d41420dd2e69b35e2e3ad7ac;
			gammaABC[118] = 0x2b7ba574ad0aabeabfd3877cf50e222deb67b1eebc2116d5a60fc30300193818;
			gammaABC[119] = 0x1f99bd684d75e056149bad386498ee098cd39f7d90df84a00fb7126c884becc4;
			gammaABC[120] = 0x224424a7c020500da7b67bd43a89f38e4c3826dc73be0539304bda915d9436df;
			gammaABC[121] = 0x1e9081160ce5f5f7a28fd047867298406d7d34af6f654321296793e10c5eae15;
			gammaABC[122] = 0x267249e409ff165339bc22b41820622a4ae04d261e47a18f1d38dca5bb3c3e94;
			gammaABC[123] = 0x1d6edf2e80b52b20962f59c972f0e105cc7ffe35489766a6497af1eac19b5889;
			gammaABC[124] = 0x6097012db77c34eaa2b91375145824a4cb75ae8430157671bf03d778e31c1d0;
			gammaABC[125] = 0x223dda1049d9b2df1e4e85219753eb800470734631c497e61bc78701a504dcb6;
			gammaABC[126] = 0xf280ec09399a5ada994114b958e6e318a8cb2ade9fdc67676c5952fe64b3a68;
			gammaABC[127] = 0x1b99cb308f8353e5f93f9b41a4db265d232d2614a5a4468097d3fee522224e0f;
			gammaABC[128] = 0x277a409a9cf444effdbf3e9da598a9424ff3c3c17e1414df9c863de7938cdc03;
			gammaABC[129] = 0x1872b2eb26de4ae41a36b24f16096bd086fbaa12af17c12af43f8d54e43a9e4f;
			gammaABC[130] = 0x2280babf59aec85bf3b6cbe2c40dd4fcbe6a746f4def4c6a5d5eed827b91aaba;
			gammaABC[131] = 0x126f3af955fca4f8b7891ee4aba48fa9375107c135df034cbcad7c17cae376be;
			gammaABC[132] = 0x28bb7d899e4fcd4c0e65f92f67965299052fafd7e9eb9af53268d8d78a4d2a97;
			gammaABC[133] = 0x1321b9bfef320a7f7b1616d28bb2009a8d3fc64e264901cd7b7d3c2c19f9f7d1;
			gammaABC[134] = 0x1deac0b255523f6442c07ae0508e2db732664e07cdd7b77df22c0fe3b975a110;
			gammaABC[135] = 0x31e54beb3f98d21682b448b62cff280765eae0cce4ee7262d819c0c27c3067d;
			gammaABC[136] = 0x2700a21c1ad257cb3c8ae0009e56fe11d6737bff0200ba14722f9e38a63705f;
			gammaABC[137] = 0x2ace84b4e480a37869c3560949007ea7c445b79faf96753c4947e63649ccf504;
			gammaABC[138] = 0x9012a43f61e3e2759b06210f6a60c282e72343aad5322b7f1c04ae339b858e9;
			gammaABC[139] = 0x1a4a1bc7e1987bdc9857407319631493eb4a89ff015940345b2a7ff351ce5f52;
			gammaABC[140] = 0x21b77458c785619ebe74b55dbeeb752ce9f0abbf6bc9357580c50502ce60a5d2;
			gammaABC[141] = 0x13e02bf3d05d10d7468b8445191a10a361e89f20403adbda43235de542b125c5;
			gammaABC[142] = 0x202e748dda736a5a0cf3b426553d3ef0fb620a30fee0d32ce642e407710597ee;
			gammaABC[143] = 0x2b721423a7025f98b91bbb044760e225ad0acf69cbcde88d595dab0d73c2e83f;
			gammaABC[144] = 0x5051102eb6af0906a6bf13fe4c7cab9e3858dec9bae923fcff3e9798cd1b351;
			gammaABC[145] = 0x223e4612abc42358ac54b3e7e03b882e10eb69bd58db72ee4f4b170c7850b462;
			gammaABC[146] = 0x2d9cab8f25a69e79e174919924ec1f303d5033688f8160632e236f3ba0ec0877;
			gammaABC[147] = 0x13a57d6731248c1209ffa7e67d04c1e4945e78b25c641d6ed903d889f78aef1c;
			gammaABC[148] = 0x12d7d3dc961d72eae304672d0371c2da252d33505023ac45ef771af0e7261b59;
			gammaABC[149] = 0x103000898a5913fb7f38aacb3753169d13a46e90556c13e10342ecd5df7ce1ce;
			gammaABC[150] = 0x1709c0f1a248c32be9e4043943481f0a28ff6396ea69d2771da86589488bf1d9;
			gammaABC[151] = 0x2ab414525caf27f9bb8743cdb2c61d2ebf82e90a6266d504cf498286f1fc1f0b;
			gammaABC[152] = 0xea741df260484b44b9d5b6af57ec893fccc674a8455c9e03c0827a535cd5c91;
			gammaABC[153] = 0xfb0875b716ad0e6d6c46a9d3e8f74ec8cf237c0876dccb6d1e28c215a3fe951;
			gammaABC[154] = 0x176eb4ab1de7a4c15ff6254bbb1833633be25f3dad309eeb59b4282449957617;
			gammaABC[155] = 0x119c1df93d38e69a2e875b7aaf6dc0dd66a1429ca6e92b9e0e6df3c221c19656;
			gammaABC[156] = 0x1c25b0e67b023c21b2dc14fb648b9843189d907973ac9d81e6d97ee6a3a25f10;
			gammaABC[157] = 0xd6f7e1683ce0dd4754a2011f5c5bfc0225051be08da40d918aeede5d289fcea;
			gammaABC[158] = 0x162b1e9849d9c4409a4a78a3e527c0670c9f118412cd3cb2bb122d03d732c122;
			gammaABC[159] = 0x300bb0ad6988290381617455ec1dc84279f59449abcc563baf85c321a7590c61;
			gammaABC[160] = 0x1538ec1d092b507385dc609795bce68af392f88082bd611e76039a75b7793bed;
			gammaABC[161] = 0xc04653d1893d28fc7fd6f75e0812910743027c6186f7948e6f9cc33760692a2;
			gammaABC[162] = 0x1f55ff3c9b5731b0ee9f5214dbd87eaeccf31fcf878e46c79a543898e4c81371;
			gammaABC[163] = 0x15f90a90332b7a265ff6228ebd412d508b6804060771d500a0a29154144598fa;
			gammaABC[164] = 0x2d66d1fb4b2509437fea3b48fdd2eaf1cc86c885a90488b794e120e44b8b6e09;
			gammaABC[165] = 0x2094ce65e7a3db17286946177c360fec694f4ca47adf563cf04165b0cd5f726c;
			gammaABC[166] = 0x13a39547880c78602c21490891fa55fcafc14c205a3a2a74c24fe86aa9bcd737;
			gammaABC[167] = 0x154b69217548d362f46e5287e991f49c79c338b784305ef533041732f445a4ab;
			gammaABC[168] = 0x199c13c52dd5d1b27131c295fb9dfb3bb2309d5f560663174fac7a4160575ce5;
			gammaABC[169] = 0x2e70a96888da88393cd5f30e14252d0385b2f253ca7c5f4fb8e93f4c54e05421;
			gammaABC[170] = 0x8f12a799b0160c728e3ac22a367ee8561dd8da319d4aaab5a8e39ef356ef5c0;
			gammaABC[171] = 0x1b7433bdf2964a949975fe3292385eb37372e0b2451cdd3f4fba1f652b0c6d61;
			gammaABC[172] = 0x21a4dacb136fe6aeb066df6d2c0276cc7056aaed31906c60d4a61a41447a3b1b;
			gammaABC[173] = 0x212ac901ddfc4e1c38089af23effb1cfc41f81e08a438644039c51c483c1a1cc;
			gammaABC[174] = 0x20965a4c9fcf644bf8ffeb997b34a30baa1249c817f059d332f8f3b94b0b945a;
			gammaABC[175] = 0x20ac6afd83387c4b8e09a47613f200b8be1b150787ca6936047cda92a81f6665;
			gammaABC[176] = 0x2bba86900a1499629d6e19e2d172a4d29aef29fc5d86a886c7b3aff7bcd00ef1;
			gammaABC[177] = 0x1d8077878f24eae74b406f4c819f4f9dc97b7572b8e452a90fe5dd66b6d74471;
			gammaABC[178] = 0x1beb146340d5a2f2ebbf20eb8b27323ca680959ac6f96e0fdf8ad604c376ee4f;
			gammaABC[179] = 0x2e39233a176b3a982b9eccb2125ed7139b0756f8d81f2ff507deb748e2115a8f;
			gammaABC[180] = 0x2c21136c0798dec0e6a3ffe46d7b24221500515adb7707802d8978900ecc8458;
			gammaABC[181] = 0x27c0a4cc64474fe26b09b6e8be70a24b33cae33cfc7499ad05ed1c10cf1c7099;
			gammaABC[182] = 0xbf957fb2493ef3400140461498c0e7beee0f5ae5378ea516934dcd92c2326a3;
			gammaABC[183] = 0x1227f7972bd3783eda03bf32b6967ae64c23b87667245ca938385cfca77b4f39;
			gammaABC[184] = 0x63682ff729c90e2a9bcb995d1b6c009f69d2e687d505195e901dc7e63ad033e;
			gammaABC[185] = 0x223d9a7008d952a44849a7ffca2fa0367100e8e4e55c91b5cc02e4531b5849be;
			gammaABC[186] = 0xa568f13783aed265565a72b47c7227636a02ba10d03bdd30d0a752eaf485d40;
			gammaABC[187] = 0xf18825fd46a12e5e6572e87a05fc02df04e80aaf5b1d12921415e0af6f17d79;
			gammaABC[188] = 0xc02f7954338507383fbf882f9b53c7299f33ab0d89690db4643ec1ec3679a8;
			gammaABC[189] = 0xd27c0c248b5bb5c313e10086a1614a729030ee9ccab4e295fe466b4da0583a3;
			gammaABC[190] = 0x2814bb256d959c03f523ada28cbf989ce91c48d78b4fde2213731d7a02446333;
			gammaABC[191] = 0x10b03ee891cab0fbe7e21024417ce61a38adb918b601901096968c26590a43d0;
			gammaABC[192] = 0x29c2e19df3754fdefa5ecec4d9213d14e477aa89b3e8a2fc18a452a4ef5379e5;
			gammaABC[193] = 0x17a76432a5da94588a44722d5f6190c114db87a94f607b3e09f7806ffffccc1b;
			gammaABC[194] = 0x4bac48eea6ea825f68cec10d0a68d6b1ffff41f915df76a1350d32481bbe1f;
			gammaABC[195] = 0x1bf91d5831fe1bcfbb7c29a1953d253eb749865101717c3c8f67b0c571b4cad9;
			gammaABC[196] = 0xa7d97c5eae152f207addd8c542a4ec3282baf9cd69cefd0103b572fe6273b3;
			gammaABC[197] = 0x56b24271b4653312344f01526a907c28f9023de06804f9343db4b0aa09e60b0;
			gammaABC[198] = 0x6efc1df5e1944c91b7d08d8168083c74fd9e643e75e8413d78cc9b6d6f98ab;
			gammaABC[199] = 0x753f95a3915ae307341efe3fee389fdfd7663251b88fbc0ca2f8f4066937824;
			gammaABC[200] = 0x1ce8171475c2cd30c5d4d747f1c05263f0c89688ff25ce1315a4f78d309dedd;
			gammaABC[201] = 0x2a6cbf4555612c566cbb8e511f89a46d054ca1e9ce3c6849f666fd60b5a5a574;
			gammaABC[202] = 0x21f91afde0e56ab4c4181465ef67632f72b7cde8b90593c4eaf606e1c10eae28;
			gammaABC[203] = 0x2dd3ba12424eca5dfa82eb099ef59d410d9735d4be6d49ac466d8a1b80e1d749;
			gammaABC[204] = 0x21f2ae28207be891c3691acdb1a51983f38ac932af740604a94a03f8d1051e6c;
			gammaABC[205] = 0xe622e30d3a625f29b9a09e7a0179a48f4973af884d6a61c88ad122bc602c68c;
			gammaABC[206] = 0x20e679b0f3b4b7a74c569b1c5954b17edadf74ecce62f9a7923be1087403c532;
			gammaABC[207] = 0x1a5159ef81096f234063986013a56a4b37877e032835fd6233bc07c8e62182b5;
			gammaABC[208] = 0x18277c5ebf88b3e72afcae20147fff1f290f6eed42298fe22c949cccf8ff0b53;
			gammaABC[209] = 0xe6b6bfcd15933e22e70ecef9409e0572246fe19a48dd967ac6c4dce61fb6e76;
			gammaABC[210] = 0x73d36c62171a18b7c211e51530ec5e943da413055cc86eed0dd738fbfb7a00e;
			gammaABC[211] = 0x28f3ab5edd34a560d9408184e872514a55f9a787247b0c608a5aeca242a44683;
			gammaABC[212] = 0xb79cb6c422ba05cb3472310cafec50c55576a0e76c5a8c95b1fb1f0cfd5cf7d;
			gammaABC[213] = 0x8616ff3b5826f233ae3e46d3c4a21dedafcad5b5052e77d51b3c00bd0d5a066;
			gammaABC[214] = 0x17c174f0a07d9f2889ed39266c15ca518df42516fe195c5e9ef72c2049ce6679;
			gammaABC[215] = 0x81cc2aa2b08b9b4040e68f5841ea7c72de10253d0ffa8df8fb1085bec954bc4;
			gammaABC[216] = 0x2354c8cbc4f97982c4b633374962afda2a5be7a0592d97a3820ffdd484974e7f;
			gammaABC[217] = 0x3ec3611bd0a01f49c738b81708edd9d00f05550bde1a29bc3020dd753a020f;
			gammaABC[218] = 0x3050c7846b69ba14ba4cfec8238419d187bbb848e0b2265af7a33b331f4211f5;
			gammaABC[219] = 0x125fa9309b56b82f46b92ac44b294d9a53125c2d324379950e84bab6f5e1a043;
			gammaABC[220] = 0x5053d38e2dcfe4233653772c279f24cf928ccc68ec32607e4f121bae7772e1b;
			gammaABC[221] = 0x2603160ae2a720bd48280a49d0eb1478e92f570fe9f905b54a3efb2898d1c660;
			gammaABC[222] = 0xe4670be8430402b663f2916ac5dcd4e2700727fb895825c2031ad24a0952abe;
			gammaABC[223] = 0x173c02bbe7a9cd7af53945490f9063fc898e62728f4bc8578a5b8ace1a607951;
			gammaABC[224] = 0x2197b015de52d54c5a6281de84ca4fcc6d3affe7129e2f3f49f5bd37c450d09;
			gammaABC[225] = 0xa6e5744ee97df8a34c7c173d1d939e8546550831e3d81a1088cd245870b14f6;
			gammaABC[226] = 0x2613e4fbf713fb88da3cd2ba84dd9740a3dbd6748280ca6c2f2852237985786c;
			gammaABC[227] = 0x30599afba9064fdda6b1b646fa1e36fe13c107a444d73d8f413706a16465d2ce;
			gammaABC[228] = 0x24177c906f4cc9102bf70ffc251fc58d8e4a691131b3d3ac6f8fb46b08dd0986;
			gammaABC[229] = 0x85a432305d5f497c189db0de4e0794d2f4e2fc16f4bd10d35a6a77779f04909;
			gammaABC[230] = 0x265c6b76f22ec764780878b2a9f233795e55adb37c90540a4ae8d951a93b2cc;
			gammaABC[231] = 0x6bf34513d0c13044a496f731b8d6541c5c575c4587acc579e1236502896524e;
			gammaABC[232] = 0x29fadaaf58ba4e0d3055027b9b67ff20f044b21b49aabe265a1a83afb6e66272;
			gammaABC[233] = 0x2feabccac5b3f01ddba6ddf3cc482d187cc55c3fe922f57fd0448e5d50e2fe75;
			gammaABC[234] = 0xfc88334abc0b963aa268bea4d01351bac17f34dc13a940ad74b7552d35fa504;
			gammaABC[235] = 0x2c0124e09de08ad384cc99771580f1996778ad9da5ad58badcb310d2e9990224;
			gammaABC[236] = 0x28ddacb184cb22a52a224416bba4fc07a463bbd7821d36a2da90e1fb2d8bc2b;
			gammaABC[237] = 0x1efa239341a602f5fc6c1c819a066c8c233dff1bb6325873fa3a041f919155ff;
			gammaABC[238] = 0x2c800c7f3b0f11470dd5ee49c74abf0af3338173ce1ff0e4782ccf94a4ca5b74;
			gammaABC[239] = 0x117ddc6675f533bdc0547613a579a995e0fc2402cbf2b6cbdf60834ccbf476e9;
			gammaABC[240] = 0x2a52eeaa086a2b340c34f10564afd890b7bbe0a12c103f989f547539a0c21885;
			gammaABC[241] = 0x2397eb077dc739d9b34443e7fabebbda6d6f88bad7e02d4fe193a42bbda5bb2a;
			gammaABC[242] = 0x2dedf2a62043796c5394763bf0916e4386244dd12dbd531deb93dae8366272a7;
			gammaABC[243] = 0x2e76f87f7b4597feff6581225beaf03687fd71774f1d314df0ef10ac079878bf;
			gammaABC[244] = 0x1aebca041bac11cebeb4ca9302f5b0d8e7bb8ba1e12a5021aa8c514d51ac3e24;
			gammaABC[245] = 0x2b26789758100f51ebd004dd15da40182a6caa57941945cc84d46e9cdde6ce21;
			gammaABC[246] = 0x1e5c96a7257c2f9efc1900bdfe4c4ca192f41002718ab6938cf6ac235ed3a8db;
			gammaABC[247] = 0x2244a0ad56ec3277a984c69ff792902e8393d1fd741933bf0e58ca5786f1d7cc;
			gammaABC[248] = 0x2f008fe481bd93baf3986e94339086a4ac5c973dc07a6618876bd1ae6b3f5103;
			gammaABC[249] = 0x1e55bf3fcac9ac7ae22e20246a483bbe3b6970835f68cb2a662d49f09714eca5;
			gammaABC[250] = 0x23a9e512bf7f768354ac7bcc68b97aa5e36907e91c3ccbaa45c13e4fbafd4972;
			gammaABC[251] = 0x2f2f3d30bb245ea5b17ac183fa30a69e949446a4c156af4d32ad9611d7c228e7;
			gammaABC[252] = 0x26e0138c476e426feb782f125be2b881b6e514d40309ef9e20713373c9f53fa8;
			gammaABC[253] = 0x15a7c3f1e09db3e83fb8966fd674b245e927ec9bc1a9785cfc7e40aabe287d9f;
			gammaABC[254] = 0xaf12f2f4520de6feada7e1512bdf592f3e46528f53f3b53d9772461fedf39de;
			gammaABC[255] = 0x260f2648974c848cb4b853b7ebdf6fc0e1c05e37b5d66f6c851ee4ce0e3f480c;
			gammaABC[256] = 0x2aabe05ca66775fcfe44e6694f00ac9bb88f564c304bb199790aff19d08ad3a;
			gammaABC[257] = 0x27d232ef889352ff418e0bafea82920e86eb3d924b942af57aded18ce5f5e84b;
			gammaABC[258] = 0x221780caa450a9a94d5286323a00daa0b986a88f57345534020cec4fa545ae3d;
			gammaABC[259] = 0x1ede376e66eec4981f4965fd91f80db4c57d286e0976101dcb064fd5a405dfa7;
			gammaABC[260] = 0x19d1827d2205ff28ec22372898dfacc43177f8882ad613f3bda2403015826c2d;
			gammaABC[261] = 0x18a15ec7714767646b4952cf28341bd9412cfdc9fd70693304f26610914f0aa6;
			gammaABC[262] = 0x7fea8c3bf782e12d2674766afc11f5656d94840826022dee8de596aa311e26a;
			gammaABC[263] = 0x17476be04076c6d080d6757bf5402b4809daa39a529192ad25a11267606d4a68;
			gammaABC[264] = 0x2b025eea71f9ab16dc7a826a5a328291cdef78c4337677460e85a7467e14e314;
			gammaABC[265] = 0xf86793adc3a374c0d00356e6f1dcf4867a5568f100bf81739900a2f4ffccad6;
			gammaABC[266] = 0x84e59ce6141146fcef10cf6c2404236a7c2e30b70cf927211da8f594473813f;
			gammaABC[267] = 0x45b4cff4b59210c1e357f513b8401230f298ca69ca0c29251847c5c96c6b542;
			gammaABC[268] = 0x19954890255c75bbe869380184ec420f9b9f9af6895b4bf9e80a29a7a85f7d0;
			gammaABC[269] = 0x2d3fa5f46469b41ea4604896f5c1cf49794c222d59f679a66e01b37c6afc701d;
			gammaABC[270] = 0x188ec3e8beb4630fce9a0299d50028205d945b1f72ea9595a9a15d6d95becf4;
			gammaABC[271] = 0x461a86e9a4eab571142a63832d496a4d7fd6bd00980066a893aa0448b0322c;
			gammaABC[272] = 0x2b8604367fb761520db12351bb0a8e7c7c3e32391d5ea0e586f5b949c6307e15;
			gammaABC[273] = 0x189b52a5654a3f99118f0527c0b4afe5b2c433cf9fe8fe0a4fdad68a4899cef0;
			gammaABC[274] = 0x155b929bccd5c580e074f8312f93863f9abe1936c2b4dc9e8be27f7db4477231;
			gammaABC[275] = 0xb550420db0531efe497881c7058952554a09fc8e91780fd1b7ff65f7722e2f3;
			gammaABC[276] = 0x10d57c99cc14df0061dbddbec8521181e1f9d61815f79778ccf076443619ac5e;
			gammaABC[277] = 0xe012e8495a3270dc96c47ca23fb9b4da183f93abfe1e234f44835acbce4cbf0;
			gammaABC[278] = 0x1bd8666f17a68efb8915e8fc8b76fa16826c22c177a400c6bffdbfa2e1e44206;
			gammaABC[279] = 0x1631adf449e7529ce12bb105fd60dec9ec4eaafc2882e272d3fb864ea281d278;
			gammaABC[280] = 0xb1bda2fddc61d18f397eaa6eb5a4a2f1e3bf9909a92445af2f76482013a250e;
			gammaABC[281] = 0x46df82613e3f01f3257f410c2a7b616783c385e2501a48c9d082874d1ff108a;
			gammaABC[282] = 0x14a7a3b933f4a320dc73711d655944f4caf1187e59fa9cc99b86079db74e8f5c;
			gammaABC[283] = 0x169bf0822b492c412d1ed61143341d19653837ed13d8147dc5a1a7153720d39;
			gammaABC[284] = 0x1b378513431eabe74b3552e6d6d1528aa49315071d30e0aee701e9bf36315f6a;
			gammaABC[285] = 0x115c44498fa2a71642e77fc79779504d1acb5017c17362adc72d869c42657eee;
			gammaABC[286] = 0x23bc256738e5bfa6f555a3187b1eed146e0a161732cfb8546b4ae0a0ed34e6a8;
			gammaABC[287] = 0x2f934ef9e78c366cdd76c17a9eab68216ce3cfa3840c4bafc59ef9c7f932ca40;
			gammaABC[288] = 0x23d930d3c13a3ca05dcbb8877f8b9b61fa5e0f3ad1ed9be0a7c83e720bd26c77;
			gammaABC[289] = 0x7b5bd152386fe85955aa2dabccba641bde9bae67ff199e1323fa0e36cb42fec;
			gammaABC[290] = 0x162bcc634a66c448092d2dc9a548d8a40b88a0d1fd13b301a206a03f505e97f4;
			gammaABC[291] = 0x1bd7cce22a7c894522634c822a5112f3419590d83cefeb137be61089c88aebbc;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierFinalize32
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
    
        function VerifyFinalize32 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x142557dcc7c3b69f8bfe6cfbe9fe393affd3abfadbd32286c2fa4903a1f53232,0xc73fe4e781dc96d6a7ceb09804696af97460626fdd8011aa562c52f8326ef0c,0x2b650b0f20848722332d4f4eca4ab2eede03a46577a4065c9f9f5bdfd4231a,0x1e0dff7abb8dc5cf6fdd8eb6a855b0d17c1561f4568c36f8aa1ff9105af7232a,0x1c7704e60072c6481986391cba3cf96b80e259a5802707454b9b49923f4bbbcd,0x249e25902126e3ccc83e9a117225304f339ecbaebb8f96dc5009f427493979e6,0xe7514314b81550f6b5ff037fd5ee0dfeb07af7786b9c7cd00a83afa62c1ef78,0x5d00242d780c46ec35a663b7407705a905e1b7f936d1b334d76a1a1a746dd96,0x17f9837b985d9d23539989ca6e0e871961e7da8050982725fa3816db6f1c05b6,0x1e51e8f148c44497668884cbd77ce0c5866be021083b4d69cb339a06e36590c0,0x16026050dc1220b82a9fa348a8b1047eeb3e0743d26cef02c7f6d82df4ec5130,0x26b489ac9df7a0f336874d981c284670e98bb6d32fcf531572257c2046bf99cd,0x1473eba74372cd4326721ecfde05113f1b5e7c7d30a8bfdd00ca87d056caf163,0x151a456d24362733a743b8c24c46960f2eef9c6e40e4bfc162d5e4d82041ad7e];
    
            uint256[] memory gammaABC = new uint[](580);
    
    
			gammaABC[0] = 0x2b3215b958e08ecd7216f033e32e6c0cb33ab002d6f32bc3285543de01f6f77;
			gammaABC[1] = 0x186aa74d1a3a54eb36e076ca9ec27894dc0cec0b57333c5a0230e00979ac6f13;
			gammaABC[2] = 0x267bd7feb5805490496d7a0e6561614b310b86e5d2cd7268c11f89bc75d671db;
			gammaABC[3] = 0x1134bbf3ab6c0775edc5c204b93c18207471fef270d2ea5c0059fa8818d22b8e;
			gammaABC[4] = 0xcbdd6db9f88d359ca6aef090f9fde08a8cbbfc027d9cb86ff8765dbc595c15b;
			gammaABC[5] = 0x52190d09f0dde588c74f7e3e71da26d371b113af414f0cd7dfb5eecdec0df33;
			gammaABC[6] = 0x98a836067e1347ed0690710052c893e7c4ee21943f8b96ac01137a0c712274a;
			gammaABC[7] = 0x25a996504faa16984ea61961cffa286770f3121037a80a09f25c473a87f4d250;
			gammaABC[8] = 0x20201ee39c9556190ebe774d544e8d017d8fdb6e6ef39b18efad6096df241d9;
			gammaABC[9] = 0x289babf0372fc5cd213da4869f79f3d875fc9a0c24d644c44015a86d7521af2c;
			gammaABC[10] = 0x934520514e7d810fdca5d7f1c5053c9e78c95dd511b6384b2fb026020887c45;
			gammaABC[11] = 0x1c463c8844be581f58d9bf708a5f2a33ade5537d3e5db47c2bfc810da45f6dd9;
			gammaABC[12] = 0x26494bd52796d2f311dd097477f568da350455657e6692c779ab3a655f10adae;
			gammaABC[13] = 0x218bc5f278bac4425eb3da22a4b639c0d43b4ea596a07f63f8e083cd4c3fa70a;
			gammaABC[14] = 0x30c281dfd550fcbffd78e91c56e8522fff851cb5426a709ee169175335d4143;
			gammaABC[15] = 0x824c8798de71352c7ab71fcd0214b2f5a57a3f097ada8d2a9ed7b83e014a818;
			gammaABC[16] = 0x21aad580cf4089f204491ebd452baa1e35523557eb08d1022f02fa5956bae4ba;
			gammaABC[17] = 0x25c1cd5c571726d663323b50068d6a8ed6c15914a8a816940ef4df3799656e7c;
			gammaABC[18] = 0x9648d7ef4ec2cd649c2964402eebcb11fd839c398348ac31917b138053b79f2;
			gammaABC[19] = 0x1d2d4ba15ec695134a0951e348b021d0a42fda264cdabca36387bdeb116e68c6;
			gammaABC[20] = 0x2e6f196466e63e165891839e13af7928fd0a953dc9087a42de865d89db6784df;
			gammaABC[21] = 0x77c0898ba7d78fdf4a2a3346ba8d9b4d90e5f0a5d3ba66655e5388504837048;
			gammaABC[22] = 0x65a78e127ed60eb70ede9f2fcc868e18cdc77da529cba8ab8617559f48499ad;
			gammaABC[23] = 0x22b58784ef1ca26c77463c5a6f46683a4a2e8b29d1969bc7c10e903b1bf326b0;
			gammaABC[24] = 0xd96b28f0dc385e2798256419a979948d400c343897d2abd889055db44c769a8;
			gammaABC[25] = 0x247b4e2b40f2903f59b818f18d9aa2bb7f3d895538548fd596f148cf0fabdabe;
			gammaABC[26] = 0x77a7f852a629d06d727da6dce08b374cf521e3301d4736a860c3722f2fa69a5;
			gammaABC[27] = 0x393663dabb55c8643273046b275e8ccc9bce45ac76b10c7dc30f972c1a4cdb9;
			gammaABC[28] = 0x2427624ef58898ddaefd312b7d4e8826e80026f28e7f7633d2c5bab87e2fd9f0;
			gammaABC[29] = 0xc41b6b6b6dac8a71f9ab99cf2edf00b58321bc489a1f730b73ae049faeee567;
			gammaABC[30] = 0x1908493965dd700deb083e2c37015d9ea3a850130d860a5ee7a873a97d655628;
			gammaABC[31] = 0x2994de1ef1968d94fd9576634b3938f59c852b07b75d373ea5c6e2442a371cd9;
			gammaABC[32] = 0x2a0ca35126fb36a3d3bd7afae93c77192a995ba4a40c21bce33fe134d856d69f;
			gammaABC[33] = 0xcba07abf8d97284ff255022f1dd559f474a772dc297d0565d1770540713948a;
			gammaABC[34] = 0xcaffef90f35f5ff228d483d1dd9eaed657861fe89ec14f32c8bdd24cfd2d816;
			gammaABC[35] = 0xaf86dd57b1dd820718f1ab427b173dce029e1c2d019b3f4cef8cf714869f08c;
			gammaABC[36] = 0xcffa24e8f43515684558da3f654fdc0d13a1eac3b24e71bada49bff4568e67a;
			gammaABC[37] = 0x1e07d1a320940ee62bf98a92540845816258cae6543c76087362618e232a0c94;
			gammaABC[38] = 0x583830107bbf31e530d76a9007fa390048aa23cf3f1638ce4a8a856b017972c;
			gammaABC[39] = 0x17c410f2feebcbe99e7ec38cce092ce26f11ea801be2d7664c90a6097140fffa;
			gammaABC[40] = 0x17f09dc3d10014cff8a6f9951659114db1c4caebd40b73c109f5b1a44b522886;
			gammaABC[41] = 0xb57700557457cefdfb68531abf1082017b5e53b7bf684b10f0003bf19e7b005;
			gammaABC[42] = 0x2b8624d9867b82644fafa7a55938f32bdcddc7e5519fbab4c35ceade84456b56;
			gammaABC[43] = 0x455f4f5b55dc832ca39e54b810311290d643c94bff774df5bb856f27aa30614;
			gammaABC[44] = 0x106f9e7b4fdaacf2aae297e8da67a661da14eb2a6445e6a3430b3aa76da43577;
			gammaABC[45] = 0x2263b1262a6209e9aa4dac2e8cb078fbefc3543bf5dcc35a02bded06218c1bee;
			gammaABC[46] = 0x1bcf635f898b1b08637ed269a90236ea6bc634587d6e7e60686a203963af9909;
			gammaABC[47] = 0x15e3a0f8ac5e29a48a7ebf6ed63c10698d312c2425d1e51a5afdb104e31f9a28;
			gammaABC[48] = 0x73971f76245875bb538d8575164381d14681d78a931f2857118d559dd6bd6f7;
			gammaABC[49] = 0x2b0b27e34ebd339a1c0e26beca0f78ce63cdc76baafed75adf171ecddcdad4b1;
			gammaABC[50] = 0x124e01089b9eb030d2d09d906f8934633e080d3f33c12dfa6bbe021078300806;
			gammaABC[51] = 0x29b059dedabeddeb1a31843b32cac67f90f30452c1161a09e97bdb2361668624;
			gammaABC[52] = 0x93dbf7c6f027e5ce426d74e9131456d54a0fb694c42dc3c4ab79e900ca78977;
			gammaABC[53] = 0x2a63951a7329b076d2e33f96cd06206df0460461fab96255c33e09cabdac6cd6;
			gammaABC[54] = 0x2f8d78f1b6fc004488e58e5901a62eee030419a28fd690117d12a00fd662778;
			gammaABC[55] = 0x187c0f168c3b447d59a557c93185c4553664f63f9fa4474b102efc1e9df10d4b;
			gammaABC[56] = 0x13f0816bf0e4b8f1a85acff17acd8bf2900a1514113b9751a4603963007cd3be;
			gammaABC[57] = 0x8b09255682b4d2202f2fd9a04bce90039ca4a674f313a34027e12bb9980e524;
			gammaABC[58] = 0x1dd1a85af8a1d465ddb45d89922e96badde2375511357e4e8c65f7f7f7a912b2;
			gammaABC[59] = 0x29cda45b5b448d170e347040a556872367bf4ac4a69130e9942a6eab53580a06;
			gammaABC[60] = 0x20e9eba1e381a1278d01d2e61d1a964d458dae961d2964001852a8ff70137634;
			gammaABC[61] = 0x1122d5393c60d93c23534b6b90d52f90e8e090a34b0338367ec951ca0d5d568d;
			gammaABC[62] = 0x17355870dbe135ba82dff9af43608ebab71595a78fffacc7c4f63438e1508e2e;
			gammaABC[63] = 0x217f9b5308ed5dd3eb45fd4e9d6c5d6823bc146234c8694c1f79bfbd0803e47d;
			gammaABC[64] = 0x38f8c460a53f2cee668a9eccafc5389971afe7180e8f2ee3f2372b36d61baa3;
			gammaABC[65] = 0x12c1b34af27a965e8f6d80a9fb482f298bb8afba72ee9cba1435838273ce5b9e;
			gammaABC[66] = 0x1e69e917d3dac267b063a6ca4f88ef9ef2f65a822319c625021083317a20cb1b;
			gammaABC[67] = 0x2e24a75baf0badfae1fc8bc98cb565a0a06011206dc1c32043a464acb854abab;
			gammaABC[68] = 0xc9e4eb63d8a6302e8783ee060131a74beb8410cfa3e5341a34797534eac3bce;
			gammaABC[69] = 0x9bc974810ee4029bf991d860c5bce5aee93551a1fc470cbd358f2597b7456b;
			gammaABC[70] = 0x15b87b0eae54ff9e773a0995568f8ecf1535fd098b1e56eb6c395a41fd49afc6;
			gammaABC[71] = 0x77f8b1c24c0d29fb9ad0e55c73f12f2c23f04deced1d74ab96e8e067ff9fe3c;
			gammaABC[72] = 0x10fc26bd5db9d5d05e037f16389458e16e95e8b185200bdd6d891cbd99607bf;
			gammaABC[73] = 0x1f3a61ab4580e121f08f386344fb82b1e1c8ddebcffd40f9bfd740cc44102b4a;
			gammaABC[74] = 0x145e57795faa3a1feed2409494c76b90fa169c4cb767bdbd7736738d645ad492;
			gammaABC[75] = 0x1d32d9146672d097cc9678d8926bf64d77075f9110730dce33bf419eb268c64c;
			gammaABC[76] = 0x1356b2fffd93f81e5b772d916565b3d6ff54947fcc51f70fe717a53ba091ad63;
			gammaABC[77] = 0x25372f2d34045206ee07e8205d8221e09b15380113287145e217f5f21daec2f2;
			gammaABC[78] = 0x1f8ca420d0171158f5b8446e1af05e4f1a2cb1da099d0a4c27da5e3bbd85c67b;
			gammaABC[79] = 0x1b36d30c0372d8b5b99e9e79bdbbe26138e2f2580ae1f44f1bea1823cc438ff1;
			gammaABC[80] = 0x822683cd7d4f4c366a7f6fb96a4b6831d2499a586b2567f4d52bdc2b8ae92e;
			gammaABC[81] = 0x25f8a35c2ae7403ab6835fe115e52a82fa1adba6ea658facd50562af13850c40;
			gammaABC[82] = 0x300caa07bab9e2b117834e974297a27136920532238feb401c8439156ba9c34c;
			gammaABC[83] = 0xdce2cb3296b127f7c972c92b965600db3f3b1c9c6f388bbba2b2705881fe49a;
			gammaABC[84] = 0x161e3e49153fb01a58d05cebe9f4f15425b408254ac3c4597a6a235fa1968df8;
			gammaABC[85] = 0xd6674f1a8d52d846aa4e4263e686a1c14a3e04a78178b440a20a557cd16dc62;
			gammaABC[86] = 0x1fef0a96b4f946e1a0c120b1db3faae6dcd89917986092b357f627c48f70b503;
			gammaABC[87] = 0xd1161357cd5d81b7b0abf0c44a3251395394b1d04301b2a53f1984ee9f273bc;
			gammaABC[88] = 0x26dd62316baf0a59d4d13db525099a2bcdb4e7fdcbc07f83b99688e836298d06;
			gammaABC[89] = 0x1a351a85b40f264530f8b97982e687d874a44ad8e4d8e62565985ee3736bb60c;
			gammaABC[90] = 0x25f2e50a480ff7637dd5f9304893e0704eb533af75ae9d697f10d31ccdf15c62;
			gammaABC[91] = 0x27e4f110bdd438cd96532898e5a97207e762736257822dca206ee73d965e402c;
			gammaABC[92] = 0xaaafa47a157e5491ec37a6c0990ff3166a7672332937cf9a4692a6767bcdbc4;
			gammaABC[93] = 0x12011c7bf77a651479246b89a50fa1c3ca074e5badb4d21fd05c9e3f04ad845c;
			gammaABC[94] = 0x25aed9d3b4167c7c9c9d7bf431eaa6255ed25f7ff9f11f9af2c2c50566a0f97c;
			gammaABC[95] = 0x118323849b86e6d3ee583e4324bb461ddab592a4cd082a36ebe8178a871b1363;
			gammaABC[96] = 0x2cd90325d8a0a2a921c85519e8c5c383990497a480221f9a523a0cb0800b006b;
			gammaABC[97] = 0x2e7f27a57ee01020799f8be37c3ee7a15d7afbff4356dd8b57201d20f3685288;
			gammaABC[98] = 0x2856ab388dde278adc728e2363184f6d91f883632527deff9fbeffce75c3344c;
			gammaABC[99] = 0x1e06dce8b825d57dcdcc6088cc816e8c01a8a739b58cf966d0a7170c6bab07ce;
			gammaABC[100] = 0x8042dffe3d9a0f500ff9d41186a536eb1971bab4d6755cc2dfa78a71a76916f;
			gammaABC[101] = 0x2f5a732b1d2e946d52c2603a07c3ce017992d0c2ddc97392be44ab2157b3248f;
			gammaABC[102] = 0x1857d49488ddfdb07f73ae3d9a3282775a5bc4d4355f37e87bfe3c7c6f051021;
			gammaABC[103] = 0x2ad94aa567aea03ccfe16a2d4b50697c498f5ca53dd627f314c09006d9e46b50;
			gammaABC[104] = 0x1ff5f2282819825f3eead2f812abec6d9a3c3a907d9e04d1b3ef543f153c1e82;
			gammaABC[105] = 0x11a70708c243ae0048717959f3138c97d0b7fa9647f8278da3d966dfbc16f745;
			gammaABC[106] = 0x2d57ff75dc10818c2649d8d5f2165249e642ba7d7b9b1f1f125d9b090c204054;
			gammaABC[107] = 0x15c92d5831d4dd7b1aa74e9f75cc183f6d8f087832a5bd9c7c780f31451f59cc;
			gammaABC[108] = 0x164cbf0343eecb76b311e1ccb461130c4742bd781dc2cf1803afb2528b6ee522;
			gammaABC[109] = 0x8fdd34b8a857bcf23a70da607e6ec349d92467c04a468b6feb83c5054f3d94c;
			gammaABC[110] = 0xdfbe7b376173e6ea68332f5d6be72469265079410d2b21c87588946790cdf98;
			gammaABC[111] = 0xb5761f6f424aacee05853cfa091d4dd83cad29d5c4d69ffd897e4bc929ee3e0;
			gammaABC[112] = 0x2b816323f5a0ff672bcc83a963ff809f871166641e39e7f769f4e71cf860d725;
			gammaABC[113] = 0x1fb64cef9e4282f521e35e90408d98da6afe45b6ead48bb1acbf97cd9d0531a9;
			gammaABC[114] = 0x1890790f1c52958376cf4af460b032669e8405295a2e7bc731361f24d29bfd5a;
			gammaABC[115] = 0xf34c42d8dbbf76eb6919a88b4e0b7b6432782612e7507f85211d4eba2751d8b;
			gammaABC[116] = 0xab65f7bf33817171ba22f3dd2e4578e511f6c1401d70019541be9919193211e;
			gammaABC[117] = 0x229ed35d63859c4a2c21dfa1c6835e262f512720ffb52b1444f4b0312d0808da;
			gammaABC[118] = 0x2a5b9bb59da2ad23b6df09c6ebb92cb1a1e2b8fbeca2e0065c103bb625aad7f5;
			gammaABC[119] = 0x258617b003c1021fb4be270b0cda16a3029d08aca2b7a0bcdd028fec89b977be;
			gammaABC[120] = 0xa4a94b02ffbf797a4eadb392a85d6c838ee996f861e524f590f3e6bcf7df2be;
			gammaABC[121] = 0x2f6b9b2ba91171b71e266ad8a831aaa6ae27c0225fa6fe16eb910ade71a7011a;
			gammaABC[122] = 0x25f6821adf195a5ab042964761ae17302dee899bcd119bc2b6704324efc003e8;
			gammaABC[123] = 0x1d9d62926cde94aaa95513198deac7f73d34800f2ce914f5348eefd94387ac21;
			gammaABC[124] = 0x10c148e55cb76121f388cf8f221c14136fd2b62fc3dcd77eed52ecdfa167d146;
			gammaABC[125] = 0x23475d0c2318eafc3ff95b9871cd1878f29555e0d8fa3695cf345638308acc97;
			gammaABC[126] = 0x2dd8d24fd6cbaf3934f64d839ce31ebf03ae123f7dafe2a53a8fc65bb8101038;
			gammaABC[127] = 0x2cf69120de4e543512f2c6bc3e9862c0272b0ea704c155a472ef7f40a3ff09d1;
			gammaABC[128] = 0x10f91be60644f8d8c44676c0bacb05194a335d457a4fa96ce54fa5554b1ae400;
			gammaABC[129] = 0x25346e808de95345561643995927c68b126c34ddd12f43f1653363a975455cab;
			gammaABC[130] = 0x24ea5acd8249aae3b95b2e5da1411880e63af5aa18b487b9a907d64e7dd6b9ba;
			gammaABC[131] = 0x9d9e9859873c7a27cb3fcb31d8564cadc0f697565506108c13f74aaac5db88c;
			gammaABC[132] = 0x96d2e9df95d4728b0a6f01d2294bffe3e64f751b7e9417da0eed1bb00e226da;
			gammaABC[133] = 0x21cc1c26d70cb3a6960295da6852e7e2dae5de86aad5b7559a7351ac3cc8fcbb;
			gammaABC[134] = 0x1161dac126af391da62b40235416a30aa6c95e9cb4f8393f57246199e5f9c083;
			gammaABC[135] = 0x1d98eab173cf4507769515fa2a916103fd62295f5affaab0a96018a81b3fff80;
			gammaABC[136] = 0x7def90cf83a61a22440b21427e2d4ef56e9069d74d97842e52a58a3d119d109;
			gammaABC[137] = 0x8269d80710f1915b89e54c8acfe68996a9721424d17fc344327842b54046616;
			gammaABC[138] = 0xe2a752108aa4f5ac2910cd0c8ac20c4824d07278c8ea9432cbc1c4e6cb96e4a;
			gammaABC[139] = 0x20299641aeb0eca73c4664ec24e53b48e955aa41f7313d0e389f5c85d7802078;
			gammaABC[140] = 0x14bb8326359f5872105f76194414ebbe615926890c33131d82beebf239aaf825;
			gammaABC[141] = 0x230ce98681400296deb0515375dcfb7a79fa6d93f1c1849382e0a5092dcaf6fc;
			gammaABC[142] = 0x2e942b1dc6b28438ec34289e17ef1b5b401fe9a4f74897406dc8b36bf0c738e2;
			gammaABC[143] = 0x28c0e0f8d2af62a69a63d432e3afa0c9e1d7755d90e4a9a21c0ff972545058ab;
			gammaABC[144] = 0x86ad76ee2c1dcb57cc25dc1d8d3a0d5bd7f303849256497acf45d4130c6db0b;
			gammaABC[145] = 0xcaedf8bbc6837250bebd7cf335f92e0e801c0c679cf1c927db7946b555862f;
			gammaABC[146] = 0x2b301107eb5e94be7b7406f0ae3dfdb6e79f8c958337594b1b29e02c03cc6e13;
			gammaABC[147] = 0x66932e8392ed782399efc91076079d1791c75acc991b7de83d8e5154d5ad4cc;
			gammaABC[148] = 0x943e74fdf644bffba08d386b11d9cfb2ec0b9983daacd760326f43db621ff80;
			gammaABC[149] = 0x1e06bf5681bf101eebda7a0bdb72281849f402276c4b24830ab3d6b3af8100a9;
			gammaABC[150] = 0x1cf46831049ef5d4a232009f92217515b577f744312d0b9fa81a944287a04add;
			gammaABC[151] = 0xe6f82334d64420c63fefe6b0ccebfcb2aada9c640eeba8893906a66979d95c8;
			gammaABC[152] = 0x11a9a56a7308565fa5e2e7c806fd551a9693277e82569028e9c28a0729ed9a19;
			gammaABC[153] = 0x2ceb4feef816337279d6d18a16aa345b5c915c5474bcdec4ae31086805ef205;
			gammaABC[154] = 0x93b1ca41c2f598230f8bd4dfdd9f7f3a4ed3f2533648451171b456df8656800;
			gammaABC[155] = 0x29ad53312201bf747f1b6d8e2abfb1bfa22ebaa55b3d5caaedce4e143b62bb3c;
			gammaABC[156] = 0x21b12de766fb402b5885e5ab78df23a97a6f9aac8b8253c8e10140dd6543c1fe;
			gammaABC[157] = 0x1dacd10f19ec4196903a3c3526b025735a693535f8e05fb24a5e162b685e4678;
			gammaABC[158] = 0x14f8deff4d5f55e18e35b3d921fb2cfee222451b677e4974ec3f6e45d26931e3;
			gammaABC[159] = 0x106076abde193032cbaec9c03801defdf9a63c554fe9f61657d3c6a5c8a5a272;
			gammaABC[160] = 0x390b01bc9680bb203f3a8342b655bd3a61e2af091797f957c33542771d99dba;
			gammaABC[161] = 0xfbcd983b756c2a9420b7376a31b8d4e1abdfa7e5a12aacb768aac05b8f57f96;
			gammaABC[162] = 0x3a47a39cd29978c682a5879f8fb48432a5db5ca83e7040ed4e5989557bac58f;
			gammaABC[163] = 0x14fcd72598ed428301852b6cb357b1b01cfbc52fca5526279ec572d30e3b81e9;
			gammaABC[164] = 0x5adad9289edd6d6edb897af1d5e1cd1705536e6fb19987ec43306f0615f8c47;
			gammaABC[165] = 0x10f203da7de54bc51ac175a3cf560c1eace13032e56f86f6926133139d874d6d;
			gammaABC[166] = 0x9c23f7e8d4b3dc86573c8653f857a3d594952912faa73387b949090a19b49e2;
			gammaABC[167] = 0x13c7f820f7a24e856b9436a3da29869d57d3030b773d3f2ee2862f31bd58c314;
			gammaABC[168] = 0x15bdd678cdf6b59589bb3ff414df3db55b3ed6948ee09a152ebd012265af421d;
			gammaABC[169] = 0x266e1d67d2919d3bfb261b666d921a92ad83370d334375d6d83ec07d5869db57;
			gammaABC[170] = 0x2fd932b21122063de75e09e7760948ad8b3e6ad645b638458c44a760e1a0ab3b;
			gammaABC[171] = 0x28b6cce2acb95489808f510b0eeb73a621602c9b638e57fd357ddd5d5da89994;
			gammaABC[172] = 0x3e8eefba52acf389a2f7009620fa4dc5ec7a823e1f7f7f3b9cf3a35c93783c1;
			gammaABC[173] = 0x1fcab81158670f8cc8a6b2ae0afbfe881878088788a04b19ad62f13dbf1606bf;
			gammaABC[174] = 0x2cf2a424f61deda8874d689c3bbf9c42b740a49af591c14466714a8e0b04c959;
			gammaABC[175] = 0xb37458db46d166f27eebb29d9ab16d70a253d6125a05f0a79a419343ab6d2ab;
			gammaABC[176] = 0x12a50f666779fb7e8dc1782ddc49ac39c104aef95affaa4970db08ef2a9841b2;
			gammaABC[177] = 0x29bbbe1fe0c03c9d27a493a2e1203c332e8ac7a6a343659ea2e468837d6665ad;
			gammaABC[178] = 0x1abde95bb2c57b30d87e22002a49002bc082a1308ba815dc175dde4c9b8b4a3f;
			gammaABC[179] = 0x188511479b66c8ac2317b56762cbb6b5427008e7d8889f643b132cd7e5337c0f;
			gammaABC[180] = 0x1ba2689c337203d0c90a1ff54eb24b251902d02a1e62162b1efea54a240f043;
			gammaABC[181] = 0xcdcd5c5408710a916540a300dd37ca6c6d15ed62b99db0bbf1ff71388ea046a;
			gammaABC[182] = 0x1d8e8b36d11b3617bc0992d193d8bcd6658454bfd5753ea59cd1a2d45b6b38bb;
			gammaABC[183] = 0x27892b0b7f4ba2487dc576be35caf6a2e4fb704ece97bc4cac79e25d6572b77e;
			gammaABC[184] = 0x1b1f7c2a0df2b9430fb6f8c69468883a76fcc26b8171f579b28f38991670411;
			gammaABC[185] = 0x2b4f0b51dbfb151dc3c43d9e404a55e50072bf6dc83c576ffac7a614a32109cd;
			gammaABC[186] = 0x208ae9a101cd551e10631b597aafdc31de5d4312c70b0f36945ad599551b55c8;
			gammaABC[187] = 0x2cd152e65a93eae494bf2ddd58ca95da961a6c25292df9c09caf76ce2523e016;
			gammaABC[188] = 0x7675c11b1fcb41fa4a821fb0e8d24206a422d7c1480c7228ffef1c46fdb92b0;
			gammaABC[189] = 0x318e5ab0d811a2e01f1321c8acb7885c0398ff8dff142980ad9eaaac55f3fb1;
			gammaABC[190] = 0x2784e181dc46e3f145cca80ca35afd5beab19500bd46e96c8ec4cfa4f9384e08;
			gammaABC[191] = 0x20ec7bdf705559020f4799ad58304648badcb24c4e6dc1585d08d5471c97c84d;
			gammaABC[192] = 0x1d09bbe8d72f8ab670c1ea731d70e33565749acb8104031edff47fec09819ed5;
			gammaABC[193] = 0x1274387a08b9873a0bdbd7a9c9ea2b633f0626f12d85778353ad3e9690cc82f2;
			gammaABC[194] = 0x585bb74aa55727fc3c5119e48730cff2e520e78031d793ad48036cde8ef9b0a;
			gammaABC[195] = 0x141427825c0118e8f893babdd0f85af2e0dd3eb546a05912522df96d64ae2a86;
			gammaABC[196] = 0x1e054c216c5bcbf25991fad43223743c43c5c9d010d46183d25df639a24c0280;
			gammaABC[197] = 0x245d2536f6199d1372966fe617c26bbc7bed743eff72bc1409da283e6068f28f;
			gammaABC[198] = 0x19ee5c66f000207765d60f558de6d4a094d94abee37fbe5a545df97a258ccfef;
			gammaABC[199] = 0xfb8a72bd6883ec85defa19f47a7929c97379d61f8c590222c59af4f10ae7b1d;
			gammaABC[200] = 0x2554511cc2f169bb36c1180d6112b63227b70f902999ab11b83cfbb108dfe272;
			gammaABC[201] = 0x10ed982660947707c754f4dde8e26f0a3bf3dbe51166bbe7bf667b5ab3fd85aa;
			gammaABC[202] = 0x281199e9068e42d538ddefadb5e3f01293532dab42f1b64f812e55c8d1143a14;
			gammaABC[203] = 0x28e4a5d785f07ecd009144b03324fa4b6574b1443bf31a29874e6e4204ed65c8;
			gammaABC[204] = 0xb9095ca84eebb567a658e036b804c52d1993fc8cf742b4f9f85b5452f121b6a;
			gammaABC[205] = 0x11deff3c21ab94ad0e95558e90c4697c3aa94f4bda4ac29e6cd6836fe5e0279b;
			gammaABC[206] = 0x153af2f8dc931c516b8b7b339f0f562dc036d97a71b89977249ebd02a2d3011d;
			gammaABC[207] = 0xfa4a1478b0b0b805afeee4e87e835567c61047b42f72d7fb79d8bc4e92a048d;
			gammaABC[208] = 0x1a34cdcbdea02a722c5fd7a8b6d0541c09d288114ae1cdf51904761605496267;
			gammaABC[209] = 0x2d31424dba05b64b9a649cea35c9b65524077f91539b9bc0b0abb3281682fc75;
			gammaABC[210] = 0x425f44f390d17e84cffedc2ea4fafe3d5b3baa6e14495cc1b10197aadd76d46;
			gammaABC[211] = 0x2f30fcda63f12eea78fe924afdee4dbf8707f2ae2d73afe831cc72a81c34d76b;
			gammaABC[212] = 0x8995d5d0eb6537edb185977508823776e3e2c79146a6de218f69b6cf4a4af69;
			gammaABC[213] = 0x27acfb9be90fc1a30abfa57281474f41816812d6dc3b14d2877deb712278c23b;
			gammaABC[214] = 0x29e813a09fcf24513119841e612928021f4b1638177d348ed4318af6056b8212;
			gammaABC[215] = 0x25532279cd0e2fdc3906f202481c440ea4c55c06b5e85e0fb55b1aa2e6be8de0;
			gammaABC[216] = 0x75293c1971604b474ba53a89bf8c552efd37a2a3c9580f02e25e7cb8cf34c38;
			gammaABC[217] = 0x4aeb43dcf1989a9ccaa5cbe6effff7af524ed4ef1457f5d211d96c03cd05813;
			gammaABC[218] = 0x103fd652b2ca4eeffba2e49ea8c12926d87192d01e366838ae3736d2343f8cd2;
			gammaABC[219] = 0x19f9603d4e6f722a6b65ad0db349e87d80806c181eb9f65819d91f8eb94cb901;
			gammaABC[220] = 0xe3f151f42f8c81368e6a4ad05c41bf01275d2512da799233e4daac8e42419da;
			gammaABC[221] = 0x25806cd972eb478c616cf66a63b6d5411e7e7d9e634c0d16fa5a3dadd1822cd0;
			gammaABC[222] = 0x10c49cedfab476da5fb70d09c4318a532b5741002ba720bc16e12dfdd05f5888;
			gammaABC[223] = 0x8c8c1c282d64a1f097013a15ee3b93eef3529e5fc6fd6b0b08654b7089f26c9;
			gammaABC[224] = 0x987d93f35ee0a07eb692febf1a1a920592834eb143955674c8d16f864b5976d;
			gammaABC[225] = 0x2124209fc06bd3b72df0c9be1c3871d3f2525e1fba27ba1f848f325124d9e7c9;
			gammaABC[226] = 0x7c4c922e38f4ecd01c241165077216d9c1b7dbe815cd285a6d5485243ec297;
			gammaABC[227] = 0x5dd49fc88eb989e3c0daf3dc56236d2f24644825839748a77bef7f5567486c0;
			gammaABC[228] = 0x47d10b154e40c2430972a40cb9e05f82726a1fc8fea451ed1b4fa419d2b3e32;
			gammaABC[229] = 0x21f765370fcdd40df9068f095d70baefd06eba1b8ef500e529db13f99bc29a14;
			gammaABC[230] = 0x29728cabead59e2719981f36bbcd65e697b37c34436901f974db01f994f9c184;
			gammaABC[231] = 0x2b6d56a9b8028a72fa4c756f1ff2f80168b50e04d7eb7cf7f6f0374d57ba1f2;
			gammaABC[232] = 0x168853197ccbaaeeef6b219b2e9e9a75dff6c7349f7a9bda3205fe60ef33e885;
			gammaABC[233] = 0x19e02e4083e3c635113214a81e5bef7506d294f6886caa96d83692566219822b;
			gammaABC[234] = 0x8164de381ac47555e8b475bd146dc98d11d4e1c3341f60076cf02f443c4297e;
			gammaABC[235] = 0x2860830afacfbeb8f0e6565aa5ab556665123e617c42ca8c9e8d031bd0323518;
			gammaABC[236] = 0x2594e875c9df967ca8f7cd79557ad6f08b3ce88499cb170d7b63cf071a8fdd6;
			gammaABC[237] = 0x1f0c0f03f9ecb637986fdee95855cd8a326a3ea31046341df82e16911dd7f8be;
			gammaABC[238] = 0x1b4aba70dc5613f6b75e47ee1584bf5000d2724556bd22df52d1784fdfa1ff20;
			gammaABC[239] = 0x10c97ba6b1c292aa6496f21970a94bd3c490d865c3b4f644bea9675b5b484ea6;
			gammaABC[240] = 0x2e9f08e2d2d83a8508cab92ceb6de402da9a0d2ee35be85a9bb961ebe1353c7d;
			gammaABC[241] = 0x274eceae4d0a577eee5c5271a038d15bedbfd102ec606adffe833789a74bc652;
			gammaABC[242] = 0x2d74f0076566b2bda67189b62a1311aaaaeb128a0bb1fded415ca8dc4cc4b9e;
			gammaABC[243] = 0x27abc8d96202a5637973e44b61f69261f9d7c1d0a9ba52ad28fe1b735ffb9134;
			gammaABC[244] = 0x1f959968fc9eb93ec1703376ac84d85f16ed3da3ed948d4fdaf90543a711c84e;
			gammaABC[245] = 0xfc861c91d4258b855fdc96fd1bb1b2d98abb2f8249eb91b6f2268fc4d5aaee6;
			gammaABC[246] = 0x19d228b8e9bbbb71cc121c3aa7f2d11b81a150c2d4437aaf135fe9acbc379c61;
			gammaABC[247] = 0x1ccad486c77e6f5aee65c447ccda87dbc056dcd75b8e2335eba108e837b7209b;
			gammaABC[248] = 0x27c43419a9e4b24301e66446ca47a78bc9a4779afb8e756e26a3e543b8feca9c;
			gammaABC[249] = 0x158b9e82eedddbcff70046326cf598db8063d7bce97c0cbd88df4e6d713b6700;
			gammaABC[250] = 0xa87f42bf1ec6e457efef801e99a681ad3eddce8195d7c227e6b3fbac3a1268;
			gammaABC[251] = 0x1477898351b7e539501741e84ba63c3a296cdc8eaee30ddcb2a591b8125144fd;
			gammaABC[252] = 0x2662f0dd1efb527eb28f4bc412184e5e9fd45fbee30ca3e80b0d06f7012a3f5b;
			gammaABC[253] = 0x40e0a30067f8bad1fdc6866f278fc73a7c0ccec45c95864b8c21ac711f72f26;
			gammaABC[254] = 0x37e2155251d5436e37483147995589d828bd6d50fcbe14bf5a95be0c9a24d64;
			gammaABC[255] = 0x133a8c7f6d31f2a8fa06ee0503773e952f738924f64b2e8290cdc8f6a7e2f966;
			gammaABC[256] = 0x1ab5f6760f16d72d893600012ff43772da01877b92f043a5883403a3bb554918;
			gammaABC[257] = 0x2aa5f2bd05598cd67116ceeb0ac604a8e4b41df546ccdbda6828a3e5a483b75c;
			gammaABC[258] = 0x18bf7e85a8aef5ce1d8aab0be8302377760d147150bab8412754eca3911f093;
			gammaABC[259] = 0x21ebe559e5b7aca6c73d6b70617750898938d126f489764335ebdc539c0c0b91;
			gammaABC[260] = 0xea5d3c54ae1acfc87da082d916c740202894a2bcd42ee2006d92e76aa891c06;
			gammaABC[261] = 0xabd96cef5d964adbdd6984422f9eb891cf683dab5d239264c9aa14294aee856;
			gammaABC[262] = 0x189bebec15500c2f9c1c2365dd6cb5985b886dab58a5d073eec75f0f5b2e809c;
			gammaABC[263] = 0x239f999b0978e04d1daa668c99a9d343586f1adf5570db2b6e734783ca454b8c;
			gammaABC[264] = 0x23b280c82594a76326258f03236cb2d8d71c9923177a7da13bc939a1b259882e;
			gammaABC[265] = 0x271d9a2105bca3bed01b83774742c31c1427b9d661800c7f94b4d43b5c9d39a9;
			gammaABC[266] = 0x127318d0777a3ccf993e7625310be2ea2ce5b0f3e9dae3c97b171fd071ff8c2b;
			gammaABC[267] = 0x2f494aed883e3e98740800edd50cc5f5b32ab2ba96012cf23fdd5242517044b;
			gammaABC[268] = 0x1416ec3bdab1f3470c389a69f74aa0abbaa4ee9e50b4cfdca57d011211159436;
			gammaABC[269] = 0x7091e89dba537b1cd8d089342b323aef4de6dd739f373901bb79e8f032951bf;
			gammaABC[270] = 0x1bab26fc6806143fb29136a3a0e2b32f3a4ff6fce0b8a95dba7305ed97ccb80d;
			gammaABC[271] = 0xe0b117e03375192bf27cb274b4d63cfb4d811966e2d7874ea69399fc8249720;
			gammaABC[272] = 0x9f65175e5ff256a36d427d2f3583021b7ff8ff38727a510e6db5de4455f2c9e;
			gammaABC[273] = 0xdbbefb8151292adb7265c767bbe372a984bcee1d3dab32826e31738ae595ce5;
			gammaABC[274] = 0x20062f24344441190294a1d6b8d0ae633200813b4cbf8416b7b40f1b42912394;
			gammaABC[275] = 0xc730909908792aa9681559e15274fd775550feb442d3ca9451d87e3419ced9b;
			gammaABC[276] = 0xc523804b28fc1cd8322bf32655a05b2b381d14d758ff6c83acb7654ac327a97;
			gammaABC[277] = 0x1542ee1c34c5023ade2c6ed19f75709b2a7dc61748b8998fc0b5813cd4d733b0;
			gammaABC[278] = 0x2c66fa4c4dbb2c7c20a4d19a0e1a9e0d474c39b525f1e39262452cc6c07a7a13;
			gammaABC[279] = 0xc875bec5894f9802711a15e6dc3ca12562c7010b5533bd73b8f80b502953ff;
			gammaABC[280] = 0x1fd25e9c105c4485a88c0c6efaeb13ffcbf4dbe1f645488205351d03f39c085b;
			gammaABC[281] = 0x1d1957d13b35af1e459ceff8554646b9cf07e06ee1dd8d07a3f9ca447ad99b6f;
			gammaABC[282] = 0x26366d9a14f46fd7abe2cc2cad116c24643be0c494c34f8d1c34a41af1ee4fb5;
			gammaABC[283] = 0x110c607f0e4b2515d7d609dede98b9552aa49867731eefdf93411d07694d544e;
			gammaABC[284] = 0x221518278849483578b0b49a45db9a79497612bdde0817938de82c21fe6af372;
			gammaABC[285] = 0x2f73fb9cef98ecf777d78d357d2d8ab63b1a9a1b36fab1c26138eb6c08ef48e7;
			gammaABC[286] = 0xffd0128fac1484a8243798dd26954353c05a14a48a70d072a9da7ab80b77a86;
			gammaABC[287] = 0x9e64e8762dfb83012b7342991f205b5008c70da869bcf1dde6dc483b5ea5c91;
			gammaABC[288] = 0x97bb1a537aa9d9af3b9ec743ce1ebfd2b4e84a34a8e741d10da7f1518c2f6e4;
			gammaABC[289] = 0x189624702fce00cfcbeb865d027ebf2f524b550c5c6ceac79c65e082864a09f8;
			gammaABC[290] = 0x27243f9606b61112e8b55b70d24de1349792d041261504f8546bd27ed58bdc83;
			gammaABC[291] = 0x142a8b8036b04071b55cc34339817ec197ec28e27b9e4079ed2080f0c58b6cd;
			gammaABC[292] = 0x32ce54be761ecbf68c065034d96f2ce0d8cdb4f8417518e9cc8926c64a6cde6;
			gammaABC[293] = 0x23f7398c2eb586da3041b5dd43a64eee3d7ca59c85487c9aa4944c135a855f7d;
			gammaABC[294] = 0xe0185c1a6e3acf04aaa3919a9ce374bcf7174a671c84f34476e0fcd594cf9a8;
			gammaABC[295] = 0x1000fc6d13d72e2da78a6122dd81ca9346bd7dd7f4eb10ad6bb2c0a44752d5c3;
			gammaABC[296] = 0x1f4536bc3676e18060f56d034841ffcf6b03e113ed7fefdf8b028d9167d0ef05;
			gammaABC[297] = 0x193603653104a08903ef7366b28e632d4ad942645b1fd4db1c3c26aabad91da8;
			gammaABC[298] = 0x1447c82f6702a0ea7c9bcffe6a602240bce1d573d19c5728471a9c5420d2e1f5;
			gammaABC[299] = 0x2c8fadbc32000e96563f68ec6922a5d3c101abffababe4308d39053b66748ba;
			gammaABC[300] = 0x15a931f1dec3794ede299f1c33806973b95d1e2f6fb65d426fe9eb859a54766f;
			gammaABC[301] = 0x4346f5b3b235c08a567cc9bd2bc4e2a6e5451ccd394b405b5ba2cc1688cce06;
			gammaABC[302] = 0x246a0f109bdf2165c87b0c440ff947782b3aa77e3fcf1864f470ac30755e3ec7;
			gammaABC[303] = 0x1ead5c7193de6731786fa4a8ba24a68b797e79d3bd0d0508c0a1c29dad37eae3;
			gammaABC[304] = 0xc9667ca29fc8eb4b757ba2b86437b5cd55951bace26a69f3d1c1395182eb3eb;
			gammaABC[305] = 0xc621f3810317021086e65ef3674263f34532e2420094f1a79fc5697a9c5d474;
			gammaABC[306] = 0x2d98657c3b28563aea04fb4c4613798b1d19f9558c73ff475cc6a275b57e58f;
			gammaABC[307] = 0x29092129d500209796bf344622dc823ae3afefc986fd0631fcea36524d774e;
			gammaABC[308] = 0x236a4709cb6f76b98fed20eea7d76e0efbd769355a690e44f58f7f47ca1059a2;
			gammaABC[309] = 0x2939f778e5dc05454795a36c49a3dd8252a67eaaf57e8a88ccd3862489c9c1ee;
			gammaABC[310] = 0x1926014ffac66b777c8d2f38e7371a5259d1e17c2337658802a2e1b85ab35680;
			gammaABC[311] = 0x26db90471c864bac0bfa084af27f9a4e1aaecd6d5660027a1c212397621a16c7;
			gammaABC[312] = 0x2f5c90831ae78d19ff5a5e6c98078fd7e6872f4c085edd54c50ac3c32d05de56;
			gammaABC[313] = 0x77c9eef1c9f24c2849739ebbf54ef1c733e278cb810bbd01c1b4c765c4e7e0;
			gammaABC[314] = 0x227742ba3f0eeb86ca61565fec00347d53e59a65c6ed84902cc1aba19ce8ab15;
			gammaABC[315] = 0x16e8b2216c7d6c793a677abb53fbb8d62e18c398dc9a09ef1c2dfb00dced1dcc;
			gammaABC[316] = 0x26a10f0bf1b92cf1bb868545e2ded29e76a2a1be2d912713a4a1b6528430f13b;
			gammaABC[317] = 0x14cccd709c8883bca9e70e80e06fda8f66b578271d3cb427d6e5b7eb73ad93a6;
			gammaABC[318] = 0xcad2906512d2086415724e8390fb974d3e83bee43166fb1049d9627470fd0de;
			gammaABC[319] = 0x122f18ed395156136ba7493ad794310edbff99a0500377d582fa5046e60e7e56;
			gammaABC[320] = 0x56adb305431bd4f66737ccaa0fa58a08e1a270d387d0417e0333dd515b55e2e;
			gammaABC[321] = 0x1d72a5fe25661d09c945f7af7bc221847a50ae7b9071ff976d7d73c0230acac5;
			gammaABC[322] = 0x2a4594eb1a3ab94c883adac7b94a091803955355b80ce9d4cbaf3dbbbd667f5c;
			gammaABC[323] = 0x2993d77a032ae66ec10eb6360c1cd7c56c5e9dc27be248b0e08837af737096db;
			gammaABC[324] = 0x93f746770d11f9f0ec53207b685d852f088f2da662111ef730c065ae87554aa;
			gammaABC[325] = 0x1c8be1ed706860d1d8cc514d3cb5f02efeb7ca002a46558a319a49bc9fc012db;
			gammaABC[326] = 0x17e0bae9a9befc3c9ba1a6aadbf003e045918f741ef2a42b1d898ae7c354a4b9;
			gammaABC[327] = 0x1a678af86e0c3c209907b8554b866690e54562074cf8da754ff68d90fb983757;
			gammaABC[328] = 0x2bbec701650620660f5e8a40bd927241a465f188b4fd36229561079e7eb35355;
			gammaABC[329] = 0x8397e19877abe908c65d508d74ef3d9323b91e4e8a6fac96c6f5bd80bad6f0;
			gammaABC[330] = 0x2f4f3b4645ce6ff82cb5659a6b14e2e9a771563d7b3117c38b396e14f4483994;
			gammaABC[331] = 0x5a502cec59a20e9380b585de4f378b98dad7b945472cd785eb7fbd4a9c9ac2;
			gammaABC[332] = 0x28ef3f879cfd4f87e41322751e3135cd87a49dc26edca8ee36737da1f1c307bd;
			gammaABC[333] = 0xd6f5d473790495484ad63940b54af56c57c4ae1561e5f1ae88c7785982fa631;
			gammaABC[334] = 0x2636559d054526d24c7f19abc39d987f027bc062404c2ac553f9502e371819b0;
			gammaABC[335] = 0x11a3a4d71f7c74ad255ca370adec363533fbbb134a2c18ce6c24534bae818d76;
			gammaABC[336] = 0x223d286a3816a7397fc4562bb86e77f2890509d79084ef175d303e7d6e594a8a;
			gammaABC[337] = 0x19255a3b52ae74e286b6f13e6485ce1e3fe4bcf144423bfecd7bfe10002b13db;
			gammaABC[338] = 0x2e5ace31f47b98050d95080f2860c5b0a1df7d42474752410d6fe2990318a6ae;
			gammaABC[339] = 0x158fa277af8bc7012a4228a5f265f11a34c7f2b2eee2c93c2e65cc59786042e4;
			gammaABC[340] = 0x15b961ab5f97713b443e32041568d48b6f66b0eaf967185117a27a0b5184ec6a;
			gammaABC[341] = 0x79392c15f11ec1652d4ecb9cb11471e4ba3ce8565446aaae6cb779296ec9c3e;
			gammaABC[342] = 0x236af9fa7c5f531d4b80d25e0afd96cd2eace6493c1bbe01e562d6cc6070ab73;
			gammaABC[343] = 0x2d46fdd66378472179d47ab9b8c16bc8087b23c97c8a997ec4117a1c99db2f76;
			gammaABC[344] = 0x21f25f66d13f3b7221e7c609f76e9f50e574434cfb9855c1f2506b27b0a56284;
			gammaABC[345] = 0x166d84eedeb3b905ffb0e3ff327b6568924bc15389ca9c4ead5fdabc791330f7;
			gammaABC[346] = 0x15c66a2e7bd56d1512a91b16330390106d0ce5f63153a7081eeed784d5e0fd15;
			gammaABC[347] = 0x1bd9169c1b1b737e4efd9c1aec4d9ad66cb46f9a07acf36d204ec345038bd068;
			gammaABC[348] = 0x2d94ffb258e784cef8a72cfe1607bf2ff5ec804914a8f91c9ed88830c515260b;
			gammaABC[349] = 0x1e50556efd457d75984ba11ac59b714ef3c4eb7bf6a330d498085b8d9606dfc;
			gammaABC[350] = 0x1d5d1eec266a957f773de9cfef8a0741d39ea54a88378229c89e63e76230e4c3;
			gammaABC[351] = 0x2ab52f5e0c63819a729975dd72fa97a5c0be5b13a8049107810b5c4199be6180;
			gammaABC[352] = 0x109cfff6a2a80184016d2acb774ce1479248eef9ed9b4a2b07f16418d5317c30;
			gammaABC[353] = 0x2056883af285318aab9ea847b18d73c498793f9ac455600c7673e694585e5619;
			gammaABC[354] = 0x41bb42b727535eaf45da954d030faee9706cb841e39b49c94b92842c0476ee5;
			gammaABC[355] = 0x28f6004f89e62707de9370e428ce4c2a8748c9953061ebeea911eac5be605941;
			gammaABC[356] = 0x2c1842dd7262236904a99f8af17bcfc52f01dab524c2f6b7764150bcd0b62c89;
			gammaABC[357] = 0x18160f39417253c5ab5dacffce71472152f201cd99a8fd6bf0c0dda6eb54abd;
			gammaABC[358] = 0x2b0635b9071637bd2df0820dcded38ed8aa7e6c395ce1fa600a40032e2bacb87;
			gammaABC[359] = 0x8e66209d4227200ef8333eb6f30ba925e20fa19c5eec51fd69414356c5199bc;
			gammaABC[360] = 0x2a4821d66fbd17399ee2246debcb64b07e439e9689fe401651b6c01007828713;
			gammaABC[361] = 0x271f30255915a8c283bea23377600d417b258fee54b83ac0220a6534e8dab6f6;
			gammaABC[362] = 0x30318672a3c143729be96ff2874987286326ff026be6a231461c04da4cdef941;
			gammaABC[363] = 0x325272e0b0c646c1f80c6e4bdd544aee6caeca407352c82db58043f9facdc13;
			gammaABC[364] = 0x1b87a54e7f126ad7f1b8c629b7a0d5e70e7cab941230ec052eabcf6d0c492191;
			gammaABC[365] = 0x2723fa4c89aaedefffdaa986e7b2830c35be5620db7ef016ad599d6f5a70c0c1;
			gammaABC[366] = 0x15ea35ba2f2fbfeb8c0d3b9dde52c96dacad452669057be29236c45e59e93744;
			gammaABC[367] = 0x1f3f37d1c312c1c76bb0a9677794ede3e607d4ac99c66c9062bbb46f7a1eb7b5;
			gammaABC[368] = 0x7bcf216fafc94bde19e06d31a77eb1af22971e06ab490a9cb9ab6d3ba9531bb;
			gammaABC[369] = 0x2d50a8abfa13b81a9c35574caca8c5c9f222ce058dba869ed49d24eea0c35e0e;
			gammaABC[370] = 0x6f9ce5041f8bfd68567da2af5fb7f59498f70e926ef66aaf7c3a3ba56062ca;
			gammaABC[371] = 0x1a76f08a6e5325eb8c737adf79c5f08db1d5ad260e79797b3de8177db8a88c3e;
			gammaABC[372] = 0x2fe95177169d9ec4966466f546826152a030cf8b5efb5ef47d4cbef70ff9a41a;
			gammaABC[373] = 0xe3ec5b396845e589447df264accba8e54881b39248c335c22bacaa84d452154;
			gammaABC[374] = 0x2dfbcdaf954d41fc38d0038ad56f6587863dff31e9d7bbd888e95879c61425b5;
			gammaABC[375] = 0x182feea9c6463a31d62c1d56ddeda543ebdeec95ab577a499a56492172ef5252;
			gammaABC[376] = 0x219520d19e0876363da846c62cb84810feb0b3e49fd40137101c4ba4e43347;
			gammaABC[377] = 0x21d4f270ca98d469afd95019a168b34a0e5c8eb1c320f7545865469782b4ec3f;
			gammaABC[378] = 0x12098c262eb300f4cb0d3bc99a1a01ee3901eaccd435e4538fe43c9b49e932a5;
			gammaABC[379] = 0x971d8b9e027813ca66b405428284b5fc304d63ecc53077be28d2fbbac3bd37e;
			gammaABC[380] = 0x1df2ee68a62e9dbe2f1d51ae82579f08ce6b34d7d6c1b993adb08f027b29dd00;
			gammaABC[381] = 0xdf421e9f7a3d556d3a18632fc16d068063a9c6d9da6a7b778d4c256e86800f6;
			gammaABC[382] = 0x13dfbe229cf5c6cacbb8e06b38468256d5bb5eed4a9d753ee222e268a86f41ca;
			gammaABC[383] = 0x1a1b2de8cc9df03fcc73f7de2fb50b2ad36b5cfdb4cb235f3d85d3c202ff2810;
			gammaABC[384] = 0x29a204e5ec1dc21604fa193380d9292b5ae695f6fdbb823c6be069d5481a694d;
			gammaABC[385] = 0x5647326294c179c8fb756e092a3fe0dbda1b76256b53fd53cb00cf6cc8e9976;
			gammaABC[386] = 0xf63359c1dce6c2fcc48cf9fa093c131bc7f2c68c3606ebf89c13933528a668f;
			gammaABC[387] = 0x7bd6fb2192f3d1addbb47bfe795b06ef8e38125e057448124d896cdbda8e9bd;
			gammaABC[388] = 0x21ed8ba46a9841e2db87f2d39148189260ed8569a0831992d1c8f4961604b235;
			gammaABC[389] = 0x22e0dc3177e645331d750fb595e259a92d6ed2899e640bbc02f708d88fc8784b;
			gammaABC[390] = 0x1e0f7840fd4f1831489cb4c803da6483f1607a2bff436aeeb3925eeb27b2b897;
			gammaABC[391] = 0xc7d72f59abf7c761ba451a947c37a073f24973793373b4295df602b8a461d60;
			gammaABC[392] = 0xa3194d32d5f1210a5a22634ce5cd8ef8866e27cac8c2b104a47f3bb7d2ebb80;
			gammaABC[393] = 0x1b00a743ae8892d93db64f31c31d7e361ec713cc697b85fb29a65dd9fe962c87;
			gammaABC[394] = 0x90b64f84faca9923a6d1d7b35b22c4897f8518ff1b19e8e527c746e09f35f21;
			gammaABC[395] = 0xa98c55e5a05ca9c5e843162d32ae127841e3ec537a33b8e5f6ecc138343a588;
			gammaABC[396] = 0xdfa278861ea5cbf43827ca7f132973263025f9daa623734d193bd54f6a5b531;
			gammaABC[397] = 0x65132e7525bd1e579019a67aae992c8b1f40d95b709b2fb75aca70d504f0c6b;
			gammaABC[398] = 0x1ef8a298bc55efe2c3769f645fb6bab83772ade2ef03f147b336abd4dacc87ca;
			gammaABC[399] = 0x2c10965485f5f0c112f346cd9c927fceb9a1dbd5ebcd0f6bb1a33dcfd1a8bc12;
			gammaABC[400] = 0x5b4a1c4de84b27244bd362cebfe2aa12d03ec2d6d831340e2f7ea9f460955c2;
			gammaABC[401] = 0x81f2d74049388f25b309f4ec6b23681cec589f108f6dac14be1c50cfcb4b32b;
			gammaABC[402] = 0x1e829f63147e5d5dade950f57413cc6ac28f9c134ccf27bf167e814d21a49d4b;
			gammaABC[403] = 0x1a4967d05a8d6e13e9f165feef78a4d9b298a0ff8925cbc4d2ea8afe01acb2de;
			gammaABC[404] = 0x7c00d4bfe0bc6ec27fa1e10974768d86ce6910a5dfbd720d32bcb27f842b3d;
			gammaABC[405] = 0xa36d6df88cdfc444e6fe9086844f94b38e9ce9aeb0b572e894466701993239b;
			gammaABC[406] = 0xf77391cee512d6688727adb2c06e47ddab0c118a3b89e94d5bd1540e81a58b4;
			gammaABC[407] = 0x273303eadd81b8c5988950afd9e230e448e9fae7ccb32dc63e89ecb2a00c820b;
			gammaABC[408] = 0x22bd97c5a32fb89db19d12478a75e6d444a1f6d8d2715c737612d48a28cdd0d6;
			gammaABC[409] = 0x1707f6cbf881fde626cef8af062b07677da70dd31e3cd09c37b899021a56a7fa;
			gammaABC[410] = 0x198f63c972cb4f3672f02b3969d8d680944463f2e65982b3d993a4949ec9a264;
			gammaABC[411] = 0x1f6f1dad3e7c92c10c9a16a603c330e45c393fe6cf7dbcf19fc4de5bcc81d3b7;
			gammaABC[412] = 0x16edaf802b5ca3b879aaf56071fc5f4b193b54569c43ab26922f387c44eed320;
			gammaABC[413] = 0x1bea392c419f54f0e769a9ca0ac31ad9a41cbb1731f94b4b8cce7708f7aa7de7;
			gammaABC[414] = 0xddf0549ec83c39d66e9826b5cf4f6521e6e3233c535de25ea15794785ae5874;
			gammaABC[415] = 0x27b764175ab0d402c5cf9331775e78d2fd44d1fe41f951ad17c41e43ce272967;
			gammaABC[416] = 0x2cef483997611b623a415d40d37230101f5abf47674a807bcc2345436c65d556;
			gammaABC[417] = 0x3f858c9bd5e19114f7225eb11fbdbea5a930598adc752dcf2f73251403e8bde;
			gammaABC[418] = 0xebcdff3b434f9f36fb3d5b3e1ccf052d0cd3f7464308cb87c829d852f80a9ef;
			gammaABC[419] = 0x1c957a7f70e44631738c0953298f9eea61c40e42544f54ee1d370a4ad00e784d;
			gammaABC[420] = 0x239f4e28ec82806947fdc600f36301563986f45876815eab7135092e14f4ca9e;
			gammaABC[421] = 0x1cf815c2b9bd2b175cd8bbcd6eb228c5cb78450af7007d8455a81cdbb496b60d;
			gammaABC[422] = 0x1988d70e0a71f5520041621ede4ddebe493983ddf0ec74d865b784729d8390d8;
			gammaABC[423] = 0x2e7cbe369f80593a67456693165785359ee1b3ae5256e4fe7f596ca66ab12a3;
			gammaABC[424] = 0x1c4c2230d78ebc59b22f7c496526980e7c5aa27a618523e900f510d45d0fc78;
			gammaABC[425] = 0x229149e84fcfccd563ccd1edac008c9051431977ff060b8fc6893bffc70c311a;
			gammaABC[426] = 0x1a71ba6b547b63016bd21ba38c3bb06ac41c053c39cbc621dab5f0d25805ea72;
			gammaABC[427] = 0x2c88e45a1f00669aafc2a3f9df1101a6930c2b14b0c594a334dcf11960ae8f13;
			gammaABC[428] = 0x27b2c41bc19f9bcb636dfd8f77575b278476a0e68bf8ecbcfedf69966ad7f405;
			gammaABC[429] = 0x2024f14fdaadf0604c601f85a35895ab298e04b3e3b1ddd4f9fa14ede2bb60be;
			gammaABC[430] = 0x100aea602c78a05b77ea55c46bf54da8d913df27b0390331d376457612a6dbd1;
			gammaABC[431] = 0x2a31e3e439a9f6d67ae4edbbe085ba4a7fbf35b7489cbcca4f70d441442af813;
			gammaABC[432] = 0x2a5c8799a3b7335c293a9daa557dee3bb2079475b4927ecef4bd21c7e3b4db7c;
			gammaABC[433] = 0x126ba9a7e992184a221973b2fdfeffab3e8f1de85a3c167419527d0dee7775c7;
			gammaABC[434] = 0x2342345408ab7a99b10267926b5b7b5f9a6d7f49e5525adbdf1315fae6b6755a;
			gammaABC[435] = 0x1e6655d8beb7dec95682dea45429d8735e1632e32f757bb5cdeebbea019f671b;
			gammaABC[436] = 0x2364d306046ceec052e15920fcfc53ddf4f3e9cb2db2437172acadaa1d979850;
			gammaABC[437] = 0x2389c2cd375d0a47544df5ca9ee12da750bec6f38e4b10be3fd14698a95b1f;
			gammaABC[438] = 0x2dbc24af192e6968348a25b624740a3a524e2456904fe7ab031c78d41a1f7767;
			gammaABC[439] = 0x2f734412494d906bc114a600974aaf7c8692e633264d62ba32f510073bd8073;
			gammaABC[440] = 0x11906d46a442fe7ed1197c42f8e7159995909a26ee2af85c5822d346809d77d2;
			gammaABC[441] = 0xa0189d569777b6fbfd51c51c25de5d9589620d67d111157592e73947afdc92e;
			gammaABC[442] = 0x4389e5c56d3631691b81b3b2409877d8d1a298072039333e0dc3fa8573d4691;
			gammaABC[443] = 0x4cabe0cd3ba0d654050aa8f1cd077a7fd27a1b1e843167cd294518ffd3a3a18;
			gammaABC[444] = 0x2515d49d16b80f7446a8e7c4f602b64be133e1bfaa48de1d339f0df195fbdc0b;
			gammaABC[445] = 0x29799263bed14cd4fb6e8882f25035c7e2c9c76685a852101a5fd5801ae41648;
			gammaABC[446] = 0x231e038095f93f55b578cc7833722133b9c45bf3d1d6128e04abadca961251cc;
			gammaABC[447] = 0x10841361542037fcd245bf90ff97cd1aa86cba83deac89c2921fef69ac2861ec;
			gammaABC[448] = 0x23366fbd1a30f03cf9fcbf1f1547b9349285fed565763dd980b50cd414009c5f;
			gammaABC[449] = 0x1a54a507066937111dd95f361c53f23c48066aa1463930015037461eab2d9375;
			gammaABC[450] = 0x1cbbd1f799a099390824b29e5cc4822ef8ef5bcd58f87436e4cc2beea444e854;
			gammaABC[451] = 0xc44400647024f693931a33be115a9c2a90e94fa6fe5e91d17a40e425f3535d3;
			gammaABC[452] = 0x11dfac473401b8bd9464156789a48e80578cab2c693e3ba61b36b951130e5166;
			gammaABC[453] = 0x1de1e9825434f615fce68053c10e0e8923e590b8bb2cd6dd91b985ef659ab396;
			gammaABC[454] = 0x4ed2e69b6e06870c61924dec469c9cb0746c7bb6f03a61ff3aab480bf58766b;
			gammaABC[455] = 0x2d8cb471206f6f146a2cb197dc2c8fc6e36c74734676b13e77fa08f12f03991a;
			gammaABC[456] = 0x1cef166b8f6bdc32972251074f2d4623df2fbcf24bed6d54d4b0282f3595351c;
			gammaABC[457] = 0x1ce00df855e1eadad1e00af41d85e7f23dba60b4201a275d47b3ca0e872e80c6;
			gammaABC[458] = 0x1fcd9274f4be31276422379cf01b0d5ca720555f1c2ef47bd7cdf9971f06171d;
			gammaABC[459] = 0xaa1ffad214ec7979af1c54abeb86cce76bda3f6e131edd1ceec97285a09fff;
			gammaABC[460] = 0x1c2bba28e6d2ff66c2a4fc6cbff1e7007008ad4f7ee6f9b96eedce3a2ca8290e;
			gammaABC[461] = 0x221bac3c0a169b89c7aa9a857c63c08d9bed1cb859f30c6df21f64688b6c5b1d;
			gammaABC[462] = 0x1feaab573d7eefcb7392dbf226a0d35d9892627573236f9f9c3e47cd95b9a68c;
			gammaABC[463] = 0x13a19d4f212337f9e2eb6310e13467001847d0d50ace8902d1e59820e6a631a;
			gammaABC[464] = 0x181a49ea5172b76716bed6af6e70f57ba54f94efecd5d995390ab7cfaf949657;
			gammaABC[465] = 0x1e017db3802cd720a77060072ac36168b4da9b895d52a482d9fe9797fd852537;
			gammaABC[466] = 0x169649337b149941de722f65553bfd2d7d254938f2f13cbc1d548ab949533177;
			gammaABC[467] = 0x176a9c876e5638e937f9515cf9b4ec9b945e42e1951bfb0731f4dfba420619e;
			gammaABC[468] = 0x1b14ddb516265972c1e13653a690011c1e3837dd0ee6d32ff46f87e5027ad09c;
			gammaABC[469] = 0x8b5fbd9e3654b06677580b89a6f7a9802c436e8aa4a225c19a29f9b7cac39ae;
			gammaABC[470] = 0x1db3f2354eef70733e5ff5812b2a57693dcf4039eab8d32e3a6509e3efbd9fde;
			gammaABC[471] = 0xb89a06e60041c8c074a3cb3e424978a8f0c2853f741b5c8cb942ef42ecb32c8;
			gammaABC[472] = 0xc5507374171ce825b0c667a137b3d789cf31783791fc4e525d705d730def025;
			gammaABC[473] = 0x1c70c18bf527637e5deda7cd217ba4326b07de790155a8000e222d3f9b16fe3c;
			gammaABC[474] = 0x2fe18a6fae6be249d9ae956ac458e28fd1e34b100b9637e4a469cad002f4f281;
			gammaABC[475] = 0x1646bf9e2f84a3262480dd7d2660d399e67269ec13079af943f02dc7caa59511;
			gammaABC[476] = 0x21056d5eccdc95f66edff557f60fdb964570d990390c50f06d707f3c564e2e6f;
			gammaABC[477] = 0x2ded89b4e0193dcc8dddea0512e126602b0a45e7e8d2aaf48407095c3fd7c891;
			gammaABC[478] = 0x2785542e5eefd134a69707a77be679a1a7bfb938cb03ecc2907ccae8eddda3f8;
			gammaABC[479] = 0x3b151b7071441c1be4cd6740ffae18be6080b01af067827124eb4a91730f152;
			gammaABC[480] = 0x1692bfe725ca2f8da7f450a6dd892ad8971406e9cfc275301ce3d98c0c5b5236;
			gammaABC[481] = 0xd52ccac9d49a57da88987f130df2ad5eddc453e73d309805eb0254612229809;
			gammaABC[482] = 0x26aa18c90dc31fcdf9f9d9816fc780bebe57d977bf786c079184f0d099b7eeb;
			gammaABC[483] = 0x11f2ef22cba42140a211c693a994372eb9b659dbed33b73384083a7e295d23b7;
			gammaABC[484] = 0xb052dd35ab13da3f2b42ad189adce99b71a2e71cab1e1c844639e8837fa5b91;
			gammaABC[485] = 0xf3ef6fce7b1ec88d303ddc236d3561d0b6982907147f2fb645760a7b0b94553;
			gammaABC[486] = 0x11ee11015a474103458e98ab4a61d945353a6d694943af13cec60c4786d6d0cc;
			gammaABC[487] = 0xe99c58856bcbfd409db1f77c8e1630b31b8af2f19d244fc469c293a3a2f9e70;
			gammaABC[488] = 0x2551ca0e1ffebb93cf91e0a4575c055be981398172b113e86be47054a6ca4dd1;
			gammaABC[489] = 0x217aa5536b044b083e3cbcd95fba15ff8663f72b29525633ddf93a0dabfa6f99;
			gammaABC[490] = 0x7be6e6e747d16dab61c2f7585d2a51fc444559b86272fa1f5d9580e82ed1a8;
			gammaABC[491] = 0x2121f228fcd71e2b29b07b037a516f3482b12e5c0c521e98414931b55420f0b8;
			gammaABC[492] = 0x9c6277c0c0f5b7c65ec2f7e0e2f2e4f4de5da5a4d5796d02105d0871a9e7ebd;
			gammaABC[493] = 0x1ae80ab677459ec368551f81a6a5cad63349e84775c91c07a64e9f7ef64b83e6;
			gammaABC[494] = 0x1b5bf9f63df08dc1206d2fdf174f8c60abf8da86a1f90b1ff531382dd97d4c9c;
			gammaABC[495] = 0x1b3ed8f67c2103bda685929693f2204839e00df324333d7b55d8019d967143a4;
			gammaABC[496] = 0x1f6149a595ebc5963af899f15c49625daea15fdcf4021ee11d4eb8b080aa611;
			gammaABC[497] = 0x16003bf2196535e8abe9ff71a2c69667d6e3c61769025c39c66df0196b3989ad;
			gammaABC[498] = 0x11177e9464edee6dfbc55f23ca5e10b625ed21493159905c5dad5254067f532d;
			gammaABC[499] = 0x2b1e95ff554e82483e58feaa8ead0774d9fb5296055babe8f9badfa9e3f1625b;
			gammaABC[500] = 0xf917cef9bc5e1aecc0c2196818172a5cfcd10f750b78fe59d58ac4090b421bb;
			gammaABC[501] = 0x2314d9a9028aa712879ba5296d7b8fef57c4afe9a6d191d353c529feb7bd55e0;
			gammaABC[502] = 0x1ebad0000b25146035287fc49e983aae8561a3b90f686e519235e7d211e59f5;
			gammaABC[503] = 0x13f480cfeb4b1464c9639e22a986c2144c941b9b1194d947f59b297424a7d3a;
			gammaABC[504] = 0xeb26dbf4b213349ded28fefd6e8815af9b321b14b2415bc9af61077dc4c5adc;
			gammaABC[505] = 0x15f34167feae5d986d36255707fe86a7f40964f5bc900dabac850202bcd0b25;
			gammaABC[506] = 0x146800655208addda90849a35f28eee3006e1e6a6f72651f32083a6b8db3c552;
			gammaABC[507] = 0x8867d54c59ffe269277e2ae2385f0cf112dfb2fe3c2d9670a514533ebe8a667;
			gammaABC[508] = 0x95668bacaf61d1fb3408ca8d0ffe81542887312b17a8b150acc973162a04260;
			gammaABC[509] = 0x2d2dccbff6fa3b783d3a811dd004cce17dee28ab01a0cf6ac0a7c95fe5a3f0f;
			gammaABC[510] = 0x4bc7602f4a5d307e8ed7d62cd8142ee7619f34052fcc8e5a277ae1ec1875103;
			gammaABC[511] = 0x731b7aec649f33c1212d47e2dd73de5c1830976feb6e79e55c63cbba989b0f9;
			gammaABC[512] = 0x2de21bc905a48c749c420ba1f6f3f00705de7ae2f02d0c01a216ee7e8446d18f;
			gammaABC[513] = 0x25fdce8ff54950e7d65306e2f2a0af1cd175506562e588918a9f17935efc6fc7;
			gammaABC[514] = 0xb36d3bbcab0f7e2fbfdc99aeecb24fbf0deee6e53d1ed8437b20de49d8f6302;
			gammaABC[515] = 0x1b1a19ca720783acdaae2df0dfdd82357b31af868da568cc7d1cec2dc4e3313c;
			gammaABC[516] = 0x126042f025b0e9afab84b63e4f727de75cece176eeb2b84716f788a64472a295;
			gammaABC[517] = 0x228677df70007d0332eded63bce4f16817dcaaac56aa57d0bc23d9ec0d144b4e;
			gammaABC[518] = 0x13d3b245766b31f13f465c172df1354d578ed7d4c6cbbbe7d0ee9cc78e89e6cf;
			gammaABC[519] = 0x1df893c583c967071d9046337ac525a69a72a4a4b7aaecea4c11f8684c9485b2;
			gammaABC[520] = 0x2bacfa19718eb40327e90187cf994754ad779459f7822ab15d8b31d97ffac09e;
			gammaABC[521] = 0x992bdd731742ba2f5ff35ac22ac21fe5ecee326119ec25d1138b3d0b9bc5868;
			gammaABC[522] = 0x1101521b1edd4adf064da5f843e294024f1cd0486a928cbc778f186ed4371e1;
			gammaABC[523] = 0x1b8c3daf6434ef1b56b681c53bf1cfb68b78f58768767c0cc88130985f1d35fb;
			gammaABC[524] = 0x8ae2cb4777195151c588354e8d1b516a3a7de87e75425b343b5a50d8821e740;
			gammaABC[525] = 0x1904b67aa7adf795c1b97d3aaf17dfda3ff17d0668decb93f49782586bb518f1;
			gammaABC[526] = 0xe19f635aec6a84e1072aedb4631c19eba43c52da144750b71b5a968ba4bd78;
			gammaABC[527] = 0x1da1fa846833fd339c42c65a1180334098b56f8d40414737d650b23a96c7df91;
			gammaABC[528] = 0x2255a4d0cf5ae0794699743df7b4a2230cc97f683e09564cff2a407a6e1ad6e8;
			gammaABC[529] = 0xc0421ad9720b5d01d008f8c1fecf18cc9294a4d18a38c33b42bc568f1e643e5;
			gammaABC[530] = 0x15b1bf54f1bbd02942d2f0ec7055f645b8fec96c6b8126a0337f98f51c158d2b;
			gammaABC[531] = 0x1c6682e676718ae1e641ce1d3e1cb5d54f9924f43e90d43b06e29816807c131e;
			gammaABC[532] = 0x2047bbf99f1a9e67d2dde62e846eff6c93ab741b428148413aec04d67e893332;
			gammaABC[533] = 0x3d8468a97033e76b0851d5283b7d7ee48a06d9c400ca4063b4cad00f0cc1077;
			gammaABC[534] = 0x143428e78ede07decd38e2ff530f3b9268fae2eb62ffcb0b95cb32f90da8d09a;
			gammaABC[535] = 0x467264acdb3f10ecf7da1823f2d55474d67b4346783846a3ab9477343dfa034;
			gammaABC[536] = 0x1a4f84de1263911a2013650f56b9c998d41389d8d6dd87631a36bc4209788982;
			gammaABC[537] = 0xa30f8234a9d9d4c124d032f524f96b1c0e316f5def95d1ecf837dc7e2da0c18;
			gammaABC[538] = 0x1db6098bf16424fc632236559dd89ae35b861f93666d734fa8a768ccaa396aca;
			gammaABC[539] = 0x121876049e6f1bee6ad2a81fcdac7484c99c3dcf9a6f98a252ea24b8bfab3b5b;
			gammaABC[540] = 0x304e304edb8db75766bf68ffed28cee9e40036d171a0ec63b19abec12173771b;
			gammaABC[541] = 0x23e2e939e20baae6b94298291badb046da5e213726742248b74d42fcf623ba2f;
			gammaABC[542] = 0x779ee10f97f0ffc2ad319d4d9ba645d7dd89c2b4b933ae3b456c0119351a324;
			gammaABC[543] = 0x11816bcbd87ae5e0207985c7742141250500a082445758fcbc7f8d22c2462f9;
			gammaABC[544] = 0x1b0a0502e6d8af905678825553370c313f66cac49186af95b86dc10ec775ffd;
			gammaABC[545] = 0x129a3c5dc04faba8edc922a214ceec39025dc33ca83425081ce0a83eac79477c;
			gammaABC[546] = 0x21b4682c7b239f4e6ad6c1762ec7bd7ad7196cf592e0bf19b681ea347564471a;
			gammaABC[547] = 0x11a9a5977dea425637dcb4b53492219b8f9c25e922f4f137b24aa34bcb3f490a;
			gammaABC[548] = 0xd9e904411718621794c46a449d42ff4e5d530d19c4f35d62b438dc205a666e4;
			gammaABC[549] = 0x15985a82e64d87922443d07a83e141108a2f99a4488240b634227b3c09f61ac1;
			gammaABC[550] = 0x162f876ad741ee6557813b00be813b4e60348ae4a378c57acf20a9f74ebb80db;
			gammaABC[551] = 0x7d2ada81051e24473105defbd098bdff5a6d5b6a63f705b86f60de398e51e58;
			gammaABC[552] = 0xa0d4d062b9d4d8867c0f919431772d65d2ff807ac483557fe48419fd8806f6d;
			gammaABC[553] = 0x74988aec8192d2a9e2830a33551b66bc464471925bfd80af808d617e455bfc8;
			gammaABC[554] = 0xb766e6822e35fc527680160f66333572c80dfa1386d4c2127f8e41c19795b60;
			gammaABC[555] = 0x2d2bbdc5f4698688c2e68d7d31add035345f64b9dd5365584c7baba48cd5c0c7;
			gammaABC[556] = 0x1b8c71a4423488be71bd6c00609cecbc79614f242115bf345d65fa0e861e94d5;
			gammaABC[557] = 0x1146edb0ebeb4f4d7d74c2dcdee52d537737c631ef75fb1cc471e6fa26ea85d8;
			gammaABC[558] = 0x1a6b2e19ee5b9816ac9f2d80f5f0b1d16937bdcc52afb09ad6416b5f4f2fae50;
			gammaABC[559] = 0xdc5a27eab02ab9e04477f4b25c19a7eaa9479fa8ea65ef469fe94de02fc2871;
			gammaABC[560] = 0x28bde7fc7364186ff262f0ec8482b2cebd97923fdab099f5c1858151201e5692;
			gammaABC[561] = 0x236984bf18791f65780710849a0d0f9b1169973323b622cc32879f04bbb526d3;
			gammaABC[562] = 0x30782d38e016f53d91e4ae493f622b2cec219047f11ea7a90bc27378e599dc5;
			gammaABC[563] = 0xbff045ca813d4e19f1d497c06f0ef6eb28aac2e9e306272e1448e5ac2629074;
			gammaABC[564] = 0x1a2deb5fac2605bc3db13e59e86fce411848fe494e41110628eedbbab1afab7e;
			gammaABC[565] = 0x1e20aa6272c9da8b1abdff79f15d7555984eec8f4d87a26468b760a7ae451895;
			gammaABC[566] = 0x308f806730da32639887f1a1b973032c2a583b32616f8e0890f60e1c386ab44;
			gammaABC[567] = 0x9784163cd32e2389e2b24352c64b8f22089d48ebd889d4f89e9fd609e69ae5d;
			gammaABC[568] = 0x2eced19f3b17e9105f4d21dab023342a3fa1167737159972170fdcdf35bdd900;
			gammaABC[569] = 0x11bdbda83059294966ff6edd5c189e9112cdd2469136c1a1f822f3b07229564a;
			gammaABC[570] = 0x2c515509a19e685bcf0da6e26457b71ebfe8a2b41f42632b5a07af0db8cd54fe;
			gammaABC[571] = 0x1770d6fbf4f3e49f5d2bcc07cce918b83dd5b646643668b9c110cbbd659e0cd9;
			gammaABC[572] = 0x14b750371c13c6b8dc12bbca5d85855611486bf9a73e3aa8af3f5591c11b84ef;
			gammaABC[573] = 0xe5b1e377d406a211df9264fcfce55687c2290f78ba4f4540f62cb3a91363ffb;
			gammaABC[574] = 0x87c067df45f74fbadba5deacf99c3cba643c6188fdcf4dd44a2a13cc9ce6e6f;
			gammaABC[575] = 0x194ed9f08c5a3731311c314b6e1cbf41040053f04268b204068e68bde34b673;
			gammaABC[576] = 0x5bc5130dcfdf09d4ae734108578f126ada30d9cdcad73ce6c17ab0da32a4b5b;
			gammaABC[577] = 0xd88b6668744498e81124bfab27c7a1943a060cf14a4507c6a1cbf031efae386;
			gammaABC[578] = 0x27798ebcc6a0752d44881cc935aaf3eb77931c5e6b09ba217383192c309d9b86;
			gammaABC[579] = 0x13f51d21b424e576d8cfcd13e273bcef955e404fa0a93703fba36088b741a24c;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierFinalize64
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
    
        function VerifyFinalize64 ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x2bcfc77bfd8fc1037071dbe33a64e937a3b057bce27401e329d1db79a816ab02,0xe53d9614e908756879b345b25fc5bfa6a2ccb5926bd7eac68e2e143c5132a73,0x25aee25eb79c8f10c406bb71d3af74247fe617c7c21a5dcf76cbaeb3af1e4bb6,0x355097bf3837d20886edde2b9a6b856b1123f99ba61abddc51c721280916e4f,0x2392243d7c66b931e71f167cc9eca51208e01fbd068ab20b0ac649a06a5b49d0,0xb8907f5317ae4f6a27744a8b45c3cbf458b22c0bfb2d4f6ba41626dd97de6f6,0x215ef9d898f9689c77f42866b75cdfe62cd37421e446c07ef867d181e3699f77,0x1060b0a88f9c27fb27bf1b004f00a98ea2c8d5e6fe0793547e0b495684accd69,0x5488b88e6b5310ca48632c9e6891f733209068216fdc6a951ead35ee1141cd7,0x2c94733d21f577387ca6e83f674f34f74035784fc939cdf5bbe01cc6f9bbcef6,0x5cbf1bb980aa68820819982fb8fa4b4134b49c2659f624d9c77ec5e6fc467fe,0x2f43e815ed6dac56e4a30503de04d8bb66aba49c83f2aa0fe47cd4be50e8d729,0xf18527412a06aabbcb9ec3796aa70735dcddb2159a34ec6aa1499d1f2d7fda9,0x906427abd12e46f92caa8644bd08988bf88e49cfe2cc56b087efbc9d0889971];
    
            uint256[] memory gammaABC = new uint[](1156);
    
    
			gammaABC[0] = 0x4f7718c103d3d20b6cf5ad47d41f83c98ca22503c653e740cebf94d3a2dcbeb;
			gammaABC[1] = 0x2dccbad7839f2e9eb7eceb5a48f38426e0d50b2ea522f9e14b4460a57b6f59ad;
			gammaABC[2] = 0x256a5a1d571d24f7cf7b259b92adedf6faff534fb6d6fffc43b3528af1f87c3;
			gammaABC[3] = 0x2ea44d436f8c9690a4c364fa3341e5a42816342218fde4dade0fdc5265f2b7cd;
			gammaABC[4] = 0x2c391be978f52cc046e60ada3fcf7b25d665b4c48b4aa6a8e107107273c340ce;
			gammaABC[5] = 0x10d0bed9b9c3b616745508abd2a0d98099efd55bc11a8e47abcb617309655e54;
			gammaABC[6] = 0x13aa65021a215a750a2d5ae7009d58fa532fdf8b5401a278b383a532fe45e523;
			gammaABC[7] = 0x2b979b30ef9846efcc7a3be41b4f570a531a312aa6197c46637dadfd82aacba5;
			gammaABC[8] = 0x1d1a054cb0658d0a64e6b2aab93276be9cc3fe9785914aa39e0ebb2c12549b2a;
			gammaABC[9] = 0x1ffad88e9e55fc4db1ca326795b4a5d99a29ee07f6357ccb2e48d5c849d416af;
			gammaABC[10] = 0x284c97bd2b76912f8d2046e2c0dabd01b0a097ced3349a3cb1e1fe1a96b141fc;
			gammaABC[11] = 0x27be9b6c1bd737d52490352aa017666525d10ada04bb75c8e1d42c765ab77ab3;
			gammaABC[12] = 0x20b3627792c4584f1c89a37e7f13c95c8024fb5b4563f1e4db7e02aa1d7ffac6;
			gammaABC[13] = 0x2b7b612373232936de6f1781f8690ad3522b2ca608ae17bcd0c6e89c1d4d37c2;
			gammaABC[14] = 0x10dc68c3ab69e76d7a255eb441cdef3571b46bb33fbeae7ac034c90d8b85d5d8;
			gammaABC[15] = 0x649c31d94e53a36e9a1ed38b2a0610aff82a1483c980d9398dcb551bb5dfbd5;
			gammaABC[16] = 0x117af2f9fa930f7a7a8c6e1c63d519656033e729a9e6a8402a4bc5ed7080950c;
			gammaABC[17] = 0x1c49e1f0551e962d99fbf72d36e1aa3b0c7eccef9a39842014de1ac2b46ed921;
			gammaABC[18] = 0x82de270859873b8379911e1f1a314e336567ec5c38c1b9754cc859de3cb023;
			gammaABC[19] = 0xec8094024cba80db30528a9de4ddd7219c629871d2aca3a5c2612baef96ea3b;
			gammaABC[20] = 0x299c6e40c155110944b35cfbe72237b39131c8a37d32704e1156ae220a3c04b1;
			gammaABC[21] = 0x1eedc36e21318069bff0fbe6da8c5e8120f56e89173295931666e875db575f1;
			gammaABC[22] = 0x2b8d843cce520b08ab4b59f1288fe55fb047be50e12f187d8f6ea0b082889896;
			gammaABC[23] = 0x175bdb92f7a09c2d8e56561e11b6ca4088f8abf7d9315733dd5b981c54d6a330;
			gammaABC[24] = 0x79c2a9ee24f665d7610873548f41cca39e749b58ab881615aaef0fd7875b7ba;
			gammaABC[25] = 0x1fd56e3c4cd836bc0a6812d012fe0d7a871f868d4d3e1a23e8664198f20e1185;
			gammaABC[26] = 0x6219adf34f161b7f1c60618c1362bdbda635552052d128d1487719600d3628f;
			gammaABC[27] = 0x2b8f99ff37c1a72afb7950c8e1239d646d6f5081bb08fff6d556592b24a617dc;
			gammaABC[28] = 0x121632981d92cf54e68d8ca2940a94ff13c0207be853718328c039683b5a01c5;
			gammaABC[29] = 0x2b32039717baf3cff5aa1e13055cf3c0228c0f4a1a084632cf81900bf28eb434;
			gammaABC[30] = 0x198fce112c89440e7e242dafdff38f6446db92d2ef2ffe7117e6ab416b62707a;
			gammaABC[31] = 0x153294245a3df73f50ad4bfcd68ebaca94e3c3df0cf350fbb8b0f8de0dc3a431;
			gammaABC[32] = 0x16e3fe810511f2961518e3d85992568aa510e85c4ea8a4a49d9c68fa95b7982c;
			gammaABC[33] = 0x33a3eb6b8b90ef476a6af00cd323e0c21963b6c51edc81ecf07c94d51438408;
			gammaABC[34] = 0x27391b64ef8077103b6414e05624fbb833d980e4b26f56325359428f66e7c450;
			gammaABC[35] = 0xaf1623cde40abf532e2fd7d82a3706f90f6cb1e67a379714936258342f9b634;
			gammaABC[36] = 0xa02efb490ef5b7d89ceb3c0638dbc410ec3c0084256b1a283966f3d8f059a25;
			gammaABC[37] = 0xc2294225faba22cff5a0dff5da80c01b2533dafdafeb223a896d7a3a006bd2a;
			gammaABC[38] = 0xebe1ac99efadeb7cd8c5051097b388c947b0d0bf9759d024606e4d4b4f2ad41;
			gammaABC[39] = 0x2e74d555b83bd561d720396c5f05c356a4bb89519a2ecb5ad3fbd9b36c986c54;
			gammaABC[40] = 0x2c89ba6f47911c02142a2466a7dfbbf23e862a3775db61a68037a22604d1d5d4;
			gammaABC[41] = 0x1e71d55512de47a0e73f391f48f0944998d0dc31b7c6f23f65e1580018f16696;
			gammaABC[42] = 0x21e59c0320ad670859afaf45cb6ca169e230ccc65751106f0674210071ae5739;
			gammaABC[43] = 0x9722e72443436370bf13bb50a105b2e4592a7e0e4004ba16d37700773417fb4;
			gammaABC[44] = 0xfe46b3b63e9e9a75d6b37fb9922c71bbd80c2ad9e9d4491e0a1575cb076ee6;
			gammaABC[45] = 0x29437d8872ce6aa916908ebe2cde5b977fb9693956c5c09667c9e42dcaec753;
			gammaABC[46] = 0x145814d93eba50f5317ec05eee2c3f11859f2cc797cd8c7fe5e4008f140d7223;
			gammaABC[47] = 0x288258265fe32cb3e96903a23b2ee7d43a66ffdbeee6af1aa3f38e73f168f76b;
			gammaABC[48] = 0x2c5e8c92ab254ec8698e151b44e3e21b92c452cfee3aecc8d587e4a661892cfa;
			gammaABC[49] = 0x212e266615ce497c1133c6f6eb22e6c93542e607a98c6f760080dd1014fc6b3f;
			gammaABC[50] = 0x7af303e205c3b98d2f37b29128c11026a59e26de845bdf577775374fe4fe09c;
			gammaABC[51] = 0x230d327489597a35a6c66be7f10772ce40a9990bf9bf568fd1abb83cbaa94011;
			gammaABC[52] = 0x2419524e06e3b9f6f4c6a88e14822ce9f0417564999dc1ad509c94a8f0c735c9;
			gammaABC[53] = 0x13c8130ba70386ca51fc86f83755068604411189dc7caa0287b2a01adb5f35d5;
			gammaABC[54] = 0x2ff91d8a6b29d82c8f68efba5a680223716eba24d1516b0a0b806b51f6bffca8;
			gammaABC[55] = 0x26cf532e96ce73c936762ad15b0bb280da9e400ce70630514a24c28ce91d2325;
			gammaABC[56] = 0x1a27cdaf03ca3fda0a2e5fa0e3c244e8049da78b1fd900f088a206a86bb07880;
			gammaABC[57] = 0xb9d77671065a36c2d86fb653c256562d166b9f86e3280a4ec21fda50745f9a5;
			gammaABC[58] = 0xbcc580c051ddc01a6bd86cf3d80a76181aeac89139cfc12a1d17358a6cf73b7;
			gammaABC[59] = 0x4f7708a2fe84d43879cd9f41acbf5444fc206c82bc56814ec2bf281e583ab4a;
			gammaABC[60] = 0x17197348eae77cda795e06c6285fa0475ba36f948baf09b434acf73c69973b2e;
			gammaABC[61] = 0x1dc6ed3030731e00cbbecb532c9d74cf2c8a5919a6be7be27ec39f54c3773ea0;
			gammaABC[62] = 0x271c8ef14d4de6f9a7bc30c00edc0c4ad59946f71472aed9a3121ff4556b3a74;
			gammaABC[63] = 0x3cfa8645effdcccd8d1a76c63d2230ac476c9b72c6d62eaa70adb18e7996c42;
			gammaABC[64] = 0xcb5b219e678f8a1fcfd8a5615029732182b5b63f423a106312b6580ef12bb10;
			gammaABC[65] = 0x14e6185ff2be7c583e036782e6ee0bfd2610c99aa1cb686ee5731b5c8627a809;
			gammaABC[66] = 0x1fbd71493b2de66fa851f34f9c79b10c7e916d4d960804f5fcb1fdb114a92070;
			gammaABC[67] = 0x2d9eb1052924c92ecd7ebc4476c04daad86b21e1a36d2da08cf851d135bbefb8;
			gammaABC[68] = 0x13316568e559f824c2c2a1fd84bc1b72b93401af533eab19abbaeb73aa894e2d;
			gammaABC[69] = 0x166c246d9139e2a6da27c940c52244cf7cd9dc248c29c9e1fb58f52ce0a230a0;
			gammaABC[70] = 0x25ba62f89e6d568615e298b45fb8afb8b9e26f71e9f84fdc346f17d68b7bad5a;
			gammaABC[71] = 0xc5b5aa8efb8e0fd197a2c6e5b7a783a31713861e9c0f1ab9cb5a5f5ee00f233;
			gammaABC[72] = 0x46a09a2bc27d427ef8632851eb5ed304c80c32b3770690c05e92f3b7e4b4ddd;
			gammaABC[73] = 0x1aef2f5ecb4e067ce381cd2c36ed3497e41c4d3b48349d737da1e4ad36f6df3d;
			gammaABC[74] = 0x27e3d8b96786577f70b2e8135f3300b9903fe30ee78f16403b3b4cf00101722;
			gammaABC[75] = 0x221bff580acafb15eecb5c4e01b07a662d26a7e5f0f372ba32ff07d878969f7c;
			gammaABC[76] = 0x1ab1df649ba229643012e6b64caea90fc4d21ce678b9a29ed7373e66155a060;
			gammaABC[77] = 0x35d3c9cb38726c0b6f2492eec4f9ceba0fbbf974744835486a503d12e518da4;
			gammaABC[78] = 0x1973a04e80b96bfea6524e6bb324094b4c20a187fae0e878968febccdadae362;
			gammaABC[79] = 0x1545e1abf1a7ce2b2334dc3698ae8610935752fe56cc956623934bad0a6f01d2;
			gammaABC[80] = 0xfb805edbed92e2bf3e5268ed7823dbd07d01c9c61b364786d71b94bf1b3234d;
			gammaABC[81] = 0x3a2767ef8865a6711028d6234674aa687377971a5e832fc9020d158ff69d0cc;
			gammaABC[82] = 0x11f2e0a7e818dfdd7bd8f98a413894b4e4ef4bda1685d5d6860d33375b36fde5;
			gammaABC[83] = 0x8b9e4c7f27291bc5e74a8a09d9c0db07b747551e003bc8275ce948a0d8cd78c;
			gammaABC[84] = 0x1a5d96c2eb70a0586f514cc2f78cb3aa3f3bdd094d948a7fa6500991e20d706b;
			gammaABC[85] = 0x1497ebf1c57a2d559c87ce56dac6b9b54586b9b83382b0ac739867009509fd91;
			gammaABC[86] = 0x2d8cf9eef0d23ceb8537b98f707c20244aed6305c68c1dde86b947cf0de3c03d;
			gammaABC[87] = 0x3017a410c0c9124523a2cc0fada435ebeb0965dc2226b9ca336ea0658fe5f8e;
			gammaABC[88] = 0x2e486c5893e851b4d5e8cf5da2e09e1a354efcea235bf691b28f009b175bead3;
			gammaABC[89] = 0x7f7fd4de22ed520a5cdca12e26fa132c99855e02d3d4a2b31cc3c6e7203fab1;
			gammaABC[90] = 0x2979b49729f501451e86b2cfe658d3bb1c2291e82e27b4a1dbbbe18dc266a2ab;
			gammaABC[91] = 0x82c80030f11d8b7a7f4a404fb843f14cb7eac7871d6d826040d9a9316f8e43d;
			gammaABC[92] = 0xfcc18ba84fc5f0a951d3559cc74cafe2ce168f96138ab7f8c96ea0d8d5c1eb8;
			gammaABC[93] = 0x235c0dfc3b379d390829865b8f6ae0fb695ec6d3d745dc9a859f7c1de521acd;
			gammaABC[94] = 0x1b4b0018b9b3f06bdbde788242bd7786a3fb21ff72171c86effc35b5cca9bda8;
			gammaABC[95] = 0x1e34e6368b9f299ef99226b7caef82bd89152e369aaeb509fce62d4d2b6ee95f;
			gammaABC[96] = 0xfdbf1c9c2db43f3984325877806d8d0ce956ec9fad8829ef64ed4ebbc5f0e70;
			gammaABC[97] = 0xd3ba226e5cb950483d8b7adcc1e51d023ba343170902727b8885d0eb72b5ed1;
			gammaABC[98] = 0x20ccfb3792e0a4dceaee9f898935648da699274e4e7bef88c40d2e47b882fdcd;
			gammaABC[99] = 0x2587ccfdf511ef3f83483c46db2806410d83ac9d156dd72cc5abfdc83c77b3d8;
			gammaABC[100] = 0x19764889a82734b5c9586f94381bdfb5859ea770362a38057dbcd84c4350f62c;
			gammaABC[101] = 0x17b79d55088123ee001e94cc50beeb6581f400e5e5ed706a5f80735bfc4415c0;
			gammaABC[102] = 0x2826c9797932577b08d8330206750f737f802762922d09338fd6333c642e9744;
			gammaABC[103] = 0x1f727580efd9ff0de5a0a49425c02da2a0f82016ca73e7829b2295bb2b899498;
			gammaABC[104] = 0x16c3cfc6034969fa1f1625dc0bca69100ba4490ff6b88f95e37711588c91e7ea;
			gammaABC[105] = 0x177133ea9f7db35b4ac995ec3ba092c2b759e1b3c0fad6507a1621b4befe50d3;
			gammaABC[106] = 0x4fe18b1db0a9ddac363c1fb1127cdac317000f93ecfc8e187e5e90f36cb457;
			gammaABC[107] = 0x17fd5e9e15a99afae9e7f1b77f7a6e13977f44ecb73c2ce1adc6acc77dc360af;
			gammaABC[108] = 0x75fb8ca5809936bd716a4e6ca264e10eaa46ba7275e3bed4df5080da170448d;
			gammaABC[109] = 0xdb0ea91042c2fbeaf8dc1c5aa9be851eb1c63b5df346e95bdfd03f1aaa8d18c;
			gammaABC[110] = 0x2983a63b10d8d6c9233c735dba1927e7e5d8d0dbf19bae41f1a3d5622108fb9c;
			gammaABC[111] = 0x2e055a990575a7387ff36167e004b003c52856e8649a6bfde706736f807df0b6;
			gammaABC[112] = 0x2d4e7701e2fc6177575d31ae8008a09cf0e64fd1a0c67ecfc1d46d9d50cc84a7;
			gammaABC[113] = 0xe5fb07d6e7f19bc5518d6514b3c5f26a4587684e759881a0139a7f4baf78163;
			gammaABC[114] = 0xcc09f70d2729c3836abaa4eb3373a595f1ff4ef15171ead1f45f7d46d721911;
			gammaABC[115] = 0x265e8fd094a9f2c2310de40910b5405ffd87ec24cbb471290469163d5d6948a;
			gammaABC[116] = 0xede1669b3c328ffd36dec3dada9895c805a411b7890c623443310fd38a8b958;
			gammaABC[117] = 0x14311bda4be13a7f3dcbf241024573192687035f385c8e29a8d73a16f855de5f;
			gammaABC[118] = 0x1a017aca92bd16fada118b521930962e1b6c8ab94dba8d402956ffaeb9cb44c9;
			gammaABC[119] = 0x4f78e10226be2340074e9e1b0806e6d3a6e6341dd37b24ebcfb7c1953d9541a;
			gammaABC[120] = 0xb108192da8ed320aa087c15b17ceb1007711f485b8dff6c6624d739b6d856e4;
			gammaABC[121] = 0x2dbca1655823cb5aa9f3f350f65e37047e7629e2c111fee3dd38518f8cc91471;
			gammaABC[122] = 0x1384a9bfc2e216ab4b5ff0a9f1f6cd0c92d42be2e4d1130dc30eaf1644dddb32;
			gammaABC[123] = 0x1ee5f96865f655a0d94c2cdb28f3726b9f6736c1b852860a70a0236628b87c8c;
			gammaABC[124] = 0x2e2772e0cce4ee1cc88b5b1c8a4c96cc8df50038d4b7c8dc7ff0c4739cf36cf1;
			gammaABC[125] = 0x8d534d05c72edf79563bc23b8b19601cb5a7f8792015ebb180f03995c46a48b;
			gammaABC[126] = 0x1b8c3f4142261a809f9e6ee7e4c3d8ece5b1d988854eab397013546f00d53a0b;
			gammaABC[127] = 0x2b287ccdede3d04b468daf74f204c5dcca7050bd50c198201f2cdd579595d43d;
			gammaABC[128] = 0x1f718a3b40a474dc79eaa03d0fd0bf99c7b3b49b8e1b9198995a47f4e6c69e9;
			gammaABC[129] = 0x220214dab431c84cb2d7d1e8ded2820e36beff3b35502950f10e84548cd6a619;
			gammaABC[130] = 0x87fabfafc01244c6c87766d577189c31ae68e16bd9da4b92b7af7f2e702b209;
			gammaABC[131] = 0x2974544052a6afef38f21b9f64ef9421118dfe2900c90b7dc479e919ffcf1a6e;
			gammaABC[132] = 0x2800833897875bc65f00a4bb5ab3d29d8bf4b279260c8b6ceb9456cf4516dcdf;
			gammaABC[133] = 0x15d290850fd1fef432a46fd9df8b8955f9392fcbe610071f947ba727c593d003;
			gammaABC[134] = 0x20e76eafeefe1c47532622d4b2c3566007fd80a5d0e58018e990d5ad686064ce;
			gammaABC[135] = 0x3da5dac8087b7db04758eb5a4699ce8f09de2e2be798e97a4e64ae2050248f9;
			gammaABC[136] = 0x2515d53f37fe091b6cbb26aae37af2138cd1fc3cbc55db6ba9113793ac126d67;
			gammaABC[137] = 0x111a0ef46e1b8f24e7fe31ebaf1b7f09ead655442fe86e6d195978d269ff07fc;
			gammaABC[138] = 0xfd5fbe699c3411e4c801842cb8acb112c6b1d760e1dbacec264ccbcbf1eecdd;
			gammaABC[139] = 0x2fe792b45a5362ec2c58404d499d3c961c024dcf49503ad796c7a43f0f42d59e;
			gammaABC[140] = 0x2e9b38a314d5881365e87d885c9746d4f78226f7d976900472de2ffcda031a71;
			gammaABC[141] = 0x6aa11bb34420756a8732fd86604a091688720849e5463083e093f6ee010d020;
			gammaABC[142] = 0x1b17e86cdb306e582b6361a888752b8ad24fe75728af26d585c13d5630d64a1c;
			gammaABC[143] = 0x2cdb584679bb7c0205edd8d6fbc6b533de59a1fb6b2b4ac69481bf6add1e81db;
			gammaABC[144] = 0x232be1a4a3de3a7df4d090d639c98df29293f4123198693293d277307836b81b;
			gammaABC[145] = 0x17fdc1d7f76cc9e04ae61ba0ad107590adca60c4156bf9db61ab24ebd430ae08;
			gammaABC[146] = 0x20715a0953f2c66f19c30e7eba7fc11f21c4ddcb9040cea9c3cb9b96be11a0fe;
			gammaABC[147] = 0x16b1aff5243734af0b46eb1c5cea91fecbe123a47bbec6057fddab072d384fe;
			gammaABC[148] = 0xb5cfa14579c9803ba4e09f62c15e63348f9797d0c1e98c6669459920e670456;
			gammaABC[149] = 0x299f0c8638d4f03d7caddd52a62e46be78d035aed0dcf03f70c9091fdd8bb19d;
			gammaABC[150] = 0xd937b5f6cf31116ba5e37f4c479dd88d7482ebd2aacc91235925c16511361f7;
			gammaABC[151] = 0x18f580c18fe5cc352e098ddf4bf2cb1593d2c912c8ced687773517c38305301;
			gammaABC[152] = 0x19562e396f1918728e33f2ab1c2df06fc1215ec9f4d43240fb5f30fcbc4a337f;
			gammaABC[153] = 0x4db9ae4611137da33fa3eea6773deeabceba7ca16918886deff0ee3aa10d396;
			gammaABC[154] = 0x2c27786a087dd6d8eb4586c5bdb116b1ec152f749ac61f59e98ea20b674c029;
			gammaABC[155] = 0x2e759dffaa2b4c6a40f78ec142c4fc11e1b15dd1354a217ed3a88dedb46fc36c;
			gammaABC[156] = 0x24bbda4f3ee74398c1dfb3864f54f104268c1d4df005604e74c3761e10e98e10;
			gammaABC[157] = 0x13890be14d8d2063669a3b8eb81042264f588a56ace18c3d2efdfef36f1bf0c7;
			gammaABC[158] = 0x1a4287821a2f713f3629d52c8ec1206128266408fdb646f62c14a6be006db092;
			gammaABC[159] = 0x24ed1234e3c371564d20088c43c92efd9b6469998010ba5a732c7e0ecf59970f;
			gammaABC[160] = 0x29862a3ba203f6ed4ed7bdfa5c12d0691b96926cf199e06b776b213533916ba4;
			gammaABC[161] = 0x776f6bcb483ecd39ac9bef2cdf639deaacb1b044f86df911ddd1d96ac9469fb;
			gammaABC[162] = 0x11a8bfc015689a97af62472000496c2702becbeec94680a644a3e54ed65d3f9a;
			gammaABC[163] = 0x14910ba8992704f2896e196ec31875416a4746c3cd9069f8fbf61c6615f2f58b;
			gammaABC[164] = 0xa84f9f338a032893fb9997dde8fad511bfc3662764b3fbc0716cc6e858f84bf;
			gammaABC[165] = 0x1ba95464889a142643eec63781c65a0528d96a7aedd01e37d90abe84c20e371e;
			gammaABC[166] = 0x26d181cdc23d6a8fa051232e55d7a44d43608914a560651a008ad83294aad50c;
			gammaABC[167] = 0x1bdd474bb2afdbdd50b7e9885ad6eac391322d151d09c4bcbf07db9a1e83d57d;
			gammaABC[168] = 0x1be0efc8431fb1eb0888d300d31a60e3ac3f9c017b1dcfd2df8a1137ed991eba;
			gammaABC[169] = 0x2ec5389ef62c6c442aca9c1f8aed42e24e730751f095c42b64147dbee7ec2923;
			gammaABC[170] = 0x2aaff573ddb897638bb9aca6288024965a425ca6f139cb831bc08894f5320ae2;
			gammaABC[171] = 0x21ddb271b484ca23b65559e3aa04fac24da0603a25ceeddaf1bd674461dc34b9;
			gammaABC[172] = 0x2104155099dcc369ded0ea613fd3a8875eb3d387f74abbd2ca385c0df4d42f96;
			gammaABC[173] = 0x202a9e46ef362f7b3ec370970697c597d1cbe356e243c72c9d4bc1eee4ecc7ef;
			gammaABC[174] = 0x18a8346354356150412cc554f3e41a52c6b14a1c2f1b98224bd072da2aa2e428;
			gammaABC[175] = 0x1e2679f93fbf7fb473e6d506e2d295760e5dd9abf15f7aba327b1a3b8c49712a;
			gammaABC[176] = 0xe1f1b65ea06f826154ace5915526a9f2097255018fb17217adc2165fa08321a;
			gammaABC[177] = 0x2fe5fa1052316968172ef9726eb7b23ad527adf6f0f172f0aad73425698be91c;
			gammaABC[178] = 0x1dbc0f1d2dbd2210dd740419c0125827c9211f1fbd6752d5cb902d06c482c72f;
			gammaABC[179] = 0x47a281b8afffea42d24249c909b4efa3ec719d508982f0da61d313e87113b39;
			gammaABC[180] = 0x14e186d720afe8c9fbed03599e2e6581e28cfcff8ae2d231c7c7b8765ebc8632;
			gammaABC[181] = 0x22d9f27210af15ae6f0075a5734da1e008f49ebd4049cf40914b6c99e469219f;
			gammaABC[182] = 0x1149b697fc6d604f3c48847cdb710fb546e0347d713d82d09446330e4269d280;
			gammaABC[183] = 0x2c6ac079356f599a5e9803ddf44d8b5a46f99977960761a166c3ebfb1a78759e;
			gammaABC[184] = 0xc36a53b8f9a72595e1fd3ebdf9f231800801d98eb7c6e1b4ea282ea56e6a5b3;
			gammaABC[185] = 0xc90c07e80c6cdf88f08c095fd3456666194d77df38a7a1ccbf0b4bc76ad9c3f;
			gammaABC[186] = 0x2107165151204b30b3c2a087cd748c860339ed0eb7486a43979afdd1d4d6eeb8;
			gammaABC[187] = 0x2684b90d808a61ba319222bda979689a3c09a3b63449a49a9bf1f31554b19e83;
			gammaABC[188] = 0x14e5f8e25667b213599c6d703dad6555ff2e5662f52805a3cd08b2aca2f684b8;
			gammaABC[189] = 0x2c6a21919747e18728e1b7b70bf4511f4b57bb32280c4eeb34ab68d927b06fc1;
			gammaABC[190] = 0x18d866cc6b889152c59f88c6de4d598edcf567f8596c8c902f8037cf5b009b27;
			gammaABC[191] = 0x231320dfd0d54282d660234c928ed4fafd7e740e33743e1c21de60ac385c0ceb;
			gammaABC[192] = 0x6e3f1399371b8cf20becaa2fd75849dffc36806008b1a41a2b27a19e37e5fd2;
			gammaABC[193] = 0x73ca8afd8d215136cc53254a5ac15c03f39b65f2158b0a422faf3ac781b37d3;
			gammaABC[194] = 0x2bebea93478501805ad4c0efcf4b6946b5e76c65d7078f4760e180059622a83c;
			gammaABC[195] = 0x124790c098b4897cf28b8c327275352468a53aef56cb06596f5e6d66c99ed4ac;
			gammaABC[196] = 0x70fa870fa91d4f96824034f721ae6bfdb1043adbf03b8f5c7d10704131efd22;
			gammaABC[197] = 0x49f7747983dcef6e74a71bfc4ad3370f0dc8194e031d02a44f9ee7743704ba6;
			gammaABC[198] = 0xbf6cf1fb59e292b43936713c6868e7ce8cbf0289425ce2c82d9b4eef9f381e3;
			gammaABC[199] = 0x26ea46a037c25d6f4294808c6c272a3ce33acd5f5fe7120a15f6931c979eddd9;
			gammaABC[200] = 0x16f545a362749d9319f7e8282b3ba53c76c2673b8dc1a4d8f72ba9da32ffa75e;
			gammaABC[201] = 0x1c858a549769c13dc46d93d6cf85f43438ace27ffa7968c40c69aa2fd1cca008;
			gammaABC[202] = 0x1afe9e0c9273e5e520e4c3771cc4b84e781a6ed1a95d71b70137f540c38dee1;
			gammaABC[203] = 0x164235452dac277a9b7d32005e2bf4ce8046e86ae4e5ac361bfc0421bbdf1ca5;
			gammaABC[204] = 0x1c0309d62663eed0e92bd9b0eaa17bf6a0b4523315487954b6dd5ae1eeb47e67;
			gammaABC[205] = 0x1851ebf281b826a050f497ac461fc12bf4fd8e04c96a83813742d4856742772;
			gammaABC[206] = 0xc5d680fedbe308405ef2d8015cff0729e2488ae254d7a05a1df2f93d89c7cb8;
			gammaABC[207] = 0x18e013f5705418a9de968bf8392263d1ba94c4993fcb4a094e64ace129cb7686;
			gammaABC[208] = 0x2a74c6fa15140481ecac894aaca3b7ba9d234567d14dfbd33a8d1ed18a0557b3;
			gammaABC[209] = 0x2a1b9041675efbda131bf301bd7454bc8e840a8fabf9f0975356166260b27e13;
			gammaABC[210] = 0x216fd5d911de33f2c54476f734229922b82f3726734698c1c621b7beb5920e3a;
			gammaABC[211] = 0x2f4181988c50db8e8ac8fb66d9076ef0b0b73b2c4ee712591443f032bc618f8b;
			gammaABC[212] = 0x2fc7ae8de6acac16e7a170942a7f88764c95b952e4ad5ba3a9acd9aa3debb668;
			gammaABC[213] = 0x1493cfc22c9ed3a1c5c6969800274ba544ce891510655081951803a6500a8297;
			gammaABC[214] = 0x1fa777937e35c3e9c9e38327291c14e4a5f58c8b3f90cd5d492fd31513a7d315;
			gammaABC[215] = 0x710392d50ec4099bb3ee1cbbc34352de3a20fc5f5eac8d8ffd35e73ab4629f9;
			gammaABC[216] = 0xd1b5f3e58bfccb94ef312821a86ab50a8818c38d98b836f72bd86e975db5e8a;
			gammaABC[217] = 0x257db16159c693a93edaa21a06ad7e12693c21f1f37c706d85360fb23c37508;
			gammaABC[218] = 0x43826844c6ec77a39f2cc3bbedccc5f6a0d4e193133c5320f11d92aebd9aaf7;
			gammaABC[219] = 0x175a9265505ab5680f5b592171bfec7efb06eeab53d72034968f72f25c534358;
			gammaABC[220] = 0x1087767ed4231e46e2f5f254d17203be04c3c8e1f1968c244fd1450e3a2f246a;
			gammaABC[221] = 0x29a3bb71e0e96e6f88de204868ea4cf6e3dc08bb98a871472f45fe5bb496de0f;
			gammaABC[222] = 0xf01b40294509f50ddfdc86e243e2365e1da573f9480d5ea51d22d7dfde8eb5b;
			gammaABC[223] = 0x54aed44a2ad053aafbf5b1aede9dff7b896830cdd6fc97f236a99dfc02f5af2;
			gammaABC[224] = 0x673742961f325c5af6463f65d449c149bda59dfc82f84ba6d5e5cb42e08cabc;
			gammaABC[225] = 0xbd1a5c6d5ddc6bfbf48dc99b192a8fab9e1859c2acfc143689dab508e95e42b;
			gammaABC[226] = 0x2580203fa5afb982f9b0b8f398154f5f6eb1ce9a6c7c37f465e0d6e28016f60a;
			gammaABC[227] = 0x42d1f887615b99be3387601d9015bf1534c6459f9b7ff714be0c99ac718f158;
			gammaABC[228] = 0x1526f049bc4281312773c34b50376fc95fd07b0bd4ff3fa49787667273ecf904;
			gammaABC[229] = 0x1c1e4d3a2bf59a0e5756f62d4843fb180cf08e099bf634cbb66d92d2d6b21b78;
			gammaABC[230] = 0xc7917f2fabbe841074dd37792305ebd882e54d56db486c6bd2c551e1789812a;
			gammaABC[231] = 0x8424fb9cdef75f0ae514d6272998e98656c7b0a5bfa2e63c510f1e29c42125c;
			gammaABC[232] = 0x1902ab3a2919f7f87994e2dd35c93cc08bb6a06699ad1bb3b8e14c4a7a27d2ad;
			gammaABC[233] = 0x202a54b1e19f0e79ffd8308c0304886db6f2a3cd4b7a5454c1ca4de4c36f422f;
			gammaABC[234] = 0x14daeb31274d6a26e9fad0ec1ea12bed8c20deaafa4ebc4579e8780300c894cc;
			gammaABC[235] = 0x18cd7c70db3314ac3ab01fa92232f9e838dccf9d727a86d3dbc6946f748074ec;
			gammaABC[236] = 0xd51dbaec875b88e04fc1db11d765d6f79ea40d44ca2f1bc30b032366a49e1b;
			gammaABC[237] = 0x18128a41e1b12e343afe10768082b1f0bd623dace836a6a482a5c2c2ec82ddc0;
			gammaABC[238] = 0x90178afa20589b17e261bc40c64e1ea8a9740f34053bc663e180479180de42f;
			gammaABC[239] = 0x2c7901486d2669b79eda3c43fb0b7b02dd46430b07ba2e5e0915def3a1a407c;
			gammaABC[240] = 0x1910cf10867a2b30a9145aee45e4900bf320c0d76ff63ffdada9cb8bbb13d642;
			gammaABC[241] = 0x98977520262b2a64a9f0400e0601f2c3e33c5d0641b30f1c23f724712bcdc6b;
			gammaABC[242] = 0x2f1558dc00630a70ea7a7824f5cb014b8ad067ff1983f4e6b73827be0218d245;
			gammaABC[243] = 0x19305ea2f156a3d2dccc3370db82ef68654e7f60d7eae3ce06d0be0e3814208f;
			gammaABC[244] = 0x1e68bf5104262f029332b288ae0370ecf0a5ea2b9cede9ecd680cb8c9213b429;
			gammaABC[245] = 0x1e4493fc20a8f1e48e96b1d6cd02e8d7e1e360e984acca78aab4bd76e42db4ed;
			gammaABC[246] = 0x268cfa3ebbf30576b3e8b4fe009022a7fad2229ca14a05422d6e2e4e54c9dd11;
			gammaABC[247] = 0x22808b985689c60364ca0a29af8649aff49a7cee7ff987a6552270c5a3fa8f66;
			gammaABC[248] = 0x15c816d914bfe1546a1508e30f8133acf839ff99cb7a9591b16ed681f92594b2;
			gammaABC[249] = 0x19328a3b4470267671e228235b6553bac35e83b25e677e316567f8057b6f2984;
			gammaABC[250] = 0x12184345ea0e6f6795d5d435696171cea9f6988ec7162ad9b6ea700fd40a2064;
			gammaABC[251] = 0x77a41a86d7c1563b99ea6cb89302898770b985f4b705d60b574a52df5060513;
			gammaABC[252] = 0x7ece306d4b6921e8eac6cfbc785919cc962c72c030f5d9181d174042ae1961;
			gammaABC[253] = 0x156dbc59fa37744fd3f7b535bf3bf13e71e175caf4ea35c0037be06e95c9440d;
			gammaABC[254] = 0x1116d79307645669c034ce439f12a7a271c5a078383f2b4f79e598ff38733231;
			gammaABC[255] = 0x30010a373b848e9bccaf7ae092cb37f8694ae703aba0619995660e113958d5a5;
			gammaABC[256] = 0x132ac3b0eeead271c11248aee238f8668037f59fbd28aca7e3a91a1fb1959e9e;
			gammaABC[257] = 0x217af7dfc0c1f024dfd33ff7921b3b8039ae290e58003dc1539f3ec05e9a134b;
			gammaABC[258] = 0x1e60924ad60e3a6a440d7cd50b9578c124ff09510b8e88616ecb9b7fcbac1ea4;
			gammaABC[259] = 0x970babb50b3d76e66134ac6c163e41abae30fd0622a2952f30673d80384ee75;
			gammaABC[260] = 0x22ccb5efd467fd2fdd89819d4f832c9c0eb3d8c8aa06488c3b2ceeafd40c9932;
			gammaABC[261] = 0x1ecae7fb5c3cc37856385f18faf4328d314c03c4b5395a394998ba4a01bad704;
			gammaABC[262] = 0x24030ca65e38df18473b84f32f58f745beb2c43f5470b1170420dc0d08e768d;
			gammaABC[263] = 0x1212bbb2928b6932ff484a1221339ec2285b37834fe701f04431714d75da4423;
			gammaABC[264] = 0x2783e07dc242f28a11033e1619d832d0073827fcfa7ddc8834ab899eca01c3ef;
			gammaABC[265] = 0x2a8014c56364327e8d1a2bfc0cde4b4944ce0678d2b9aa6365b9ceadd1f55ab7;
			gammaABC[266] = 0x1de84ddf81d372c99d70adbd08ee04bbe45476253431d270889486aa933abb4a;
			gammaABC[267] = 0x2e30056d05b1c2f5fa8515aa67bbfc9521d1c71464f680879f6e1effb581a056;
			gammaABC[268] = 0xb52504e7c9df0bf2dd1440df1a5a57f7a19d36d5541f5d2fca58ac4dad6b403;
			gammaABC[269] = 0x1ed948d2734f0c6f14d5eef2659f0a2c74bf46479fd74095d1fab79abef150f6;
			gammaABC[270] = 0x2161ad24c655ee2b0d9eeb0574d1036561a7f57f4fe6e6fd5d5355dd87dd8f6a;
			gammaABC[271] = 0x9b947577674db0dd224c79b7bb7bd170174ac410e54e755e9cf6e08e344b44f;
			gammaABC[272] = 0x2ef2dfe742822c0a6e4f5bec91cb1a5adc01761589e0005ba2720d9ce42ba86c;
			gammaABC[273] = 0x6d1974d563d0a6a55389d996eabc6ea35a689ad8a683014639d72953e723640;
			gammaABC[274] = 0x2a1734b57143c471766e7fc817b0c9c419d714c543a8df45eba7eb51951d748;
			gammaABC[275] = 0x2849d30523ce9104184f94237259830e6589f7e9659202ff0d140d5e1bea65c1;
			gammaABC[276] = 0x2887ed643b4b5ace705bfd31f44e9577af612d45a53b6a87d3453ce1cd50944c;
			gammaABC[277] = 0xd3dad0aea8601543f6b892fba5e570a7ff728c1b692361eed025724af35347a;
			gammaABC[278] = 0x2f5d778011449d2defe6f1c41ccfc96f09e7f5a065875741210ddfc1d54f9948;
			gammaABC[279] = 0x46b7d6383101f75f37244b0411dd6e0a0ee20b8adb0c30a1972f823a901395e;
			gammaABC[280] = 0x24a388adb86002ccfc741c4eba8e5deca2c9247f27894fadad7095ff4ad311ac;
			gammaABC[281] = 0x1902dc1e472e49c9eeb2d395d25041fa33c846f173a661fa40310841dacc9ed7;
			gammaABC[282] = 0x1f35a0a1deee5ce285f9a7b685126a0b32bcbd785c27fe920fe7743cf3cb14e6;
			gammaABC[283] = 0x16099596dca020a90428d29db5ca0922322ca04431701a1ba3f7a965b88bd9cc;
			gammaABC[284] = 0x1e8be39939a87ead16b2006f9e135bccbfc4968ae1295603f5ed263c54356c71;
			gammaABC[285] = 0x98f2021b04972f3d0bf21e4b67937e19216b2e3ce2d86cdcbed4caa1d182e48;
			gammaABC[286] = 0x1d88c57a74aa07d2d2419a61c40c1219fbceb75d27a5dec9b1c98f28e03bd9f8;
			gammaABC[287] = 0xc781d73e90291565d8f71616e462ab74b89e689f67c120eaabe6db28cbab7ea;
			gammaABC[288] = 0xe8e7d1a7c8ef1da9bf89826799439ea255a86af9d727039dfebfd62909d3296;
			gammaABC[289] = 0x1877909fd7c7ad28d9bade145754436d01bc994413a640787bccb66491db0b1f;
			gammaABC[290] = 0x13d93d3281781f484c66be771177cd3d79e4dded9dc463d8eddaa40e352f31d3;
			gammaABC[291] = 0x11a4c02742233e32b4320655e2bb72e13fedb9e2f2dffa7691bf412f90378cfb;
			gammaABC[292] = 0x2862222310b763f5d76eb6c9f0c464cc51477e0b99a62e37cb2050b1d72ce877;
			gammaABC[293] = 0x163b2fef6300f909fc2cc01b8ccba10fa599b81677677261341c4f68c3eb9bae;
			gammaABC[294] = 0x1a0d8107163ecac42d154abd41627e1bc5a99cd26729d64fbff8944a09ce6016;
			gammaABC[295] = 0x13c3920082c8b9042dc8fe51ce6c6e00de4eb0d4c1cab508bd423030967ca853;
			gammaABC[296] = 0x2f2217d159b5423392bf3fec20bcb87402e2d795f0e734612bd211fe28b6e8a0;
			gammaABC[297] = 0x82507d2662359885b59f339291ff827e1199faf7fff6efe9616746747e9f8f7;
			gammaABC[298] = 0x1f88ccd5ff41be76fdf1dfd0c9cdea2df485344856d379a15565aba16b7573dd;
			gammaABC[299] = 0x11a3feb7e3c104a0410882112a07ae42a68b4772e629f28a231f10ccd45918a3;
			gammaABC[300] = 0xd67e5690f4fb2264ba6896610eda31e5f607616fd28300339f43f30af1970ed;
			gammaABC[301] = 0x255ba2ff7ea18912d5f9f23375406916d783198aad08cbef0fdfd3baddeafa1e;
			gammaABC[302] = 0x59a321305d13ffbda96abefd21271135ae2ce0f6c1a75bbe0985ac5ce9f0151;
			gammaABC[303] = 0x167a6fa07d4b1ba725ff7ec4195ff521a3fbd519e3241d50abd6a6c6aefaaba2;
			gammaABC[304] = 0x2df7e19deae6b2edd51895721633b716da9d81b28f1e8f67b6352a554442243b;
			gammaABC[305] = 0x573cb137c2a6f44fe55725c6e662673afdeebcfa545fa567531c28d88fcf8c9;
			gammaABC[306] = 0x16f6d06d64940c025d9f7e4f3e47cf1464f62704c0bdbe24fbe2dff4a914b063;
			gammaABC[307] = 0x16a19a1c633fa685628206015bb826e6f80816a1539a43d39135d29c2b5e96f7;
			gammaABC[308] = 0x10bbd496240ba9cbecf7c366720ae70b7e384f85eff1eda2574ca7044fb97c5c;
			gammaABC[309] = 0x1834f1af382128f4338bdde6a196be42c1db383bf95c6e00d4ecb7586505f1b1;
			gammaABC[310] = 0xefa02c4640cc7f9b258554e471ea7cf1b6716173462128f503ca0a2b6e4ed06;
			gammaABC[311] = 0x1e65ede72347993e6f8863bc3739bbf3eb676420a654a98272e0a3b292739c9c;
			gammaABC[312] = 0x22777b1bdc79cf724030a404306d1c75510accc71dbe49a7e75fc82e2af5b496;
			gammaABC[313] = 0x2f84786d5cf644c7891bcbee84992fa3317a08861cd888d667047bbd9f9213cf;
			gammaABC[314] = 0xf64319e280de23fb191b69560ed146c8ec45d249d7f2243398521c561f8b059;
			gammaABC[315] = 0x208c9f65bbc4a2b43d9c8a15bc3698abc03f92c01653f8e3464d1d1eddd1139f;
			gammaABC[316] = 0x19811750ff7b6437daa98981ff3465795df8826d796ada5d4780d8ae46baeee1;
			gammaABC[317] = 0x1efdfb2121ee4eda53d78e82ba2642aa32f56d5cee54f797b90d4bc6f734679b;
			gammaABC[318] = 0x2995f974ca05c352f32f18287f0a94c10f5177aec24d149be6369f45adda3a4e;
			gammaABC[319] = 0x1ac37f2eabd8bd653301875ae66e8893b424680ed0744a4dcd2ce6e963bb75a;
			gammaABC[320] = 0x16eb0329c4dde932813dc04fd4593ae1286eac999adcb1ada681a1f36da8e393;
			gammaABC[321] = 0x1cafacce4624b6626267f9af46e44b7865560fc6a58ed58fcb7db423ca1d8b54;
			gammaABC[322] = 0x15d89ce4c0841d6b764653764b717efbfe911397371cbe0e4340fb47f2b53749;
			gammaABC[323] = 0x20f327895cb09719028c4e684170ca631225424157bf8b691bdc94857b863cea;
			gammaABC[324] = 0x1880bb4a7b160fb054ea908c22c8034ab37b434716ae6ed45e6868ece7d58df3;
			gammaABC[325] = 0x9a4ddf61dfe1144be1431faefba4cb5555470382855e906333facc094cc4e57;
			gammaABC[326] = 0x2d476eddc8aa552595169ec6a57eb7d0e0298c8bde0e5117db38b0043afc32c4;
			gammaABC[327] = 0xc16df168afad189eb3cf37d98a06544f0d17f000fb9b4cb58c8537a847c968f;
			gammaABC[328] = 0x1aab1b150c512f2c42bb5cedd07778c0782f3e4e736087fcfe0a2877a7d16546;
			gammaABC[329] = 0x160fe5fb0f2c28835b338c483547f233651845ccaf65a4dafd8f360c0dcfff1a;
			gammaABC[330] = 0x2a76af59d6d3b8148642c33c09cd3169c3a68b6ba04d2d30f6551cbf2110a55a;
			gammaABC[331] = 0x19c6dd90f4b2df192fa9b5bd076b12f31bb659600ee7c0acd0e227fae5ef0742;
			gammaABC[332] = 0x12b22bf1a39c19459f470f4f5a2b2094f1249ec6f65c19b27097df83fb74f8da;
			gammaABC[333] = 0x1f7b6cf6be7b2a4e34bb376e832805436d86703381901461e225fd993b8d8a5;
			gammaABC[334] = 0x35e36505b88fab899dd54b8257cdbec57dc1ff779e839b86bdd21d9322afc9e;
			gammaABC[335] = 0x207965df032557d50ef9a36d13f528937f67c86bb568917d4addca03d0620ea8;
			gammaABC[336] = 0x255cef0cbfedff5b4e77c4dea6718a194d132d87825592b4a5694a2760436c7a;
			gammaABC[337] = 0x28ae51c203ce3861ce2ff10adc31e89341a0ed1e55cb773c92ce5fcbf40c9aae;
			gammaABC[338] = 0xce796ba615cc3194c1f7b2bcb8e96de9d105a2ddb65b5ad832734837e4c0cee;
			gammaABC[339] = 0xe3a55a63c747054b463f4c3045d8c7bdac01b095f6c1dd21462e120c03d518;
			gammaABC[340] = 0x4759852bb8a7e73c339a33c0f7bbf95ccc75cc1b68e14ea72d425399f71463c;
			gammaABC[341] = 0xea6aadfe352bab7d7959f20018170147d910f34e4b0824e8b7370983b005747;
			gammaABC[342] = 0x11cf0003825abaca3f68d9164bfe0fff88f9147353be96175aca05c5bb08f90d;
			gammaABC[343] = 0x1c603bd79dc7dc9f079efd4ee965786f977cf19b1886e95b2a9e3dc94d73faa;
			gammaABC[344] = 0x28b23c60ddecc00f35152ceee61e156e8c58b0774f9cf73a66a724bb3b35bf3;
			gammaABC[345] = 0x2e729ffe7d1b02c579503d0e19e8c553c54086cf34d71828738e11530456bf54;
			gammaABC[346] = 0x25f43ec8a055904d183c5f818e443af32d957fffcf8479738f904d6da15876b2;
			gammaABC[347] = 0x17b7b9a75229803e679acb00994d434fe95ce4b6c4db6d68cff64e53bf577caf;
			gammaABC[348] = 0x289f2a57c0347d07dfc08c181a11edda40594f71d5f81ad382bece132149e669;
			gammaABC[349] = 0x6cc1f9a1533e181575463077984ce9bb0747b42c5e2d3f5ce799db35dbed1c2;
			gammaABC[350] = 0x164f8978cf43bee85335bde41855771410eb1a7cd53f710d0a76daad744254fd;
			gammaABC[351] = 0x2ad4991f07b0546f84210b032e0a5b3f669a9a4591cba65e4be672b4a7189230;
			gammaABC[352] = 0x1d2a7eabc5340382319f9cb6f7b70ce7890d9df0cd3370308cb78f1a86d8ba61;
			gammaABC[353] = 0x243d0f1698f43e73c7ebaaa1ad9b54e7e16d27ad47444e0bbebcb0ae941544da;
			gammaABC[354] = 0x17cab27dc29d6c5725776888666b9204027d907d0438a2bd5e62daea2202e99e;
			gammaABC[355] = 0xd145c337395acd52cd25bc25aad21ad9ed70a570cfed3329d74299a173e4ba4;
			gammaABC[356] = 0x2bc50662dd421f617329f1b8e9614455a1aa3e766754d743376f7ba355e9eb8c;
			gammaABC[357] = 0x22a760b6776c7896dd657fd6273859e60a64ef44820f35a10ab3560e10fa5bf7;
			gammaABC[358] = 0x43986e78039526c2df9df87e8e61f8656e0398eba3762d77c12359093f516ea;
			gammaABC[359] = 0x1ae428943e60821639b2cf7ae13ae052c331485857d908016b10efa3b111007b;
			gammaABC[360] = 0x480a8b2e4e53fd0ee2bf12f6c602dc0911adccde24e48348e866fd0832b101c;
			gammaABC[361] = 0x16737b71955e9c154475c47af9bb2ad39e566228829e15fc35c66643b5f096f9;
			gammaABC[362] = 0x2438a5abfbaf48fc83d9edd41a8d21d1088eb2ce1246a0d13789e73c1e1960e3;
			gammaABC[363] = 0x17cee5d273cc5b89eda9b26cb0bcda70ec0c075f62d5ccad7f9924146dd819f4;
			gammaABC[364] = 0x233531762079a266565196014862077014668de6969ef94518ff4088b5b08b3e;
			gammaABC[365] = 0x2292b9b953f287b1643dfde656cfbc638887cfc8b31ecdaa0fd796c179a48bad;
			gammaABC[366] = 0x1af2b27e68a6f633306f448fc71cd5fa809927b536090e4336cde8e062fa5b72;
			gammaABC[367] = 0x176716ee64860c6706c48236765852d958da3194e9bde65e2cbbed2bc8673f75;
			gammaABC[368] = 0x2d8d041e686a9f1da1687fab0d91457e7de693fd52be37b7f81ccd83d39f9ce1;
			gammaABC[369] = 0xd9077e28bce82df68876ec55f73eeafc3ae1b3c101eb353ca53577b05a6e8d5;
			gammaABC[370] = 0x25c6d1d62631d7cccad8b82216a0efea5d1fb3f7d94d9a1cfa0b2aa0dfe8f164;
			gammaABC[371] = 0x411d4157bf6f42824b1c18118782ca74d648fc58d34640b56ae2a5a3aee58f;
			gammaABC[372] = 0x9c8ba62c7036457f3815ff366bcb866c3568f8a6863ea4973b36909c85c0512;
			gammaABC[373] = 0x1b88da1c8659a44993a9fa8a4d0f5d7c49827b6dd639700c5b68663724bf60b1;
			gammaABC[374] = 0x26814fb1b43cfc62c51920ba659d9b19004683fc3edd40a485ea35b421a48642;
			gammaABC[375] = 0x2f0285a3cd03678a49b281af0cc06d6eb75875a69884285223290a28673457dd;
			gammaABC[376] = 0xcd5f07dc87f7544d62cf726f0c6e67d5d20b216f0648cbe1c90950572149cda;
			gammaABC[377] = 0x1178b807bd91c025b4a0b0d264e41d8b53d44a71b83b3c5bac8d77b9348a9897;
			gammaABC[378] = 0x169059017f3f8fddb3bd38c4f21fe4927517eeb5c85292a76f4e3bfda8f4cc21;
			gammaABC[379] = 0x1f48192075c69046129656f292631cd2a9048c149da0085a7f1a27679960d3bb;
			gammaABC[380] = 0x278e101c117ba85f826fc20f266a373a9116abcd9bfcf8865b2fc921ec61f8ed;
			gammaABC[381] = 0x209e81963fe251a1638b47af96560c667dc5ffaa6e3a0a2d763b22e4d8eeb20e;
			gammaABC[382] = 0x1b9208f6639801d86dee9b5bbcd26eae394bd3228524ed023a78eb5ef96a3df7;
			gammaABC[383] = 0x11d92904debf7d37106b9dff6680ef5679a3c31cd44f7ef90a63a41bc1238453;
			gammaABC[384] = 0x380e989d9f9965a72111415bb4b116017e0310d719c3d35f19da43ebc2bcb26;
			gammaABC[385] = 0x2b24ca7ef81d4552307bb5e2fa45675f665aed059eccd88784ecca231bd1a721;
			gammaABC[386] = 0x361192b470e41eb88ff632a8a61ada5e04ae7c92c68562b81a10e50fe771784;
			gammaABC[387] = 0xb862023d087b7884c812a6ed309e415e6873d5a54327ef7eab45e35208d8715;
			gammaABC[388] = 0x2fed6dc51114086ef1b92c02ee674cc0c3ce0864347e1cda8d13db90737c22b4;
			gammaABC[389] = 0x1bbb59295785ad699b0a1145cedb2c65513eeedc252328e86414b87a1149c646;
			gammaABC[390] = 0x2a44beaebd43b604597f674cd788eb04eef8639d7d8e060e411615886efd9e28;
			gammaABC[391] = 0xce612a99bf521a66381e78899df5720f20326e4824249197cb546d9c0faee0a;
			gammaABC[392] = 0x1f50b2060c5960fffd7a5da03cee2a734d70452547315b85df0da03226d8f29;
			gammaABC[393] = 0x1918c021b52de1036aeeddb3265636a890af21dfbd81eeb6081825091b6479f1;
			gammaABC[394] = 0x1e217f656b75ddec2fde5b7dab0a7a3ba705219549f681be775e6499ed524824;
			gammaABC[395] = 0x2c05a1cd6efec634a6b6ba9916f60549adde44f8fc0da830d2a04753b5f4017e;
			gammaABC[396] = 0xf751c37815cec962e50f31444641b8759b080ba23120a0ebad8b748281f0ac3;
			gammaABC[397] = 0x1c95a610c020e0a4189e40b94d918861c726471920d64df8f14d5a7e6e9d665a;
			gammaABC[398] = 0xb857b0594c94e4184185b1592ade940f49a4166da1bffd6f78de14597c08ac9;
			gammaABC[399] = 0xfba649ddd8c709ab35d6f9b95ff13882a0caef32b4f54d4ffeca9ebab82f334;
			gammaABC[400] = 0x1b8991dd57a519cc87668fabfdfd5ba2a5b62fc09b6b773ee0ca62ab484006c9;
			gammaABC[401] = 0x1397f223b240cee1c4b5670beea706d690dbee56c36f2832618c63b063663fcd;
			gammaABC[402] = 0x12bac219a47df2494395d6e468c16751d200a2c542ef5570e90a850711970ad7;
			gammaABC[403] = 0x233012ec6973bc9699f2375a4411f78bf5f529d580d8b04017afc21e141c16c3;
			gammaABC[404] = 0x1f3271547940d0e30d13cec332c82939e4001456c3e190c4078a8a9973dae5c5;
			gammaABC[405] = 0xace929762aa4657cbdd6f241c540e6686f3cd43f95553a5e0b9db19df6629a7;
			gammaABC[406] = 0x2c473276b23f112f496ad810d9b1f615d1c64efaeb551efff0aef6bfe74fb86;
			gammaABC[407] = 0x5adbd351ec2afc7eae9335570a551c5fcd1c4af4f3a0165e7cc826828ecab4d;
			gammaABC[408] = 0x1c566088c4829e9d687dc32a162a2d06ec84c4d8e65f8184e73d1d72b54d53a;
			gammaABC[409] = 0x26f7acf7229b015446318ef1d0a5ec28bdf5d54cd9bd734352430228bca1f2be;
			gammaABC[410] = 0x1283a01838563664979b1968c8ffc5b86d4c9aec3b6c7aae86e75405d46495a6;
			gammaABC[411] = 0x2c160c0ff73ad3af320ac36dad527aac60e58cfb34880124c4b4336b1e44e4a6;
			gammaABC[412] = 0x1f051ca88a8a97b60ce6f13014a60576ea37e6f36264140ed5820bebffb3c37a;
			gammaABC[413] = 0x7c28c1cda9214c06027f82c0f0e4fddefc8ed5572ecbe906e5d7829b3333459;
			gammaABC[414] = 0x1852bee8ee092a0a8e5ee6bfa977f1ca1ca74171b3883dfb5baf65f9e01dd342;
			gammaABC[415] = 0x1523ca94fa72c81512cb9e7bb180fe2851e2396dc0dd671517f5a9c21b3bacbc;
			gammaABC[416] = 0x244cecf691565543f758da6df7aced48aef8685e192239eca3efe7cd065605e4;
			gammaABC[417] = 0x8c8206a37756ae54df77c387f636feaf113b247b3e35cf5cd9102f8d57d3ef7;
			gammaABC[418] = 0x14fdb7438d7d1963da7bb70ca5ff2229d59c360df61160458fd8ca580bc913ac;
			gammaABC[419] = 0x2b7d4db8a3e0d22dd225f3e73165644d22d215ec55b61e637ae6b10d0d8cda09;
			gammaABC[420] = 0x32f78b665e4777072928eb6f788d615d6fa8853b22d3ed0852a7061e7fb0e9b;
			gammaABC[421] = 0x29949f58cf470bd20da8fc311b8f44132c5a779080f4079ad6f7418d8cadf750;
			gammaABC[422] = 0x26c01765dd270e1ee329902155d15c5888a370d519d46c96d157ba88c2979f29;
			gammaABC[423] = 0x238b0e9c0a053575c3820082d21a54843f3fe21c6da8cc2098b07b9bef094c85;
			gammaABC[424] = 0xa66f7b0a96e0616fc7559482bc9e58e3c1b2f4cb5fce1bc1da1c34bde84d90b;
			gammaABC[425] = 0x17fa8eb1419f5c283690cbbe5fafb07f4088d42fdecaa4244702b8676566e968;
			gammaABC[426] = 0x1464d535c0eb26536e238bf5dd11d2f1010c211a3a299e310c3d337c022deabe;
			gammaABC[427] = 0x270a1722abb01a442545e6b1f64cdda3c8f7db277e44f94fa7911a741185573d;
			gammaABC[428] = 0x1f0131a6c186317c4d4374aaf72b3ff99d3c7034e493f2d8ce4e26a8fb64d36e;
			gammaABC[429] = 0x28ac2e77e2464c815dbda5559a1709f232bf8d459f5aaaa4a72c301bf14024ea;
			gammaABC[430] = 0x2335e8bdc2c4ea774c1d5e053ef5833c472cd8cd07fed5e20e17cf3751c1136;
			gammaABC[431] = 0x731269e2244349ad9ef89b384bb32db78cb8b4d525c29b07915f21f2d289555;
			gammaABC[432] = 0x3009900d05a63618c0a9a3faa97b1177a98f7d98eea62820fe091e0274194f3b;
			gammaABC[433] = 0x180277dcb3af49da93f0d4b244ef4c620c93a4f2a7b048ff77941fbdfc3d043e;
			gammaABC[434] = 0x2535baa2041496d5b1fa8aa1d3408a73d327f3b3b113dc95de53602e371f1925;
			gammaABC[435] = 0x2e203d6345e352288271f4a073831b0a04277c58d89773e3c757a6b48a5e0fa4;
			gammaABC[436] = 0x2675fef3cb5ce1f941dcf02999b4364f1133ccf03425d5e88c36cb82eda4f52a;
			gammaABC[437] = 0x29316bf6564cfa9e8920a79abc79ef21f20742c8303e728ef42f5f382bb507bd;
			gammaABC[438] = 0x59d15b9aee90bd9ace690ade1fef7788dcd30238f10f146ea33f0b727b8a5b8;
			gammaABC[439] = 0x2393f9b806ee9997c1ea38054d273a74679608c58959bd1139aff5ed7f6bb4f4;
			gammaABC[440] = 0x1efb515425f4772fdb0a3b49869d3aa1d5454c7869725d58d4e3b6f36ece49a2;
			gammaABC[441] = 0x2436ff673e63368cf1852898d368882617f726cd7d6681af7abff3d1d7c15ed;
			gammaABC[442] = 0x15f6fa7e6a35da759aff99945af260e5928f99a2a5b5dd62fa3ef384f8764e7e;
			gammaABC[443] = 0x2fa4a982a2177706a887c168a1529632946158d37abc1d8f6fd4b9874dd13792;
			gammaABC[444] = 0x2a487cc28c6a1d8f8aefef976441e9f7e2b13676e8f75019e6d44d89f64337be;
			gammaABC[445] = 0x2796204423022671d6f6ef5adbddc10251b7e79cdaf9cff798770d9c4e81d52c;
			gammaABC[446] = 0x1b0dfc1390e0cf2a2409fbec525f369d6090e7813815a982b0fa5e3d371f1b9f;
			gammaABC[447] = 0x59ae92869b801f71fd94f83bd7ad43208f32a7d9e3f9a2dd4d237cf37b4c1d7;
			gammaABC[448] = 0x2e83154b6d6f08da5376d38f736853300aaef326f3d6313ea6e5c27e1812d84;
			gammaABC[449] = 0x28bbb6f4d7d10394b7ad1775ce532bcf660d329fed6d7dae75c139835dc6a323;
			gammaABC[450] = 0x148572e9991e0a19ee27c90ed6e9f1a80d0a93edc320e30ff332811259b8f61a;
			gammaABC[451] = 0x82fce74e03958ec9f51c66111dc7c2fd9ba75b703169e30468b608e313ec501;
			gammaABC[452] = 0x136f2366263e677a136150ff3312fc0f1e407e7b41e862ca1f5cea583d4feef4;
			gammaABC[453] = 0x14f3f930987ab853697a506472e98beec255d9c5148a4c4cd5edf2a5e32bb54b;
			gammaABC[454] = 0x6ef49bae1b184f448025608513ed0d901fc88f492b7c9051d9b3dcdf447eb0b;
			gammaABC[455] = 0x1c7bc834f03fa2e5adc20510afb4728fb83e6afa779fc9c33769c8715bde523d;
			gammaABC[456] = 0x13edf12b24744f15f5cf7b74977219f173e018597f9f9bb073c4eb1c7af283f;
			gammaABC[457] = 0x1700644d95debf4183d7a934bb1013af11baac25757ee77245b09c49182c4937;
			gammaABC[458] = 0x23cc2ffa6faa2f5c01feaa0763f3c6b0b079d808bd6f93f9df54c371dfffdda4;
			gammaABC[459] = 0x2e4b25547f01901e0888045b6f0dc7e22da9ec8e66e56c04bedfb1ea62618de8;
			gammaABC[460] = 0xb4d8b3e103260f6a0b124d733a9af5bbfe97e89eb55b1a63b746049bdde498d;
			gammaABC[461] = 0x1f50487b5044bfd4b957bb20e83a4ee6a5dbc590a9a37fcfbd70415fc2aa9e9;
			gammaABC[462] = 0x1aa3839b0424769b80dc84751d5ce044a1c05e8609e6997d6e6c4d36914f376f;
			gammaABC[463] = 0x10266d2e07e526a9824f364d593b901e5c7c4f11f8ac6c4cfeb1d3e1cad84921;
			gammaABC[464] = 0x19f91f49a8fabce7d2f31a96e47166fda0c22e94bd315a0211d92e176a803fde;
			gammaABC[465] = 0xf2e38c296f3eeccddec2a02a37bb3fc72ed382d27a6319027a6b57789e5ef17;
			gammaABC[466] = 0x2a162b149d7d1a1a6ee4a427944e3111d4f823e574f56cc4e2317b83d8f26551;
			gammaABC[467] = 0x1b78942a3172b3c1b819f5fd70ccc2bf9a6f6f7a84f0fc3fbdebadb4d8ad7555;
			gammaABC[468] = 0x2077b7512ee8ba21cbe9796a9ec765bd54143f4e71653a7e93d0033e0d0308f1;
			gammaABC[469] = 0x1426e05b29fb10261f79be37f3f734d904ea96a7f81161cf9949df334158f7ed;
			gammaABC[470] = 0x241c57457cdf0d2194efcdd429d3882cfc4099a3eda17d7601ae970a514604ed;
			gammaABC[471] = 0xd943fb88359136591cde1b39f6b7a9bdfb204e06c69e8d32e9a1e3f84e5b2d0;
			gammaABC[472] = 0x15a2b3a3ff5bf9b97f5b18c4d2e9bde71864ee2aca5182261ceedc159b3ea1e1;
			gammaABC[473] = 0x2f9170d09a71e9d82c45fd4da87d945426e5c40480ff35a83ba3392038376bc7;
			gammaABC[474] = 0xad6248d412ea30180b6ef848c00f3928877f95356da2c82b6f49d48d8e7120;
			gammaABC[475] = 0x23d7c7bb5008208ee1413a7ab896ee53afbfd9c17ba37de56257d0380efcd36b;
			gammaABC[476] = 0x29ddbba5418f5eeb1502736d0cdc0295d4e30b19e539e647763b23f555a22278;
			gammaABC[477] = 0x1c7b7e24b04c43d0eba6943c49c4fb84d42decc7d217e25670cb7813e1d65635;
			gammaABC[478] = 0x21fd866885ffbe0aba424b9648a5edf89b0d23ea358932023ba15ecf80e8fac8;
			gammaABC[479] = 0x2c73cede721429d8344ab91645131c78109f9963b3531c4494aad39b9e34933;
			gammaABC[480] = 0x23d675149a5a905ae2a26606aecf1f14a346bc40a2ec8095cecba82cd49d9944;
			gammaABC[481] = 0x11adbade74db0e95c5a2f74c7bf41e332e2771116719b9fe33e65113d49a206e;
			gammaABC[482] = 0x27bb079186c29225946581121106c8f9a4b3b48e66cfcb6c2e29d4255fd18fa8;
			gammaABC[483] = 0x87ae7459f85fce6154b77df913724525acdafc312a0e36fdb9dff66bc764089;
			gammaABC[484] = 0x303022944c8b177d285eb6ee7c77f70a19f17700d723958bc35e968c06b31fd2;
			gammaABC[485] = 0x279847f8a3a8843199984b0b9529ea90b76e5fceff3a82fb5779e2361ab5a42a;
			gammaABC[486] = 0x4015f12e4a7650a916061f7e13102387acc065b4df6dcf92bb37d5c65ee555;
			gammaABC[487] = 0x6023f1f104ce9ddd98d8b6e43b02a89c289284793a42dd9cd74b1c6dfedc630;
			gammaABC[488] = 0x1d08768ba9dbbb1d19040f7ae2d62dc5d72104a63d82cd659c9c9f10aa71643e;
			gammaABC[489] = 0x3059bb23199da5d17b50487e8039d327811a553107670ed2f8adec72729f2636;
			gammaABC[490] = 0x219a7002a5b590b08e0172d8413a54f7b452a189b56a3a31d4f6ef8aa1394494;
			gammaABC[491] = 0xe9cb5438ca52e6543d27e2db00530cd972f930d8ad01806a475bdbc7b3627ef;
			gammaABC[492] = 0x26795044b14ed6cc871ef43c7f5caf8e68b65ec2883ca41c11abe124421bdfd5;
			gammaABC[493] = 0xbfa784876b217c019f29fc77b185dc98357ac9fb2c868c070e0e6eaa715c645;
			gammaABC[494] = 0x2817df56ea2572b7a393cf823d6cefe5bf9f10cba919b035a49e3d51ca0e2814;
			gammaABC[495] = 0x76029c9182caefee45dacb3bb4f93b0b3d6acd5540795d6e770292d5eaea54b;
			gammaABC[496] = 0x24c62ef03bcad0488fb9be6404c2a0d6c8cf665a0d4faac44bce2ed1d07fa41f;
			gammaABC[497] = 0x1302a970f7ebd6a5d9ddc28fb862b280e36d3f595c983f973f707f921d550385;
			gammaABC[498] = 0x2feee6ea81a26342eabdbc320b3dd43c4f2294ce3a6b069bb6e53e2a5218b15f;
			gammaABC[499] = 0x2991ceeaf2563fd10d58fe1a8d36d35980f492ef213197ea362b892d77d0fc39;
			gammaABC[500] = 0xfce3cd7e8ca845f22f5d294446b48e1e589d16ba8bc480430dd49c6ac9df20;
			gammaABC[501] = 0x290611331574921ca30b6974312565912c707c10394276254e54f81c5727babb;
			gammaABC[502] = 0x2180f5c26e24dfcfffca03d09d1903b9fa495a7c46a2929ef3119245919569fd;
			gammaABC[503] = 0x26baa24f009286ac5c7ce580dd47528b13f9a4b1994a50a22760bd287e774ed9;
			gammaABC[504] = 0x2af1747a9145f8e5af0ba01d589e56809c93fb1191ac6e7b10f8bd55ce551187;
			gammaABC[505] = 0x1e96f8597cf6e69f093ac230b0b963ebc2bc7b2d414e28750b2bdd0ef77ec082;
			gammaABC[506] = 0x2c2da8bb7b03d2eb08dc433dcc75a6f34c2f94553eadc4cd0a5daa5107c57e8;
			gammaABC[507] = 0x1b1888bf3b83a004dfe47d08e639010ed15af52befca853ff381b6e9278bce32;
			gammaABC[508] = 0x1771ac5adaf46d0bc623cbbd5febb6a075b0e0ed3dc04e732c9809fc2022e27f;
			gammaABC[509] = 0x2c56fc23411b2a8d35d7e1b08e8faa4aad2e441e8ab45694c1d9ed38909657b0;
			gammaABC[510] = 0xde4d4c88c3ecaf3b92f94c1b6551d8eea754e84abbe0fd46bf334a5afc68fcd;
			gammaABC[511] = 0xbb773cb86e830ec36913968be3ee0feaee7980f8235097a9dd5cb2c90c29b25;
			gammaABC[512] = 0x286f6ecf2f612870365cf5cc99cb741f21b53a182f8d3fd87b13012e2b660815;
			gammaABC[513] = 0x215b9c9db6b31cfcd693b703544311ec562e668d5e7212cce23aa2d7f7d4c6ec;
			gammaABC[514] = 0x23dddada63060bad055ce200425ba98ff2a7f973408d8049098318de32025c43;
			gammaABC[515] = 0x1d4131244b52c948fb6884227f76506be54decd4b7930c4c2b0b2f7f16147f87;
			gammaABC[516] = 0x1a6fb2e2b390bb1f7977804c84f0a1c7d8ce7cf61d94cc966fa8bbd7242445cf;
			gammaABC[517] = 0x6504effefebd2e434460abc607a0290f929273967ef61f544298658ae74ad8b;
			gammaABC[518] = 0x20a8ab73463941c9b65811f19a69264030d41977e38a4c632bf040eeec7d998a;
			gammaABC[519] = 0x2cff517fc19ab13d1763a5589a371c86120428460b3f67080d7bce35e1f2508a;
			gammaABC[520] = 0x178191fa9a87b112dc854997769faed339a6e1baf77029f95b2a79c378ae7735;
			gammaABC[521] = 0x76aa6dd75a875af13931aa0b276e0be6a2030cea4d8273908fb379a591143cf;
			gammaABC[522] = 0x6561e6ace5ac9912a9b7c48f30e579a832bdc569bc73e7c9e1a919b49fe904;
			gammaABC[523] = 0x637f5401d2e079d6a421433a290695bff0445693688f29fad52fd9f98a87e56;
			gammaABC[524] = 0x147d2a0f077c1aaf4681901a7c889cb299ca51e9c6b7d467caa77463706eb3ff;
			gammaABC[525] = 0xfcb64bfe8dcebe49d3ff607520f1ddcace112f6679dc800aac6f39e9a2c008d;
			gammaABC[526] = 0x2afa33ba4861cb1b3a030b8b2f816bd75efac9ca1bc5815a0077608fb872df6e;
			gammaABC[527] = 0x1407e064a01c8f0e5916906480ad758e506d3f4ce7dd31e47e8778c385a695e7;
			gammaABC[528] = 0x29fc55f87604f80079db36bb7295b2904648c47257463f15eca00da940401304;
			gammaABC[529] = 0x2a5ba2f0090b64bb8b9b51af9384b59c8632d823c086e0d8ff226ff5a5324024;
			gammaABC[530] = 0xefbcc6e43fadfcc34f3c4562e0783b0f4460eb3ce3de002681d12fa7ffffa8d;
			gammaABC[531] = 0xbf062f70c6bb98006d6712ca31fbed1dca1f4cafaa5b5c93022e9bac657dbab;
			gammaABC[532] = 0x1212bc5d6ca95cef684fa32de218c347d92ccc7261414b625ff386020ac0aab;
			gammaABC[533] = 0x3a61ad3f7e328190ceb78ff01ac5e84b1f76acf340f6b9edd37510bc9f25bca;
			gammaABC[534] = 0x2f45283da3492cfdbbbc3beb456af70847f74496e6cbbe5b6ca35fdf09652f95;
			gammaABC[535] = 0x3d8468e6f2ff459673c790e6885b9be4614c67c58382f33ccd5667bed581a4e;
			gammaABC[536] = 0x503ca77707b5035b95e7dc6438f530cd88fa3825be973d5028be18ba90760ce;
			gammaABC[537] = 0xff04792297512e3c2047e951b8d3f2c4f58dadf76295555c10add00bd33a54a;
			gammaABC[538] = 0x12d64bd5b2eac20456096699e2cdfc5c357aaabe4579aa5b04a39c898e47fde9;
			gammaABC[539] = 0x2699f64cb702d9c6ba5804e7bd6e4bcd2ad889dc60d1b8117f0becdb23de8f8b;
			gammaABC[540] = 0x107a60b7a0ff64e7084dc82a98944ae69e7eba77ad54e277231b672b9c6b20ec;
			gammaABC[541] = 0x2702a5b6ac737a7f002fd745d75ea6eb269402e145d6eb601b0ea2d5c602faa2;
			gammaABC[542] = 0x1e067e6afe1bd64c9cab7fcd9fec5a308109d818b4d32f9b5e032e161de19e4f;
			gammaABC[543] = 0x1d0c72507f865be32f0ed67c4c8dd56b121d34f43bba9ec8904cd85e4799f752;
			gammaABC[544] = 0x19d4fcf4dbb7f5fdb8bf96ccd9b73fa46db6c2b3620bb94a2a6b0eac4362cb70;
			gammaABC[545] = 0x68da3fe13f440372465543e7440506418ee7493c954c7faa314d84c5c6e22f4;
			gammaABC[546] = 0x1b63f31d326e5678925baa7c288f1de059c26136cf7c42f9b1ec968df91ddc8;
			gammaABC[547] = 0x1f69dda5552055959eebfb0991885d8d62f68a507efc0f9d564f6ccf390fd13c;
			gammaABC[548] = 0x131e0adb82533404bd86d9f41dc19369351e5b3fb88bcd2a7e2c044764b82154;
			gammaABC[549] = 0x1e3ac34c5a22617e006bb69985b7ee0ec7481ac011361bb6811c857932e55024;
			gammaABC[550] = 0x169d73b4741a5da5bb45d0efb559856f1b535a13bfd99248c504f57c59f1b977;
			gammaABC[551] = 0x1d59fbf6b17dc86c98c8045e1508a2534f8202a785c6525a833e0751086ebf98;
			gammaABC[552] = 0x20f56696117106b9e92b0623ec11483bbce3f74ca520e968985e73533a70b47c;
			gammaABC[553] = 0x2041126457679ff16006e4c5cb04bf9cd757f7deacad766295c251dd6aa65a9c;
			gammaABC[554] = 0x1c8c1ca933836933167d9f1804bd12a36755806fa3f6562c3d08bc7bafd79bf;
			gammaABC[555] = 0x561eb2d1bd9b17f1a12346e57471769694235e4138f6e346144b6878fbc229f;
			gammaABC[556] = 0xfcab9f21279a8e57b7c5afae2a65c12ee0fb25e7a47bcd635939c74ea4a0b11;
			gammaABC[557] = 0x7b9af7702673422b2de1128c8a41db83a9469e73861b38465992feb4957e625;
			gammaABC[558] = 0x7f5a94a1fb5e0f02b2f020ab31fd3a81763a22f4d429b53a858ee6f58e80d7c;
			gammaABC[559] = 0x34326f4b205f1206e8bb100e516b0ff4f9652253a2b35948732f35cb8ea5f25;
			gammaABC[560] = 0x26f968c7e95bd6993ed4abc0ba1fb0782d4c439adbd8bcbd445058585259c7ab;
			gammaABC[561] = 0xe786061a3035a60185d48e797bd3cb2c80df8e88ec1f1c7c30bf4b44702ea27;
			gammaABC[562] = 0xce2b230c55b2fb7eeb3c37edd3d1c69ac3d51fa6eb225d532b8f87792059aec;
			gammaABC[563] = 0x2372c7be926b48bb7483853928091fe61f76c8c76956daa4c4e8b94d4decf9be;
			gammaABC[564] = 0x2415a3269f4c89af382d3e0b14eac2bac334e549467f390edd23d0f29b7789bd;
			gammaABC[565] = 0x1f04dd6d254073d43f72a6cb29b7c15951841e02c15d73e47d10662e26621ce2;
			gammaABC[566] = 0x1c5ff9e9c0b11acf3ffe1765fbf378062ca232f5f0a44b496b53796500ff6da8;
			gammaABC[567] = 0x4d7d132656fa57bd72856b7d0fc0a2114418489e539c3290dacdfdace11f07e;
			gammaABC[568] = 0x1b4c84b81251185b3dddbdb1eae174d60fdd9237c2e0947145851eb434803c59;
			gammaABC[569] = 0x760510da7c3a0f2c4eb82cc35569bfc113fa06142e973e5ee764a301507beb8;
			gammaABC[570] = 0x20953ac9510e00a561241111e30d15374441812b8861e792e0ee4d93df35a0b0;
			gammaABC[571] = 0x2b5c9b70a9ffaa23610aa1221f3942bd2e4da9312d9a3ca8b23fba959a6977fd;
			gammaABC[572] = 0x2ea24cc2df03a0a648e4a8bbfeef259bb8cc911fa797e5dd57196b837b77315b;
			gammaABC[573] = 0x27500a1ffb39f65540d36496b1955c3274059bfb90769855e8665d80cef9f720;
			gammaABC[574] = 0xd096c44f189288de8f82bfef79486075ab2e6e92c64489c77b4a6353059a084;
			gammaABC[575] = 0x2f102701718606ca9d1fdede1eb48e50e234a33a37e14ce5b0190959835c048e;
			gammaABC[576] = 0x366af41f22e906be16304ec1743e7857312425d1bd7dfbcb89ab84e6d72afa1;
			gammaABC[577] = 0x2ff3c132f907f1abe8d917079eb7dee30bdbf77fb82ef058ce43838ddd4450be;
			gammaABC[578] = 0x20df76c434b87d3466d170329478221e2c66327b556bf1159631996d4db75c0e;
			gammaABC[579] = 0x11c03731332f6bba216ae6836b135dec91a5a4109e51fe7114f8212a78b9d829;
			gammaABC[580] = 0x10cf6483ad27e86193f6de77589d5ca711bb2759ea50a4cb8534def8fad8da9c;
			gammaABC[581] = 0xb486e5a1701709b3143f2fb8f9e7a6748a04ab118bf36cf2ecd0ac269f9d012;
			gammaABC[582] = 0x28064cfa6002210c4596ee9ef1f8224b7b043a91243c1ba5f2bde9ba5ec45c02;
			gammaABC[583] = 0x2a9f64289ce6f001cabce755bea944847f64e866ec26332b07b6f14c80bbbdb1;
			gammaABC[584] = 0xa672abbd6f0f09aa4c9fe7a222797f2443842489f21510217b4989fe8310efe;
			gammaABC[585] = 0x24dd62472b2c48147877ea6118336811fbe33e7a3aafb14021c92988fbfdf12a;
			gammaABC[586] = 0x132b6df3a4623cbe62cc42de0d67b29691835b2d1fa463e12953668c3f23fbed;
			gammaABC[587] = 0x2fc822bc2dd2b900ed96c212632beaf2ab1fde68944d9df8ee805ebc6b9f7a78;
			gammaABC[588] = 0x4ef07c5e2ae7efcc1c8a0f8d6edadb5616ee8c6e124cd98f4a97ace31e47781;
			gammaABC[589] = 0x21796d86986b936d8d218a51b8cc6ce352d10ec2cf2b5cb70d353bbc92377582;
			gammaABC[590] = 0x2476c42504974c365ffad363b718f1cc1a4ae257f47257391c3fe3f7e5c148ea;
			gammaABC[591] = 0x1e6120a88203ff555d1d13e62840fc09f0b39d11f5555dd94d7d2912157380df;
			gammaABC[592] = 0x98bfa4e555a6b20b4f20f12f221a6021e4c54a1ebe28f580657db754bbb43c0;
			gammaABC[593] = 0x163c1df7e17c5cde798b698782457765c8f8555a22018453a7d83da7d9cffb75;
			gammaABC[594] = 0x877dff9af58e158d5c7acd200a067a315c2b8ccffa3f42a3533fcd26d7c01cd;
			gammaABC[595] = 0x2ea0d06c6a693d5edd9c6f7e47e89c22cac26b8c151a69ae079db828bf3798a7;
			gammaABC[596] = 0x1297a6a9388cee62b7d411e669193133e73601f2aa6635a7ea06636862945174;
			gammaABC[597] = 0x1858405bb958a8487a509b09a1b84f35b06c53359d9d9ba718add1ef6aa7a8da;
			gammaABC[598] = 0xd222f25529702ad484f31befc90ea1c765d896f2414eb14e8cde066f64f443d;
			gammaABC[599] = 0x2c8ac2804de99878351b7de43f0b18792422e81aacda788d765d65df2a281132;
			gammaABC[600] = 0x1b6f5abe21de3ef8550e1181ba3758da0185365e3785b21eb2ec08ade8c48ec3;
			gammaABC[601] = 0x94b3c8af9db859aae051efca2ac0bb8e2d22bbca5a1178cdb88e77ddb41a483;
			gammaABC[602] = 0x519afff4cccc8631c8b74c560a1b49d14a958a815bd4edb58d56c0d292499e8;
			gammaABC[603] = 0x1b390ec2072bb9eaef4b0e1dc179e4dabe1185199a616de324e25060bba4e494;
			gammaABC[604] = 0xe839224fdc2feb50f79df943833721d205174ec0a48d0892a0be9fbdeb44f03;
			gammaABC[605] = 0x14e1414740c09dfe8847b9d531b009e0fc8226d44af54a4d2a4dff0f67debd72;
			gammaABC[606] = 0x165d8ca2ad52077357566429f724a941c22c9b1775f61721ea117ba544095b14;
			gammaABC[607] = 0x1dc2bce68328843975aea02dbe0c183bb03d0c9df6fe451b616c6a09cadef017;
			gammaABC[608] = 0x1501e6398d09b219ea83fa427ea0aa91ed04e923503d185fc0635309f0c15bb1;
			gammaABC[609] = 0x7b61dcfaf3862639349852338600ca69597d25317709e0cca852f40ffcdd09f;
			gammaABC[610] = 0x19f22c1645e66fbdac60ee76e05823730f4e119b964becbc7c56781ef9d5efc;
			gammaABC[611] = 0x2de20925f2904560e9d45684d0a17922a87483fc68be9ae2059067cd7d8a6135;
			gammaABC[612] = 0x130bb80f8a81dd74f5ed1b7b28c15e3aeddab6cc7bb163928cfd6f28014e08c8;
			gammaABC[613] = 0x2714d8a20380289b18230fc2b22ff55a0b8a0546379cb736e120e00a77df6f16;
			gammaABC[614] = 0x153500d45798f7d6d9983ca1c7f697e240be418630af61d7e6e30c941c4abb3a;
			gammaABC[615] = 0xb2ba662389985988fdb9a02450cb539ca78797bae39a429d248a67cded4c61c;
			gammaABC[616] = 0xbbb1dadad36bd042644e249544c591b9946e70b8b70baed7a6ecb6d8adfc40f;
			gammaABC[617] = 0x1226239ef0e7fd139f22bb7c29284a42581f1062b41285c32ceb784945d8bb97;
			gammaABC[618] = 0x9f28e793e925c482bcdd040b9e3e37e8a00f6656a5712d141ac9b357f6094f5;
			gammaABC[619] = 0xc7f5d78938cf749bdb5d075f6dba0d402e37458fdd4a1b2170c67230f0dc1e5;
			gammaABC[620] = 0x17f896cff4e93d5a36ec0c08827ee44dbabc96fb1d2e4958bd1bb07db1751b01;
			gammaABC[621] = 0x607b850ce85a10f5139848dc89fe2db9c545327e8f0341bc9a7fc457bdd1e9d;
			gammaABC[622] = 0xfc3e7e56640a38a3a7c2d74693c4ba63ada1227427b9fe7992e9442da148f4b;
			gammaABC[623] = 0x26614019304162455634a0a284cb2d42184e9a92eac8fb3e2c5df8378a772964;
			gammaABC[624] = 0x8c4983f96fa1a84d9f1cb2d0c2c5b7af9cc61b461e3a5fe8665c72d6f4d51a6;
			gammaABC[625] = 0x27f9d9a276fd8b43b3dfafa456b89ea1b76dd86703bb5214ea4cdd40416af100;
			gammaABC[626] = 0x2e88b71715ee0224778505545b1822517e7daa9900877d22b0c63fb7c0fa4ebc;
			gammaABC[627] = 0x2ddfb59e55f1ba968e28071ff542d6525730f14f971b4fb21c65faf33f31c54c;
			gammaABC[628] = 0x6fe1e39524e79103ef9c441b9d6b69646f19c7d580d716fca360bccd45a108a;
			gammaABC[629] = 0x1a493116305a6ef506c5f311fede48907dd50ae4bad0a64f1876a7b25d942c0a;
			gammaABC[630] = 0x17e159353a4e21f9ab851a1095374c91dac9e831394fc2327bf12704093417a9;
			gammaABC[631] = 0x1beac27e57415d59c1ea69ab818cf1361c38669185856bf57c533ad68b8ef67b;
			gammaABC[632] = 0x11a9c87771d9a48af35320756fcc193331f1c3a68169f9ae0151df0385e08418;
			gammaABC[633] = 0x20e7874b9fe70ff699cb3213f5a4e32eed2c39dc07118eeb8cae53f12f41debe;
			gammaABC[634] = 0x1b08fb9d3ca5a6e947cb5180c17ed80603cb4476e25b68bb96391451e2842d6d;
			gammaABC[635] = 0x32bff8447dbcb0d682fa3a345125fae3072aa551c3044255e1b4f33406301cb;
			gammaABC[636] = 0x449010c9fe74389e4b0a7602333563f0b1cb7676da70c29e28bb5c91a40aa33;
			gammaABC[637] = 0x23d0dde1de50fa352bab43009c19546b4cd940032bebdc2b76cf498c159dede1;
			gammaABC[638] = 0x1b4041f79694ca5b9911f17be85da54ea77fb7c7f6fbe0931480a0d11d42154e;
			gammaABC[639] = 0xb943b25b762d650defc27064385f54d1ed93a079977797c9eeea294b8534b02;
			gammaABC[640] = 0x210448f1749bb9bb29121b8af9e2bc02ed554d2da26d5e965c9a7dc1a480352a;
			gammaABC[641] = 0x222b4d9d25e076e2b1f5bb3320c02bfbbdb61cdd0da3bea8da402101df5319fc;
			gammaABC[642] = 0x2073d0bd8fb4555c724440ee2628b466f0fab557652ab23f0112d3e88dedf3d3;
			gammaABC[643] = 0x837e8fb965e47797c4caba31714d87ea8cb5eb7c6632512d3bdf9b4293842a8;
			gammaABC[644] = 0x254a5eb879a19f5056eaee58cf4b9b3c132d65454b3f9ad450e607c68fe97b3f;
			gammaABC[645] = 0x2728a60bfc8a43e2806dd00683b453a7072ee0d80ab5c93b7720cd30400c271;
			gammaABC[646] = 0x625efd9acd86c6147f0a8796a4461abf2f6c30edc56729b93114c0667e8add3;
			gammaABC[647] = 0x1847b5ba5855056f77f728d8768371b6d7489f713bfb23d8261e88eaaa7a9d24;
			gammaABC[648] = 0xa6885528c2f52b7c5ac4125b0a1eec8627075440a542403074ee7a3a584be7a;
			gammaABC[649] = 0x8043b4663d15135663de612f3f173a75a50c9341e70bd1d024752746aaa8d15;
			gammaABC[650] = 0xec832abc9577334bb4f8d8d26b061131235e11db21f2befb04c4309436836f1;
			gammaABC[651] = 0x1cab4d8f59813315021e68c131f9a4ea5c7a65ac2e30a6461cc129138ec0f47a;
			gammaABC[652] = 0x1b0cd241d9b3c434bfc4e7d041ea175e6ef2b54d3ff04480d6ec52172bd79f4b;
			gammaABC[653] = 0xe4458031c3497308fead1a96da9a438c6409294e34c3dce9a9cabcd20178d51;
			gammaABC[654] = 0x2dbf5bad1d9a115388dccb728e8d90fc7775e49109b8492af92792be71af519c;
			gammaABC[655] = 0x290887d06cbc675001b4b8f888380121efffe65163ecf22ca7beed33bebb01e2;
			gammaABC[656] = 0x25103aaf7df3aaf782b4bae7f4783fd60779eec445a35453bf65fc2435bd44e8;
			gammaABC[657] = 0x2edef8c9f0bc845db103a3cfb5024033e69747a8f72192a67a5023ff5e3bfc31;
			gammaABC[658] = 0xded2c6f53597f72741dcd019ad7e2e0bc3161a4b4a2f07d5eeca29001b27768;
			gammaABC[659] = 0x347b71fcc84aa3132e4d4d5ab11648d7ba06d9cc6b0bb223f31155f55f8d6c5;
			gammaABC[660] = 0x77c0d01a7b923273228e358d63a4711c114141333282d94b15c8447a4616a48;
			gammaABC[661] = 0x20e32eeefe7fffb4b0f07b39d1f66d4433aca8c7d764b0d821639e1ee7e64120;
			gammaABC[662] = 0x1dee4f37b9b527b2a969b9cc58098bdfac4f8e0a685d546c8abb26445586c35d;
			gammaABC[663] = 0xaab8ec42263f0c1b7cb8994711f8553943734a707db3804588f3d2e5c22adb0;
			gammaABC[664] = 0x162a44c147f4f7d3268da06c5a374075c3176b6ded85a6f002ffb1410dedbfab;
			gammaABC[665] = 0x21089d23492424eebfda161ac14fec3dd46c9ec00909e4d9b73c24f61ba4b05f;
			gammaABC[666] = 0x1833c1990ef52f5744b326c6ed72d8d7dedb3d1de1c633f1ebb03691b364c94c;
			gammaABC[667] = 0x2aadca408ccde1bedf28e6852e23cf4a2c3edc3556b301680ccf7b50f6484df7;
			gammaABC[668] = 0x166a0743bf92bc6051418720d38f287d536291ae215b4dd53d8685d6e57e2ddf;
			gammaABC[669] = 0x121568ebecb970f11ff986eee20b2aa3c266b48a985c281e6f9e79eb387448ea;
			gammaABC[670] = 0x11618a37b6234e744fc39a9c3fd3bcd3c22c40bf507d293c21e4aa557d1c678a;
			gammaABC[671] = 0x1ce0e2273fd4f4bc5362633254818ad9eca7b0ce78660f10f86c21634b1f38a2;
			gammaABC[672] = 0x232239bf858c38733715cd16ca6ea00ece38ea7651bb604048374c502bbef838;
			gammaABC[673] = 0x1c8a35ccb0cc0a95be94397785507a284e8b2695b0b1cf15aafa2c22b59375f6;
			gammaABC[674] = 0x24d64dc4643b26407183ada259b398cea0056c280ea8503511f3a6bb72985f12;
			gammaABC[675] = 0x1cc7de1681ed2a60f2fc3c4f3c5edc9c96dda3fa7144d3ce19c26186a726f471;
			gammaABC[676] = 0x1394bc8a71e62f24531628f26cdb5ac98842e98aee83821c1af33fd5618070b5;
			gammaABC[677] = 0x1f6e4cca4fcdec8b38c7f1f5e005f9a2c4999235df07e38c2459c52e33949daa;
			gammaABC[678] = 0x1b8e6ac4d43b98734b39b28a437d00b6e9ed3242706dc3f469716799f799d396;
			gammaABC[679] = 0x1f0843b775d44d2b3c63019dc3ab11fb3d610250921c8bcb5035ffa3264b62b2;
			gammaABC[680] = 0xb340a983d22a8c3d7dbd836d200dc481f8b9786c0d45c21701981404d855a81;
			gammaABC[681] = 0x15b881348560f5a6e8feb0c22c0234df856b54f1980ba5d6eea1412a6e01eacb;
			gammaABC[682] = 0x1ebdc6a44e8f0dd7780c27c781aad4d8c0831bfb623012aaa564ddcfac069a15;
			gammaABC[683] = 0xa356ba6ae0094aea3bb6011bbc7d7bc2ae0f3bb00512861cfcbdfcbea3eac41;
			gammaABC[684] = 0x29aaa79b9047249a9962aab17092b1a393bdb3f24d977fe74d853d27f0a6c98b;
			gammaABC[685] = 0x21d80f5bde8bfe5fde91eb66a408c3fb0cad7cbd99feecbf38ac425ff46e52ab;
			gammaABC[686] = 0x1d60f832b346083a7f6016abbbd22aba01568b60a844f6c3cecf17d60d536399;
			gammaABC[687] = 0x1c7aaa2f00bd78f4ff5bddb21828a9d39ac7dd12a70f43958e5891d1c54375c6;
			gammaABC[688] = 0x1360a5569df496b64d7791f51d9cd7a861143d5a7f1ca2b7e3552c6bc3e539f3;
			gammaABC[689] = 0x265eec3b67d1dea2c1837a7db282b0690eeb2e3d07141329f4c44b751fe17f5b;
			gammaABC[690] = 0x1cacec8ce55be4c3466160b3ad64edb3936d6b6e0c5e02e9ff96f41cd277b8eb;
			gammaABC[691] = 0x21da9aa2657763acbf8bb6f5aefe4b82e74b7507d25b0cb66893af713ad261a1;
			gammaABC[692] = 0x69d26a672b97897ba83116ca58837d4a88021db74fd690acc6132673f50bf5e;
			gammaABC[693] = 0x2b9208a1692fe09d4ea3d5c6843d1429d4dc2b7d1f192444bd8576099961e915;
			gammaABC[694] = 0x82d73af47ca6251f575b95024b3de159df358ab842a6bd3daab49b546a7db;
			gammaABC[695] = 0x1477b74bc0d2295ee7f554ce7f3fc61c95b59d5a36656cdeeb3d0fd92bdfb502;
			gammaABC[696] = 0x16b108ec9c4f51743ebbd35f73a998268684600277f372e427f387311ef8d52c;
			gammaABC[697] = 0x2fa9073c9c8d685124bf04f598afa1715115326b694e37f3c522824e1cc6b4b6;
			gammaABC[698] = 0x205cba22433e99e7d2b32eb1a3b395d19e97797512fbc7002079d8e6954c1410;
			gammaABC[699] = 0x83ef78b1e9125f9de422d0a5166299658199e5a7dcc41273c75cdf00b8fb2f1;
			gammaABC[700] = 0x228f6f228215d4204852640e0a79e6932669a2d02f24c9c59068bf54e3a9b464;
			gammaABC[701] = 0x2953e860f5e1ad62a3a62b528fa7a4b6fca6a84a8a558334fbe92c64ee0f45af;
			gammaABC[702] = 0x10cade3089817d5921c093e8ceb8fb11da75f2d725b5e7cc8188c4b346f08f1a;
			gammaABC[703] = 0x1bc9c6a17d28c14b65f2c14d2ad9a231ad94181c3a4debec5b7525d16f54d225;
			gammaABC[704] = 0x41d64f727e6cc964b062bf12f7e013794d6b7d541c7547b212b99f993eb98fe;
			gammaABC[705] = 0xd284a1b6b846eeccb8519d20b2a2bc71828c2f86674f6d111d7fc6bb1b0e7db;
			gammaABC[706] = 0x2dad33d1571d48ed47d6252c51db59c4ba2a9a3c1c3759f9f7a7559ff8ec75e;
			gammaABC[707] = 0x27b8a5b81ad3bb90500be947ffb31663bea4274b504920ad7efe182281fb2704;
			gammaABC[708] = 0x305bb4690e3f1c3335de7583d3a52e43e31fc7ec54dc62ac5467827df0fce4ee;
			gammaABC[709] = 0x2d913d57b8ad87dd4f8876d627a47c50575f2ee7ad98b783ed1bc1c772a319c1;
			gammaABC[710] = 0x9b093e0ec0e34cb8ca7246d8018a340c8eba3cb9d8aae5c1f5778596398893c;
			gammaABC[711] = 0x17f75aaf3ab98264b17c75cf8c27418256a64b17d7cad121c758ec1585113ffe;
			gammaABC[712] = 0xc3dcb2dcd4fead5f232a014e6e9eb2d895dc35111c3d453978bbe8c226274e7;
			gammaABC[713] = 0x2c6906b83e367a9ea692ab39efccd9a2ee481818e552da598dd4c0b2f907179d;
			gammaABC[714] = 0x15c47267821d616d5328466df1f0486568b40730d7ed4c1655bda4e6b35434cc;
			gammaABC[715] = 0x12be0f7188ad7c5f9ef57787b358e48c11aafefe6c33cc084ff20a6e55b242d8;
			gammaABC[716] = 0x185bdcac6928114fc679d07fc5a0d1e8402e7cff8d20d64ee6a12ead0540c559;
			gammaABC[717] = 0x145ed85c3cbe6e0e1ec10b78153c08368d3906203fbd84e18a48d7175e5e14ba;
			gammaABC[718] = 0x200827da1b5e1d7573d5679e0c808d23aed0eb86c0869e54deac7c9c7d43c9be;
			gammaABC[719] = 0x3f414233808f34f210157f0b103f3e0e81b4b11da41297429051b7c4e043b5;
			gammaABC[720] = 0xc073a03ed7c46e5f165ba5786816c41d874b747bf8c7a19c5c1d095b9aac667;
			gammaABC[721] = 0x4bf0ef70c51ea53179f4bdd4b5f6ff2b713ce352eee649652739d8e79ab0863;
			gammaABC[722] = 0xdb0693dd557737a9c0d6f61d792da4fe77e7bf6b320dc0c06e8ddf09924b8db;
			gammaABC[723] = 0x200c7c0b7609926543f0f6a6fed1dfd8b194157baf9e0786989c763da98d3f38;
			gammaABC[724] = 0x10235e290348b02dbf850f462284bec5a4231f47be3c348353e8ff52e6e31a0f;
			gammaABC[725] = 0x170a804fe5552ee8cb3aa142dd9e46f2ddc382c66ed2eb0ec5be97bb443e5545;
			gammaABC[726] = 0x1e40d239dc9257313eb76924dd59f3b7104cca125e4f58a65d8260ec3eccac44;
			gammaABC[727] = 0x1b0c88041e759c9e64199e3c9d1d424df97eb2031b32d1a0396826220f8d0eea;
			gammaABC[728] = 0x2ce26f4c36d3e5d7ea635d451078d88fc0e4f896f71c93d78d6fb6bf903ba836;
			gammaABC[729] = 0xa7e25fcd38211fd8d8a5bf2f5b8d375bb79a45503124bf85b191f4494e0dacc;
			gammaABC[730] = 0x250f128abf75d5c8ae69b2bfa6a32ffce9ecb7ed7a705339fd90bd4114bb24d0;
			gammaABC[731] = 0x2eb488bee3db5dff60405925188197174e754bc727eca28fbe1b79c744a00c89;
			gammaABC[732] = 0x3002055bb556b45856164dc2efdbb5d82e6e0bf08b9b7a4ffa4363e18a46c65e;
			gammaABC[733] = 0x28935609962eb09dbeaa46c923133377540e6737978b5671cf30a8fbdc4f7f6a;
			gammaABC[734] = 0x1b138195900969beaa950a38d03b95780b7c5f8982bb9240439d79c6a5434de0;
			gammaABC[735] = 0x883fcf574b5a20fbd30b5618f9ceecb41010f6c55f0681070b5d11a68b64cac;
			gammaABC[736] = 0x11fca65f96f5b38352269c11ff03f7664f73a4b12aae8abd5813a0606692e8d5;
			gammaABC[737] = 0x25e48146f53cf05688572ef5b15693d19e8cf227f947289d8f5dec5d92cd1237;
			gammaABC[738] = 0x2cdb6a3a7e3e087cbf7d3bf32935fc7eed3f9c3654b862f7b4d585424a6ee0e7;
			gammaABC[739] = 0x1a06439b0575f08297c1f0810d4e9bd45c5ad5117dfe0a598d925215e99f88fc;
			gammaABC[740] = 0x1cf9634f339b771d6c58842f31ff803bfa4591fe64d6f5147b6cb85d1355c47e;
			gammaABC[741] = 0x1de9b174a2512d343298816d0d20570fbab3e08930dc7e22e57cf92b9fb73424;
			gammaABC[742] = 0x285226ac5cbe03dafae9754a3cdd62201019318f017597dfb15ea09a1764741;
			gammaABC[743] = 0x194fb4e58d1addef50aef6c9a151b1d1c19a986f690b7b95cdfc6e44f7f3f8c6;
			gammaABC[744] = 0x15922164ecfddc2f4d324184c01edcf2207489b165b8e13ff92e6770db1145ee;
			gammaABC[745] = 0x2508a1f5bae37a89841e7bd52f60433debacd41ff20cacdc86b00b548e68c858;
			gammaABC[746] = 0x2814c0e8f9b56d075a1196b2f9634ee284e55ac09e041983eecdf3aad2a8141e;
			gammaABC[747] = 0x182c1c735f6d387f5294f94971638ca87a9f2e661367e61c9d415ba59b314e79;
			gammaABC[748] = 0x46c6902d1c58b6c2a52ec52fa061507db790fd8778ec544ae4abbed3bfce1e9;
			gammaABC[749] = 0x1418b53ee14daf106e8dbe5d8f5eddbb891ff4624fe5e32987093bba59ff1e;
			gammaABC[750] = 0x1c382ac1033b495e64167a7904090ce3ea49d5ef6b468b9bc6a1cae6668b3f4b;
			gammaABC[751] = 0x15ff0b301ba17d79bb42989945c2715b54311ff43208bdced2c1b3fed1f6a77b;
			gammaABC[752] = 0xb4a055481be603a64c2c81d1b0c7af9af3d208102531d7d1d1778b6c352bc7d;
			gammaABC[753] = 0x2296d198bca53d8fe182a9997553a5b6f327b01a34c5baf72820515e1d364a49;
			gammaABC[754] = 0x141ea8ed7003fa8d36c670b6a3fa97f5e6c75ca65a4deca73a6d21849dbb6f06;
			gammaABC[755] = 0x246f7f2cc59afe1f1a772dec9adbadf012ae8fc01ecf262b8252ec6f84a57cad;
			gammaABC[756] = 0x1c78f0fa3cadaf23a60e1f0c4032e6b5adbbb028a9bad5ab94e861ce4cf0f05a;
			gammaABC[757] = 0x292db6338a9930f832d70e1d12bea3e74cc11ebe10aa25ba740b8334a7d0790d;
			gammaABC[758] = 0x58c1506652f307a6bc20ffaefdf3e090406268aea10ad4471b1599f9fdf0659;
			gammaABC[759] = 0x73a0e86213da08012c0022ea43672e3a04cdc293ae8041ac77fcfdf00988ac0;
			gammaABC[760] = 0x4cb00ad19b5a5eb1ce21b1c55dc295665fafa8a4323375c2affc4a2a4c0da5b;
			gammaABC[761] = 0x14f4e95b9ca8d006d400427c28a4007e64ff76c23fe0105f543ab065677ab179;
			gammaABC[762] = 0x2b789969853cf6b901446dde28867eb033387b1b8b9bb68c1e04b5a3c052989;
			gammaABC[763] = 0x16cb8bc180a1e254df4462df107eb4885549123da58ac08cd7f355ca5f39eb60;
			gammaABC[764] = 0x2474186826b70fc466b744d202980c16ca7be53960cd2506912281e70fa2a801;
			gammaABC[765] = 0xabee7a2985cff04f1be1bae557ce82aac13ac37e13ef819a11e26ff40e35079;
			gammaABC[766] = 0x9a530a3bb9716cf24d5cde4540cf4ca2930d3fee5e6e3bc9aeb924dd3be54fc;
			gammaABC[767] = 0x18fbc6733bd4333373ebfb8288a247863f9908ce0e1fa2248229ea7f5c37fcd6;
			gammaABC[768] = 0xd2bd05b188dbc546ac08e2ed75695d09bdf445ec9063c31ad9d70f055e359a9;
			gammaABC[769] = 0x40cc408a4b265568502183bf259489782b1f4ae0b9a3bf96099d217d1f274f0;
			gammaABC[770] = 0x52858a143b645a7f473a6c70935a2ee9466966947bcea71171bcfde27d28d6d;
			gammaABC[771] = 0x2845d1ac03a71451bd3a6101a4d10abef71b28b7fa9d782826dae8d5485de695;
			gammaABC[772] = 0x1d0ead8f2da91943a36435cc41139a95ec9bac311f32deef7fa01e2fee790928;
			gammaABC[773] = 0x162fd495fa8535b57c8976c8baf941dae7db954502f6683d04bab7707d20bf16;
			gammaABC[774] = 0x241dfaca001aab80478f67e17fcd80abe054a1ebd80cfc9473b3a54002ba91de;
			gammaABC[775] = 0x2f72987edcd3fc6a909724bbf7dfbde593926fb049d2415008f25d5d0ba6bcbd;
			gammaABC[776] = 0x1e4a105323773e28713578393eb7476812ed92d8f21f12f0ea22033e3fef26ba;
			gammaABC[777] = 0x19f9fd9facaa1edb848f24d2edc8748242931a709c7c885f7f50951ef4297bd7;
			gammaABC[778] = 0x129838e6501f144ff2ae33cef0f9379d469f3a3be74ed4896582561a923c0227;
			gammaABC[779] = 0x1f4daa13d3fe7f4f010bbafbc507f7c0bf594e409f8588cd628da1d17305eef;
			gammaABC[780] = 0x2a3430b837d07f9b4a463be38e628b7611cc28665b9baf43e4ec3ad39c2046ec;
			gammaABC[781] = 0x2aa2a9d29600f7274dbbb1db39a33b5b5a8ab83a3b510953fe72aa80ff9f97cd;
			gammaABC[782] = 0x2d7252074660ed904408e74de4a8021c75015290dab0aaae3bcd877538fa6a2b;
			gammaABC[783] = 0x1f063c0ee546f07d3d1c953816e91d84eb46fe44d07424d8dd3223a701aa4b23;
			gammaABC[784] = 0xb2e5909cf13e125229d96668cd405728952b261ced4eab37879ffae4fede7f0;
			gammaABC[785] = 0x86f4e274d4bf08d53fd9a0d9077469990b4ff16598b373fe9dce6115f7b1310;
			gammaABC[786] = 0x7d512a8b5a249a929cfefe4cad731493d983dde6dd5e1254c144a3061885cac;
			gammaABC[787] = 0x893c2e2b611c9b01aabeb59851ebf08f8aff09b803e155acf88ea56d7975e9f;
			gammaABC[788] = 0x87d6ae05dd44919a86b34f43814a8a579fd0f55e48de2f07c6b9bf99208518;
			gammaABC[789] = 0x19dff223800ad08ccddd174cc01a39f09751534fbb3b511815b48652fc273338;
			gammaABC[790] = 0xb5864dba9917f340c251d21e56016d58ef5c761db36919757236aa8659422cf;
			gammaABC[791] = 0xba2d36c632f0a58ce7935edb07a0a4ce87d0e23954a8545d8d9c6bb0f467646;
			gammaABC[792] = 0x82618876c079d5204f288b7baab8062ac984d4710dace01a67daccf88e5de5a;
			gammaABC[793] = 0xdc0a76dfdab0a47cdb9206c5d75968e1a2d8d89592481baf1273c6e52bd5161;
			gammaABC[794] = 0x12ac45105c0e27f61382327ed75177b66efa06b92c1525b74e087735c7c3954;
			gammaABC[795] = 0x1d4d3dd06d03d64395675e331a8d79fb55adf7a76729531cea475a723858c26;
			gammaABC[796] = 0x2d4ca9b836c9f8031869f37f0b590f12260478053da4035688b0780db83793b5;
			gammaABC[797] = 0x2ae192c426c17e29102cfa4e8ad6a0e3874d45c57b66e1ed2ec74ce0b85d36d1;
			gammaABC[798] = 0x14fbf01ec6af86604a8a8f96b2d5cb822957d8bb535a3440d0e1d988422b5020;
			gammaABC[799] = 0x2c586fca34d744e9c7730eb251f5aa76bb5bd7740afab907d4c791dd433ccba1;
			gammaABC[800] = 0x186484ee78a51940398103f21e9e7f9d50e05a78e6b3a9061de6479a622d12;
			gammaABC[801] = 0x110205f6daf246c5ccad75f58bb963d30bac42879a649ec8b82821e5f7cbea74;
			gammaABC[802] = 0x1811ab94091b631b10b487c318790a1e60f20494923a98befad55d3d0ce75063;
			gammaABC[803] = 0x275019970b4dded71ee207a3831645f36bfec52095e8fd2c7197709dfb97648d;
			gammaABC[804] = 0x152d370ab396d377d4c80eb538ceace65c9252ea62d79a9aa998d09bb358a5cc;
			gammaABC[805] = 0x16b2e64e44a11ffd7a9356fe60921053636014f50d30d0683a04236aa9e27b2f;
			gammaABC[806] = 0x18a4c51ff550dba1b8fcefc885e52c756fefcae971ff50f0a52c2274ab4128e;
			gammaABC[807] = 0x184dcd23416f8571be63ae5dd267837438d87b96774a99b0a049c4104e937d87;
			gammaABC[808] = 0x8d67fc5e41770ec741bf83f531ffa899f0a8e73bded5e230710edd44ed57f46;
			gammaABC[809] = 0xfc11c3d4cb1fe4c649f81b0da3e058b221772cdcfb3374c3f2c382095763c98;
			gammaABC[810] = 0x1ae36fb592ddb236662b8036b6f3f34a040232d70172344c92b3a71711ac2cd5;
			gammaABC[811] = 0x2ff48b8dba2065db75cff32c3c750687ee73d2f81a65d5cb473c163d48f043ff;
			gammaABC[812] = 0x144d8aebd593356f165b67609e010f5ccf1a21c0167e284821652abe7d2f5e9c;
			gammaABC[813] = 0x116193fb9c233add6a93183740aab2cf25ee0a5bfe339aed5efa597591e673ac;
			gammaABC[814] = 0x104bcb8d3778ac06783ea85730c777821b68a1eceb29ef6853fe36a73b79f465;
			gammaABC[815] = 0x81e427b5bdc6e6715b37f01d54c0560200a1ddf2fca9597752fbf148e8e1bdc;
			gammaABC[816] = 0xe22368ffe18fe56aac1b1b2809e41f8b9b0c4e7fe61543c18a30abc3881d1b;
			gammaABC[817] = 0x1bb664342b64721cc4422c6fe297a78ae85a42fa71c1ffbb8542f41f1afed4e;
			gammaABC[818] = 0x15d0e99a462338a00c6aa2f44690e61f54db1ec8c5ab14a3f8dd674d488af716;
			gammaABC[819] = 0x1c3cf5c4c1952f4f722b1c31093843ec0314730e4ee18e70bab21517f5f1430d;
			gammaABC[820] = 0x325be199b582a8a616414435569025e33d34061c246a248f1e12ee533fae57c;
			gammaABC[821] = 0x25e30f042dff49370561b510cb2c3b0d90df1f68439a54e53551f75cd986904d;
			gammaABC[822] = 0x22c06e28796a637d4f313ce6d4a476ae98dc763cbb93c066de36ae29446958bf;
			gammaABC[823] = 0x1a39dd5aa83ec0c7941e1aa701759767f5e3ea866e8fc71d8804c1a446d41d0a;
			gammaABC[824] = 0x1fe97532b16b9610d334e7f2ae33c0328fe58514ce7ea0b83b1850c77627e70b;
			gammaABC[825] = 0x249875115b5ef1feb6752928057dbdaa8fda8899a133ba4d83d236aa160559b4;
			gammaABC[826] = 0x2471b718b7ace26ed1a2f858cae43d96913e8428b92342e3442bca36cceefe9b;
			gammaABC[827] = 0x83069802ef2abd88a60414796f8cb2a963da6cfeea002fa829ef485e9bd5b74;
			gammaABC[828] = 0x2cb4d87904a894d86db6161eeb262df37ba5d88f0a5256ace0d1ac51f3446df8;
			gammaABC[829] = 0x4f4f1b827e0a74f929a8ac790132451b96e15b3261a7b5ce8361a9037b66d33;
			gammaABC[830] = 0x1388ef7f1daa3ac674e02a91c6aacb1130292972b276439230aa2b3f9db2b6a2;
			gammaABC[831] = 0x90106230d40403457d3dcb3c04f7c51eecdefcad136dafb2c48d9f977ae2ccc;
			gammaABC[832] = 0xab6c574cfcdd2d8098d235c489837a1c52186dbe0de8de1f5d41420f93fa5f;
			gammaABC[833] = 0x27a8fe7715a0ff8ce76bf73f4b94408c900463ed28c184fca1f33ca496c39a04;
			gammaABC[834] = 0x1ff03001697898f09b0fd7278ee0dc62cf1620be7f102daa2ce0392ef6cc507d;
			gammaABC[835] = 0x24621acb929949ec1c8d8dfda7c1a012606c704e552bd153368e41b1a0a726f5;
			gammaABC[836] = 0x2e7159720eee85cc6396ea2b24e83f810e69b533b404664541ba8224ee25f39f;
			gammaABC[837] = 0x1cc69ea83641bcfb089c2ff65f4202500c46d0449f66efcb23d3201f5e467f7e;
			gammaABC[838] = 0xcadbf331bf7e739e49a24751b2a9bafd1267e00f39cab83791e2c32ef3dcf6c;
			gammaABC[839] = 0x2ba35d1d799d974c2727a129bb254a9c9024a288bdd9e533943a526c9b8d6f59;
			gammaABC[840] = 0x1e50ed63b5e56898e86d6a705b86d7a8484d3abe9ae562dda89b6119ecd407f0;
			gammaABC[841] = 0x1554adb8ea8ba510ed5a42d3e5bc3931dcb887c553e173c143aaf634324544af;
			gammaABC[842] = 0x15498b80f420d4ee31e4dfc718c21522948bc652e27784f271445d0faa66d47c;
			gammaABC[843] = 0x1755e7335cfff0a724cdf49b2dad7947c590f405162bdef9240c4ca115e2b2a0;
			gammaABC[844] = 0x2ca537075814d3d0894ba3f55c639b240454e366e4d11779419d4fa2bb3eb773;
			gammaABC[845] = 0x158e5a5379b5c37b0fe333463ccc19bd505b7f683e0e854dbc9905d3dedd5d9c;
			gammaABC[846] = 0xac37a6edcd0b33bbe42fd4bc2146d09871e122e25340fcd749c8c4d48cdbd3b;
			gammaABC[847] = 0xb231988493df6e639b5df2b306f35b07a3620ebbce8976fe37d7db412a099f6;
			gammaABC[848] = 0x2edd2d1359941a85a13c6c1f0df55ff64a464d0524e56c9a02dc3261f6c7deee;
			gammaABC[849] = 0x3d3922f472954a417ecaeffc2e9ae945d26a8be4c9891863b758e040d09bd5e;
			gammaABC[850] = 0x2f4907835569676d08d4fa5a8581563bb89b188b529a512b132aac40d904ce84;
			gammaABC[851] = 0x1ec1e408260603c7066d1b0376745c5ff06ce7f55617b7626f96f73ec6cd1702;
			gammaABC[852] = 0x2e8e4d7425ebba000280ee63f3d5c5c2839f9698beb4d71d2339bada4d798aab;
			gammaABC[853] = 0x18051ddfeb290424c083fad5748df2be07e66c6fe3e21cb4370ebb7f3729a518;
			gammaABC[854] = 0x2b8ee87e34a9f79ecdb1d281c0fe2339a88f46098e68ec757060b0e12cd6bd1f;
			gammaABC[855] = 0x124c79e5e634132cfaa24fc3b9c3ba5f85f44704ac86106b24fc4c52f10cef3;
			gammaABC[856] = 0xd29d795b07e38aa9bf6eea77f77cc24c58193b329eb95a7cedda1349803f174;
			gammaABC[857] = 0x2f243c3f9af9157fa0ba80e77d3d045f25223c9a34044fe79592c73edf4e761f;
			gammaABC[858] = 0x17df35382f1c85e911b597ba995f2e4b8885c1f748bc54ae057faf4bfa8efa8e;
			gammaABC[859] = 0xdc3557aa1e9ebf37a45214e07877e47e7f38e03e9abfba587b9736a89ebd10f;
			gammaABC[860] = 0x21e5eabd5eb0157563f3b0437c37b36773e6aed64c9ca928192e7cb3186e56fe;
			gammaABC[861] = 0x1f73e52a29fc467393ef6ffc4a6f5aee950a9c4229d473256e37357e6a316e4b;
			gammaABC[862] = 0xb308db8ff3871f06ff82391f5f9b3fef9f18aab64564ccac93fba289e7046ab;
			gammaABC[863] = 0x2faf3e807db7c7d3971c898bceffbd4e1d6cbae4364fdacd197bfec7a703bea7;
			gammaABC[864] = 0x65e9a38d8accef5366e98240cfe65aad27fde8cfea2827532573418cbeef261;
			gammaABC[865] = 0x2c2b29d59f9617970774adce003a6d7079101ffb73e2d4f1fad7ffb5391bef22;
			gammaABC[866] = 0x14341541fed6954d84aa8d762520154f7402192440aea4dc3cfa2d594933f3b3;
			gammaABC[867] = 0xe41e6bbe03c356d59a6752b792e7da9d8f28a77172a5df8737c89500cfe39a1;
			gammaABC[868] = 0x267f4d6b027f81530db81a5637f934593cbcdf9ecbe5d19d7d32731ea0c612e0;
			gammaABC[869] = 0x2db545977dbffc608b1ab355c3cce3e598dfea09cc24a11983a9f3407ef8219a;
			gammaABC[870] = 0x7eaadb29964ad2323055534282a98544ead19b0bd320cccdc0a314e02b2a463;
			gammaABC[871] = 0x1714c2a8760f0ce4953d9b4e0ea453f6b76a14480bf53f0101ecbd074d6cc43e;
			gammaABC[872] = 0x2a93b18b9bce16abcc51ba7ea93bf3262d0914ee0fbfae9265274e1e4b1ce519;
			gammaABC[873] = 0x249cc2840575b0563a676ed87821166e98c6113885fe5f2d5cf3528f4e707ba;
			gammaABC[874] = 0x858845830b62ab5daaa4dff59e9bc10b8e9bdb5b2deccb1eaa80ccc74d85437;
			gammaABC[875] = 0x13e0a30f3b71017efb0ade3eb3f65166815fa8fc5fa2ed7f25b09337fa9505f0;
			gammaABC[876] = 0x2ddbb426fce964c70f60afa864bbf1523702d8b1ab4ee45ba9508ca228b9c78c;
			gammaABC[877] = 0x20524aded80e791228b5e017ad18fdc3654dbe1d452e7740848c2ba0e640fce7;
			gammaABC[878] = 0x2fe5448df937d59dbbbf82feadc17ee3cde5942eb33a24e1b82a364f67f03116;
			gammaABC[879] = 0x18c9fb0110d5569073a4df7ae6aad5713e14c70e74d5d14e10bbe9543fa01e5a;
			gammaABC[880] = 0x2d11d16056adfb854482f4f0bc342d35089f032c8d09abb8b498c965e5c972f8;
			gammaABC[881] = 0x84e337704d1c5706deb5dcdac9fffe6a6ca1f1c1389607ce330759f602e23ce;
			gammaABC[882] = 0xba6343cc2b52a9616efe7309dc56ebf9e09c2bc15062298330037fa1603dfa3;
			gammaABC[883] = 0x63be9ca55d80175ed05805d9eda846cb3c444f59e2ceb2ec6af0310de6237a1;
			gammaABC[884] = 0x2e5e7bb61d7a81f21fb844192840e9b2b896f11c15a25e7f683e2f2ad9de3d32;
			gammaABC[885] = 0x2b80f140c3a6ebebfeb71b20359129657661688c60ac6d75eddf898ac349018b;
			gammaABC[886] = 0x2e01779564b148e721a9174b2adff61a154b8d361bdc95a215038032523abf58;
			gammaABC[887] = 0x1084fae8419617768bf0e8a5df3b8878651b954639a002f76959a12d91871cf6;
			gammaABC[888] = 0x760a2e5c9817b3bf339929b15836cdd752bdd0fc78fdbe65c90946aef46d7da;
			gammaABC[889] = 0x2f84e6f566ea6fa2c115bdf5b243b804ddb519517fb8b9c8dc1769fc73d8e44a;
			gammaABC[890] = 0x204eb0356f794d6702b05b4ef5271b4cf4991664a7e62ea1e01cb73978df9d35;
			gammaABC[891] = 0x2bb35f88a8a2868729fdaa0f10e51607067382df3ffe3767107787e40a382b7a;
			gammaABC[892] = 0xaca2cedd1ef7a9318927c787cea15f5c8633e7ee3ce2c1107f95dca965aba51;
			gammaABC[893] = 0x97a548dc85829bbb41d7a35d4f0956907502c3a774e3c8e302ce4c045d1ca3;
			gammaABC[894] = 0x184d0cf62fe8d14f2ea1916d8cefaff9359480c7c791ea3445928d94fabdad0d;
			gammaABC[895] = 0x9571f1366a3c0e18fd9c01959079c2bd3673c47c39b0561507e70d1e0a995ec;
			gammaABC[896] = 0x21d11bed45b5a691ca066f0c4c6e842ca825c4aea013d03138d594d34e3187c0;
			gammaABC[897] = 0x2bd993eea3754d3ef7dc81e86bf81bad6e00726eef7e9b6f8b23e4a475c04021;
			gammaABC[898] = 0x1185e0d2a198893b9c26abb0b1b04f766ed9e1bd55bfb3d5f3d485aa777150b0;
			gammaABC[899] = 0x2dde7f75c27334d48e050cd463fa3082d6b3ce578f8358c32f7ae240c02d4db8;
			gammaABC[900] = 0x28cb900b80eca38c677256cc9287c52a0edaa5cece53a808d68d15470b00a316;
			gammaABC[901] = 0x145937072080144f6317def841dcf6c4bcfad77034bfc345fc5eba72caedecda;
			gammaABC[902] = 0x224b6225ed355f80fb0bac4aad3ea15fd38308ec067ebda8cdec6e6c2bb3e067;
			gammaABC[903] = 0x3aae43dc7961b0f701d04c7f5dd31a22944fc568df3e8000b777f9e2dd53497;
			gammaABC[904] = 0x17b48ff67bbcb1531da45a1e217873a409bedf212b61a28d6be5f685fd91a804;
			gammaABC[905] = 0x2acf59006fcf9240a86e45e2bd5855052ea9f27f1ceba6df62da4cc9738485d9;
			gammaABC[906] = 0x776bd392ab88fa168e92c0d2d424fdec262a6787ea61c1b1d2db1dbf8c4a795;
			gammaABC[907] = 0x291e6f0f4905cf09946e7df7fd68114d82f379edb1de38d9dada5fcdf4eb23a7;
			gammaABC[908] = 0x1a7d52ebb92d449ac9bab7eae08bb0ca9303894d23d6c934116a80fb9b61f39e;
			gammaABC[909] = 0x2275c69ed45d41dc790cdcaad7df2ef665feeb35139880b7d4000fc3d90234ed;
			gammaABC[910] = 0x236f06a103062d5ccda162786c5b85807ea97e7cdcb13b58daf66fdda5e4de33;
			gammaABC[911] = 0x29712f4e07fc3fb430a17a54098feac0d2be70d5b7236252556e656ca691bd6c;
			gammaABC[912] = 0x1475cfc63d642141f6f3e624f9991c0181a85e4461e02a7cec1dfcb95514d6f7;
			gammaABC[913] = 0x1870c331b33e7de2eee8fca02e2203502b626865801152e8a51101656777f0b3;
			gammaABC[914] = 0x39f5f989a0293b3c3f1d19662dceff7ff619119bc2242b52080c8c6c25caf46;
			gammaABC[915] = 0x6bc1f2f2b69c9d6d71a40ec90ee0efe9f3b533c6dcaf2b374d5b0e82e3b5141;
			gammaABC[916] = 0x25d61c13dbc91d94dd682aa4597ad74a8db6cb6f58861e67ec6c37eb0fa0f492;
			gammaABC[917] = 0x2abc07a5696dca857e6c03f93fc6a87d70651cf2ec44b0400ff455bd7d2a88af;
			gammaABC[918] = 0x12d987329bd02c01fce1bf3e44a51e1c0940731cf4bc4c027e78347fcfbbc00a;
			gammaABC[919] = 0xcdf9b19cf81e5105ac58fbfd2567cc94fb9a2d78e93812af4bbd9057f52a2a3;
			gammaABC[920] = 0x2d6ef008d17631f60611ad9fec6cfcf547535c6c8803c7f5d2087ccce31f2c3e;
			gammaABC[921] = 0x269859c26fa5a3fe02ca92deaf2a898083b2d4004887c77bd0606c81e2989a45;
			gammaABC[922] = 0x258643becc190fb4ce1cd2d3ebc9a281bd68e8fb3a1829593956493e6e55af3a;
			gammaABC[923] = 0x21ef2cec335eeb3b57bfa216f3fc486b6094814e049c9506a9604a7bf50e446e;
			gammaABC[924] = 0xe5baab0f05e83ec2925b1bd3a50df06b199a76eb95f96147401c01a309605a8;
			gammaABC[925] = 0x2229c8cd3bd0d16636f5d387abd324464c0ade8deebfe449fd509c969f349745;
			gammaABC[926] = 0x289af2ff4d0a78d03d17436a0f50e2fe135b8cdfcf7a2ada772dc74f7ae39c91;
			gammaABC[927] = 0xa427e180b0237cc2ad98a1b16c149d247418976866ef31f3c4c8747aca88e0f;
			gammaABC[928] = 0xc0a480bddcd2780902b13bca33a8801f6629fd34299388407fff4c896fe15eb;
			gammaABC[929] = 0xf1fa43f40c431b60448b77eb00d4dc472d1aff5f0e1518f32ae5c084a79e883;
			gammaABC[930] = 0xe289d0759477b3290446a7592352b11f4196592c68331770d91bad049cb5db9;
			gammaABC[931] = 0x1bd596c4273baab98b4e81cbb4473005dc2f1e6362c357fa53143b5ddc8cab5b;
			gammaABC[932] = 0x1b17df3987f8fb5fff5853b6f9add0768a08094e673dea90f48e5e272b92e9bb;
			gammaABC[933] = 0x27621f2b5e636498334681706b830cde5083fdf9e78c084278eb652a7684710a;
			gammaABC[934] = 0x1dedbd7e9cc3e1cf52bf400b6371b4189c06bfbcf3dffb5b712f5b3d19e9d25;
			gammaABC[935] = 0x13b121190e44ca05766634b38998bd3dc475ab00cbf7c3bec1f5c23f16d6970d;
			gammaABC[936] = 0xe46fd8de09dc555b412f2e429fd8f3984701dee6b577e67f558ae005001bc30;
			gammaABC[937] = 0x1b9d6eef72d48cf28fcc881e8cc134755d27d7d63746bc064fff193c9f499913;
			gammaABC[938] = 0xcefe9a695e70b6509695acd62fa0ca33b1f7b34e3c4d671511f4ddef3a857ad;
			gammaABC[939] = 0x11ee8124b09695396c4164877a796296bf5bf514c7639cd5de5c89b0e13b82ca;
			gammaABC[940] = 0x24aba4b96afbb687b772267cf95963908a42135c4c7323971260c5b1139ca075;
			gammaABC[941] = 0x1e159bc36140bdf59e6d8f36a86273bb82a8a8156c2d2ad235d99890f47d94d;
			gammaABC[942] = 0x2f12cd850e926aa19aab13549bb7ffd89b593bb6b603f77b617b67e9e1701931;
			gammaABC[943] = 0xa626e8f7974993a97394642a462b04c080ce12df1cbe59e9dbdd7a345b04747;
			gammaABC[944] = 0x3af2be48649a723dbd80b4c71cfd19897d6e91637bdeefdecfdb72918e64e2c;
			gammaABC[945] = 0x1cbb39c317cfca79b11372ac52059167cf8fc158a1a6ead4acab986abebf27ad;
			gammaABC[946] = 0x2bbf11c5533a4c40f526e1302536d8bdce26dbfe36a9f08a030bc6a8e04561e0;
			gammaABC[947] = 0x288b8679ab440a7ab5f8a3b8e8bc15ffa00f6085bac5baf7b221d1f1bebc68b5;
			gammaABC[948] = 0x2f814e570e2e24c7747d78ef1cf844041384b12db595144272c11cfd72b1d66b;
			gammaABC[949] = 0x7aebb2dfec6089269f935bd7398105873a2d25f3b60ba5bfc047349287f96b2;
			gammaABC[950] = 0x312492ede0507b31c6a9494243cb71e3e49a0fd29cc8c8601e6e2a15412f036;
			gammaABC[951] = 0x78be4fe4935c29968268b47f54a7a5bef75ac5d87e72e198856542c03f570ce;
			gammaABC[952] = 0x2569d2e1b820c6c11b678f67e513945be03c5718791176fd7089c2b42aa279fe;
			gammaABC[953] = 0x214da6577b4431c50e40ad4569d0e4911c3aaa621e9a4b304a7884710d7f2e44;
			gammaABC[954] = 0x1a6ebf48cbd489efdc6d80d57110b3f61c87a726f070b52a366fc5dd3ad29528;
			gammaABC[955] = 0x155f817ccb57af84716aa78ab25e81fad4f8f9aed91f77af1eb30ac0e03d814f;
			gammaABC[956] = 0xd93fb0e88ac73ff338423fa37bff7dc75ec47845332ba3e32cc436b6a8d9a11;
			gammaABC[957] = 0x67d0d817fb6bc440b40a1964559bacfcb87f32c08d8478beb6b937ddba4c246;
			gammaABC[958] = 0x272a2c22c5eb6e36d17a40e65d9e6f18fb509b2b49c7f199c2dca3946af485f7;
			gammaABC[959] = 0x4e24a3ca52163a8252c183ef807b53bee19889d649f46b6ba1da4673928fa00;
			gammaABC[960] = 0x2ae96c40d76dcc0fc596211e6b1330dba14e5f9b951d8413f0ab14ea8686f7dd;
			gammaABC[961] = 0x14c204589757dedfd3d399f47692616ba1dcf26472325982b0fef18c0650cb68;
			gammaABC[962] = 0x269e46fd000babf7cbdbb85c1f14973f6a3d41814723fa41bfde0052682f2b7c;
			gammaABC[963] = 0x1c5af35216d7a4ceb3fd36e7005461470b3cb41dea4adb1efaf3be87feea11e8;
			gammaABC[964] = 0x2d6b313604065a5bfc5304405fedc6ddf59b2d389a4be96c6dff783909ffda8a;
			gammaABC[965] = 0x1879e296f2fe273da7fd900ae1c644014f1165c8579c6966e9b6c2c3988f1c24;
			gammaABC[966] = 0x91bbaede0dca43a9577a569b50e9c9ea45272af65471b1d8a965d2c353788ed;
			gammaABC[967] = 0x2b7a833394a5cfae7b97500623d3a630c95c0f75d17bbe9d1b3a6ffdcbd105ed;
			gammaABC[968] = 0x2ed578210f9416972e3a70cd19d4b0f975c57111d15601a8ffe0739a3500fd37;
			gammaABC[969] = 0x14f639e2dc04f050c3795b583ee710961ce7c8a135d8b87906402959f28211f6;
			gammaABC[970] = 0xd456775ef485fbfaaadd2e6eebbe87b8d71ed980ca9c4bd7dc62b60c0b601be;
			gammaABC[971] = 0x18acdeacd9eeaf3d395f7dbfc05438e0d62c14e96c3ce7f2f9d8e7e3460b337d;
			gammaABC[972] = 0x22883b811c5007f8275677685ce07e6f4d6bd430b4719f08e4be96df02d2fd8f;
			gammaABC[973] = 0x25a727848555761a5605fcc4087758c4519e2c1811e00f3db11d14add16506f8;
			gammaABC[974] = 0x1ed9660dfbb9e69d5ab2a59ef8f46dacbdd4db19ce99a12225c989196343c2db;
			gammaABC[975] = 0x51818c72829f4d6d8bfbf29a72cef9d5e6c6990634cb745e66b93ff852911ee;
			gammaABC[976] = 0x44ea418b75eef728ed344d59a541bc00fa4ec751fc424660b89a8334d106fe5;
			gammaABC[977] = 0xc37c06b6ca779f561f34d46de9bc456c04fa7a36bd879d67ef01a013a6b3dd4;
			gammaABC[978] = 0x1df0f8eea85b0e29d02e40d3dcee8f066b6ad578b8f2b8dea839b6d6e8386d79;
			gammaABC[979] = 0xc6c2be0556f4cdb1d7169845da069692f8c579d3322f69c7b669b74f15c61e6;
			gammaABC[980] = 0x1851b6ce02de66cd385f4e855a19e8c4ab949cc028c5023efcc848278bfbe86a;
			gammaABC[981] = 0x25e07fc0b7deae8386541f519351621d15390109f914e90c97c965e49ef67431;
			gammaABC[982] = 0x300dfa3e40da87d9a657a606d9eefa6ae1254c6f1bfe3a944a01e74751e1743;
			gammaABC[983] = 0x5b77d995fda04d9f191bebed65c4dc762d1981a697fff6978da68f3ebc539b2;
			gammaABC[984] = 0x15c3030c4699682e44fdc85ba229db21ce1b280620f53706c2609a6d2c132ed8;
			gammaABC[985] = 0x197f21f6456b46eb825f6f60e737a1dfb82ed077d5b7625e973fad8367139111;
			gammaABC[986] = 0x83f541ffa4c2b6c5b280267c72bc99d72836de0e88af35182285509177bb59c;
			gammaABC[987] = 0x16e905764a4fdb4f5a4adae23814242a00aad6d8085f5fefb605a06126182cba;
			gammaABC[988] = 0x1945a1a0f277da0f76fabad17c308612b09f0eceda5e33629cada71cc8c5f456;
			gammaABC[989] = 0x25520ff79c3f66fd61df1f56b1e9598725e0cdec030b8d043bbba3d62fe46d46;
			gammaABC[990] = 0x2afe4b20991c077652b24161fa325a88b5ac76ae734ee3cd96936030df224d46;
			gammaABC[991] = 0x2fc0df99b7db9f61dc8e995b712328bd20a8af451e3ae22aad7bbb007fa5c07d;
			gammaABC[992] = 0x1c03ed0270cd5b1718f7e7aa2fc74e429c2a0c40cc08fd2c8703699cd82e515f;
			gammaABC[993] = 0x13a5c1ccadb4214e4d446f45c78e72997de600ddf427fba0d5b766a75a1d9b7a;
			gammaABC[994] = 0x170d76f3e66e00c20efa903098a93fb0528086c69776afd13c55c7db6e427b96;
			gammaABC[995] = 0x8266c4117307bd08c0ce87cb3e62145f5a9ad4f9f14275e5dca18b11d6b1e8a;
			gammaABC[996] = 0x180c27f46b2ce17d8892e588693ce57ae9b980a5cb1f324afa27f55036d77732;
			gammaABC[997] = 0x126e82fc621abb43095377bfb84b0adcafb18280d47a6c766e927aeb58981903;
			gammaABC[998] = 0x195a694f5d925b0e89d1aed0c8eba194c70c8ba63a6b477b0c1c941cda4f006e;
			gammaABC[999] = 0x1e3601f3eec5182e6a63b21e5d13890c8cc7ccf899f4b2b7681a7f25cdc2a971;
			gammaABC[1000] = 0x2cb98f7034dd9a7c1c1a30628139b8020c1bc6b52c6f1f06bd81d8b4627f3991;
			gammaABC[1001] = 0x20b79842c6ddd9943ad595bff3369b070f7d6b1dcb7ea1276ae4760c2c733b6f;
			gammaABC[1002] = 0x1f8121c58d753a2724db3bbff0e964907978d71b8b8e68842c3b7ebf39a966;
			gammaABC[1003] = 0x2277e179dd375b3e7724abd4b91c12aa8991b0a787b83d51528e070915a7ef3b;
			gammaABC[1004] = 0x8499715f33e6a2efe0fb4d37eaf9aaad09bf5acd677d107d38d8b501b57883f;
			gammaABC[1005] = 0x5380e13c1c13f93dbdb6ccbca0ba6fce5eb37d76d14c0907e00a0e385141f18;
			gammaABC[1006] = 0x318b48d67cf27ba2ca9b2e772f1ccc2d52e2317a7aec25e365c0f3b38a9e70e;
			gammaABC[1007] = 0x1d6b6b2efd6e33df1648635b6f3c2c6d942ec8c1d54306a77bf3da41af05b03c;
			gammaABC[1008] = 0x5670a0ac32a847536ac2ccebee288a775f1761259affed1e4e01359d41826e;
			gammaABC[1009] = 0x18ac4566b8dc8782e7e87d7b3de0500af745edb7d0099de2a8f3fa8b87943a16;
			gammaABC[1010] = 0x18d15dcadbb358cbffcc6b779e749fb7c4500c79651a9015d20a6d11ccbd21f5;
			gammaABC[1011] = 0x45b8c0661e03e53052f7da132adffd16f06cfc43930b8cd3c9e2e335d9a011c;
			gammaABC[1012] = 0x1ed64caf8dcaddecbaa09c8e1ea0c2058043f563fbd3183db26c768aef9adc29;
			gammaABC[1013] = 0xf42853067eb5078108d08985268e756593523ee64a0b12db18c3441dcbe5b54;
			gammaABC[1014] = 0x277b199114254645fe3437c8608d06e19b447ed6515c6899ad075685ebbfc390;
			gammaABC[1015] = 0x185d6ac4d22cd2212c9645bfee79f1ed0257907372fa43e44da529cee7ae6ae7;
			gammaABC[1016] = 0x289ca456a6209b09e828c9372e7754a76e35095570b9570bceeee010a8ee996d;
			gammaABC[1017] = 0x1fb916806582fa72e6102458d409c8f3181c34ca7cee57b8aba3910e5e3381a1;
			gammaABC[1018] = 0x28f460ac9f0b62bf4d790170784379c5855d7e2358be0101e92203c8ab479b07;
			gammaABC[1019] = 0x16361b57f2e7b486d5d051793a36026909d9c82ebed3f86fb3b824c33b7f74d0;
			gammaABC[1020] = 0x138510f1676ed547ccd29dbce401bbc63964d1e5b02cdf0e27b23a11de10d1d4;
			gammaABC[1021] = 0x25dfd319cc2caf0fd118dcfecf79757b6de46120c95f741a3889e3c5630653e3;
			gammaABC[1022] = 0x12751ec81159e8489900e7d273f1cc10d6f38b34cc6189e0a34f768bc3406a99;
			gammaABC[1023] = 0xa03453288390cda4c42261a87367818c83dfc8f1d8eed2a97e7c13b8b1f8c71;
			gammaABC[1024] = 0x146f4082ef519e66835e7b59753dae621a0247fad80ed63617d2a401dc20aca9;
			gammaABC[1025] = 0xe6c31fdad3237c584d559b416c47cfba37ebc90a6f3d413448f28bb3aff4094;
			gammaABC[1026] = 0x2fd8604bfd39bb812e34eb6a43793166fcf7d13f622831e2899d8ea23aa59aef;
			gammaABC[1027] = 0x25d0d7cc8a4b8cf20e908cfb0d8cfa6ebd7a8eb9287e1fef9fdaefd0a904513c;
			gammaABC[1028] = 0x34345723c6bd844d4393e29226dc085d22b9ec6c37d7313dee976434367219c;
			gammaABC[1029] = 0x1eda62aaa06f8bc905a17c9ca4f517f5f8d07da287dc18a01f08a3ca6ac3df22;
			gammaABC[1030] = 0x241403387775b40abe92d7a3fb8b9213d03b6e084cfd0392e2c391620db61b99;
			gammaABC[1031] = 0x14310ea3f6841a86b1f149ff8149a686f2962a0adbe7b60bb1499a3a370007f4;
			gammaABC[1032] = 0x1febf260ba9ab9c13a808c71812ac503a740307f7174a7a340bbd036d640e340;
			gammaABC[1033] = 0x270cf9ddf2d793c731b63c392c2028b139a0319eaafbc37ac0f50bc9141a132d;
			gammaABC[1034] = 0xaa8b025688aacbec802a5051e165fcb99584c485633a70b2043f9361e8b2f0;
			gammaABC[1035] = 0x143cbc968ef743b2321ec42c1321706b59081748c05c86e161c115d98b979add;
			gammaABC[1036] = 0x1aa27e7b59ca4432d88e9a3beef24d0f330ea51e89ce284ca5d734031e78941a;
			gammaABC[1037] = 0x41ebb28c5e7e34a342f94fc3e84446f62553d48541e9d06dac01584551d2d40;
			gammaABC[1038] = 0x10ef5681dd78409ab4138f65a5a829e94efd06bb4eb112666401ebf174648f88;
			gammaABC[1039] = 0x1ed72b7ca6a08ecdc2bf5648ec508ce575983b0fb5f503cb9de1cd6c4cea6164;
			gammaABC[1040] = 0x20ee6210087b79b3403f873cb48378ece1cac1c356e194921ad32b6b357cb78c;
			gammaABC[1041] = 0x18a0c6834e5f606970a035c9e00d43f7cf9d439b027f4baf826f102024c1596;
			gammaABC[1042] = 0x2e228f65a65e8b3dd3146659b28149e865ded7da7d81357c2a10ec3d6d1b724b;
			gammaABC[1043] = 0x19096cf35b3859520c8eb1054834de66a1c782314f372ae0ca51aebe07757aeb;
			gammaABC[1044] = 0x18fb61ecda1c461d2a72df6a4ef3a9e7fd3bddf1a3c3eebb11b40c30ba3ba3d0;
			gammaABC[1045] = 0x1696dbe9a05b039010737cc346207c135c8fa1831838e3aab5f1acbd5318d8e5;
			gammaABC[1046] = 0x2abb5d6473ace66bf6d0de592875a16f666d63be5adab723b7e34a06fd67465d;
			gammaABC[1047] = 0x2519ddbc2d752162987a3482f1d48a30da66df8409acde43c596d5df793ea9b1;
			gammaABC[1048] = 0x80b3ecabdbd7f7366a3d0b133a06b9dfc0453cba838e175c6b2ddb2309e2db0;
			gammaABC[1049] = 0x2d5a7054674e4f02643942a06382295f1e0491108ad1c19a22e2635f6c6185f1;
			gammaABC[1050] = 0xcec8def0c1f8aff69c2847daafb2ec73083b3701dd830025340aa3bea5ea14e;
			gammaABC[1051] = 0x3edcf21a34fe7a59ebd5d792472a67450327fb49488de44378c7b7855448c30;
			gammaABC[1052] = 0xb5183d25ec0f627f59f8d0bb7b8f072eceb8a6970df5647017951283c42053c;
			gammaABC[1053] = 0x298848248b37e277ea5d9f1f391cf4562a1184f5444b06c73064be69e74c592e;
			gammaABC[1054] = 0x12ee56b2441c838d928bf6c005aa80c3438a9a64faa77dfd4e5f357c35839169;
			gammaABC[1055] = 0x1a18a0c156fa45f1ce07528104f7eddbdef6cb0d4148cfe63d9ccbccfbab2115;
			gammaABC[1056] = 0x1599f55abb6662e80d1183f80512a8ccb2e95f196f78ca5a5cf5b7f7c06354ee;
			gammaABC[1057] = 0x2f662d5caed4eb6c53d51e59ae27e52a073a5e45c139cf60c753323c6103ab19;
			gammaABC[1058] = 0x1e14334dad210c4056821591ca8e94bdc21b8f8d56ec554f186d0131c5acc06e;
			gammaABC[1059] = 0x22d1e97761a061f30f670c056cfc21c1d86779562fa6331a3416d9cfaa2f94af;
			gammaABC[1060] = 0x1362fff486a44f426f161a32c9178788995b42bebc833879ed0919051b99f7ab;
			gammaABC[1061] = 0x1a62ef8c0bcb689156748a601a9fa3b76b80934500a66feb78ab6e075f8fef79;
			gammaABC[1062] = 0x1c0e82bd22bd7db07e7caa560c7d2bdb1b00e3c51ef694627b7a5ba1688ebc17;
			gammaABC[1063] = 0x18845de25ec5cb770090b15df18d2d23cee5bb5beb512a6c7aa68e094095a042;
			gammaABC[1064] = 0x21b04891da4b73a9eab13d3babd8316d3b38d38a22950f307a573d9647449c90;
			gammaABC[1065] = 0x29dc13fa056b5d5a7e13030f8ca0e17f2a6557b7b07421a090615001e37a32b1;
			gammaABC[1066] = 0x1bede1f37b405fd997ebebbe35227c0f4d219ec2f4ee15fca392f84226f7651f;
			gammaABC[1067] = 0x14a2a39e81bc74297d59fcf0a3ddd150612c2a11e75a534ef6b7c45c98bc48b1;
			gammaABC[1068] = 0x9f9f53af57e51705d33246bb4bd22adafbb496ef58b7be51746e54ed9a94454;
			gammaABC[1069] = 0x239fc0e2b00a48fe01e64b8d81c9ba6a6c0f501557bbf25afbd0d4498a681287;
			gammaABC[1070] = 0xa9efdedc1e665767e0d2da58fe4249c32148620308e5320e890a339a55ae91d;
			gammaABC[1071] = 0x141327e2351cc57a24617e8f775d0bb45e5e269e2bfb2eeec63da747d39048bb;
			gammaABC[1072] = 0x8c6d2c26f5e17aefe55443555369376043d73a509a782f15b1a17635ca06239;
			gammaABC[1073] = 0xe1312eefcb68d9526c62b0e95c9420ab3ff847f33772e7d3a2c45b0d6eea650;
			gammaABC[1074] = 0x2cfe7a3de95e45f7d60e14de5c660c5034d2a45d70b6490435bc8f64782065d6;
			gammaABC[1075] = 0x22be3a3070895c6406fd29e760bd66f94b22c7c1dd0c176ee1322fffe37d8f5b;
			gammaABC[1076] = 0x983789c8f23b9f99e5235e959d22a09dee5dabb0510ea62fcf053689d696d0e;
			gammaABC[1077] = 0x232873ee4ddc540f30fb634518035ebfc3e65e88fdc858962c8a9e0f67f437f5;
			gammaABC[1078] = 0x1ff84e80cd62d46d28453c74f459b0d6a7e3150e291617b6be513b817ae3cac1;
			gammaABC[1079] = 0x1a9c108e0de9179ca3817bb781ad6075774d050a2cb8bb1829f2d904772481ad;
			gammaABC[1080] = 0x4c70727639179a8c06e60d78f578b97eb6ede89eaa0598b4e0366379f12aab3;
			gammaABC[1081] = 0x23440ee1a224fe84e3e7529c073213c129040306a0e9509fb26fad95084e57b0;
			gammaABC[1082] = 0x2bea4d1ba26eef66b20da7ed3538f260cd25a204c8b393ad39fe595fbd547f91;
			gammaABC[1083] = 0x9fde54cac938a667e038be64ce25ce69a4b8d0e1fbc20e7961bf96b7cb22d00;
			gammaABC[1084] = 0xfc91bfe670ac741111b548513e4e078c3e7528e55914b488dc2535e90ae41ed;
			gammaABC[1085] = 0x1a3372effe99f78ae4f2c793e22090ece44d57a0d3aff3c9043c943e2426fffd;
			gammaABC[1086] = 0x7d9490eac28eef4422fd1864da4a8dc6ff32f79b7689af3f3f9b1911b01815;
			gammaABC[1087] = 0x23d52c781771274eafd101fee9e087380b8021b3aeb05941798abb857432c42e;
			gammaABC[1088] = 0x4ca981d25eb6ff9717b502b9e17e8d850cfc72e197b89f0044fd4bf4bf91e11;
			gammaABC[1089] = 0x23f0ed8232092eb50d8848838a28ea946e617bdf7ffcecc5d9ae403a7d3cdbf2;
			gammaABC[1090] = 0x2937288cf89d3e4dfc30beb08322af3b79594f30fdd8f62145551dc360690051;
			gammaABC[1091] = 0x2e3e189432040fe56046145048b6bfaa706877f648517507271bd5ff163ccdb5;
			gammaABC[1092] = 0x2fbe1e799684aca4e8d3c4a4f4cd53eca3b48f069753c2eb1ca284a0a251152d;
			gammaABC[1093] = 0x26e2d3128d0743f7d427f92af90cd9f460943c136892c13a223298184425c6cb;
			gammaABC[1094] = 0x19c9ec939bc62042c5a46fbf7080f72a04e5c95b752b409ef3e234d718bc6c1a;
			gammaABC[1095] = 0x85afb878c312abf03a8b6309679c21dc42c0a62953285432fba74a7fd7fd3a9;
			gammaABC[1096] = 0x26c03362bb2de7d17fb6891250d19b82bb9bb3fed7ec975616187a78ca737be8;
			gammaABC[1097] = 0x4600ac252551b5107feef15a65317a99fa9e158e954294f6cfe3a2b9a54d349;
			gammaABC[1098] = 0x5813d60ee4dac188e9b0a860267c7ee39a69fa923fd2bd3f5c8641f1bb142cf;
			gammaABC[1099] = 0x20c7a39049aae65e9a2bbec88a76e0f0afdd5828c529bb893d5d3ab830323fb1;
			gammaABC[1100] = 0x1d79e42d4337bf774a2e7d21da34d2693590eae26123316db12d60b1da02dc0d;
			gammaABC[1101] = 0x24a30a563e65bcecaf1eec4fba97b19e540ae62f4780b64026213f93f826b4d5;
			gammaABC[1102] = 0x2eb019131d4f5d2fdadbe5bd34da420266c4d4216eee7765983eb35f87eafcbf;
			gammaABC[1103] = 0x2ed849a8724593d8fdb1dbc7c45c154e86dc05abd2dae391b3f5cbd8a44b8e21;
			gammaABC[1104] = 0x2d6fe968ebb7de5ec9da748f281c55822c8f317d72dc423742c3dba727795684;
			gammaABC[1105] = 0x2ea7c1ab9069409443db95712282409ddd3d88f6531895b7a359a943ba5b9e5a;
			gammaABC[1106] = 0x1e5f98b1766c3de61d71e1af374c0ec32ce0058a3fb0273da9a1714d09898d94;
			gammaABC[1107] = 0x116b79f8c2b047ee9a303375beeaf558324f8a956e264b1972c6ef1caed34a0a;
			gammaABC[1108] = 0x19466380446abe2d0d9d0a8b56156317795713c01ea2f47eead319206d138f21;
			gammaABC[1109] = 0x2dcd284abb6e09e79cc41b1a67395cddd8df98e2fda995fa8713ae58f75177bf;
			gammaABC[1110] = 0x133018bf500dc33e18da10daca99d0f47879c718bd9a89b85f3f426dc6f3f92;
			gammaABC[1111] = 0x21c43a8d781535b1bfb852ec1fcfadbef496e8384f875b9eb645c38fa19597df;
			gammaABC[1112] = 0x24da1b519a768a8054a5d9c97de9b3e464725f99cc47fb55cd72bb092c389ff7;
			gammaABC[1113] = 0x26e40c29664e8937a6a18d11b495d5063460b3db2c1fe2fdabb95564bf19246;
			gammaABC[1114] = 0x4cb3a49d11024cfc9a4e720b4ac487f019c6493ff8a3ab2509e5e4930a6f35d;
			gammaABC[1115] = 0x257c8d72bd5c52f25f72da9547be3a8a26efeb9c7a10d9828ce484a8c7743584;
			gammaABC[1116] = 0x238f7fb90873d561d679582f84494995c3cccfa4c66baaa85f167996c43a7514;
			gammaABC[1117] = 0x173bbc152de3ab8a782680a0eb5cfaba9bbbeb2934485c5213233c64ad478aa8;
			gammaABC[1118] = 0x25d70556bf581c98ea19c40e1773ef107235697c3e15b358b26f1805a574703b;
			gammaABC[1119] = 0x2695087223ef3d434584fe51be08c56366b0fc3abbf415865e212f514c2071bf;
			gammaABC[1120] = 0x3b1ebf98f5017cf28b039fd7dbd703687964d66d4204ab9c138a081d691c39c;
			gammaABC[1121] = 0xae56a3d5aaf3569842bf1628e3a90c795cf3c27b34471bf50291e66e9787b49;
			gammaABC[1122] = 0x2bd73ad24e20dc0f5cb63eda6d1c1bd6cfaa0fde731d2a1bf8cb81708f302412;
			gammaABC[1123] = 0x1b9d73d67e6680026d6e5b94ea345af1fe209aa90c878cea06759c4e6e255751;
			gammaABC[1124] = 0x2ce67852dca8d536057c943b78c681b1f2fb3a4e2db88fc9b030fb3758b7199f;
			gammaABC[1125] = 0x2415c4fdd79c579e6659d4afb3496921d26ac118b04a7ba525091b637a0dfecb;
			gammaABC[1126] = 0x812534942f3fd7f99802540c6fb47786675dad2fa4596f10167cdd09c2a55b3;
			gammaABC[1127] = 0x107b037933d15cc813bacbfca90f479a9f36487ba47962b090be53bd07091f5e;
			gammaABC[1128] = 0x14e267c0a331c2abca771349e94221b0b70f17ef060f554f3acbe28d8784fa77;
			gammaABC[1129] = 0x1f3994383f072b18f7c7cb3e84ff3584b1b0fd162e480196d50ec9a7b6972ad3;
			gammaABC[1130] = 0x1f094142b0fe663586348903e90fd52b29868cdc453e7a9b5e33f13a0c4fdb9c;
			gammaABC[1131] = 0x18fdeb07af08cbee54d6a7bde752258bbb702f32796df32fc3dfc33dcfb2512b;
			gammaABC[1132] = 0xcb3250bea7fe05fad7f733c55bd707c24b136465ed24dc92d265885fb3690ec;
			gammaABC[1133] = 0x258a98ff3372d299c063b33287d183455a3ac7ba498fef55ba68e95ec8c0bf2b;
			gammaABC[1134] = 0x1890f3ce79fda18dcc7a44a093b0d59ed72a0be7eb62b30b44f86db561a7d584;
			gammaABC[1135] = 0xe0ec9afb409d53c7690fedeb41101ffc0ce26523f848b907e215eee20f855a2;
			gammaABC[1136] = 0x1d5c402098bff03dd56470a8c555c300525ff7a8f3f2df7a29850ee3c276bd17;
			gammaABC[1137] = 0x2896b1d2e89d2ea586c183a3f08496c625cb7bed85ab08bf4b452047890fae25;
			gammaABC[1138] = 0x28813220c2c3abd5b04167d728d667503dcf14a3228aa5b1c72ad6fcfe2dbb66;
			gammaABC[1139] = 0x1df4c995ee00826fd94f31dbe466a86b4605a79861d602bf02a3fa56b342881e;
			gammaABC[1140] = 0x1e158156be7ff4ccb572cd5c9d7f7e18452aa9b31f8f65acff4617e9d9e0b7bd;
			gammaABC[1141] = 0x1dd461385097ddc854d89bcbcc0cacbb1583807cc70843e37839046bc67cb0b6;
			gammaABC[1142] = 0x2119693c315da576125bf96bda9c2ad1e513cf6d984d330b6f5857eb588e89d;
			gammaABC[1143] = 0x2985ee45ed2acd2943fcdb4ecf95350dae068032d1e302ec6aab90e1ecb81582;
			gammaABC[1144] = 0x1442714a90e5928c241903b0c259a43723c4cdbf314fe49daefb0a8359b89231;
			gammaABC[1145] = 0x206cd74f5ed1fbe1f756d5588990450e78765c88526b458647a5c5da11a675ef;
			gammaABC[1146] = 0x25e804adf54b38739e3db0794141131a2445a930b86e66f821f5cf145cc643b4;
			gammaABC[1147] = 0xde31201df87e88bf347b11e06def46357cc40f650bd45b845a8b612a6fa23d5;
			gammaABC[1148] = 0x2756499201afdbdb2ef53cb2024ca5f2c5c56ed064d228fdef23cd762db1c240;
			gammaABC[1149] = 0x1c3a62816c18e4af3a05e30a0b1ab834dae165d065c5b1b73ebb24df90299125;
			gammaABC[1150] = 0x99cc9f70c10f0a03aa9202314b77538faf5e6283ff5e30998b5ee8635ad0b45;
			gammaABC[1151] = 0x230cb93c120cceb416675c369564388ecb72cc0c9a189ec00913fa40464b2704;
			gammaABC[1152] = 0x11e00ad41bc9d4b1c501b7c0211d3971441227e54d92d9c0413b66fc4e0c84a4;
			gammaABC[1153] = 0xf1cdd932c96e3d78aafe6674e6d820fa73c6a135aa84675d0652d126077957f;
			gammaABC[1154] = 0x1c0bff90b2601508d4ae37dad5acfe9fc4effefde512a1d4d332e5e21acb0f4b;
			gammaABC[1155] = 0x1d509b1b46f0bd421759dd238e0466b95779a88e71b8ceaf7c4228efc163bcd6;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    library VerifierReveal
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
    
        function VerifyReveal ( uint256[8] memory in_proof, uint256[] memory proof_inputs )
            public view returns (bool)
        {
            uint256[14] memory vkey = [0x283781d2591bdbbc62606e30b12fd340e4f9dc5824e3f16271d2b84e9a1eb9d5,0x17b0c44912b8a24c89bfd4b5f6ab023270ee810d5110ffa6bed4606e2f5f90b1,0xff9aa30a7f0d07d4e63fb4fa1a897afa315cd902f8351d03879691eab0d9f0,0x2ed9c4cc1aca15444869525baf4c8c3eaee189c42d99ac60a3ebe2d444a31882,0x2e2c7b1d2665f899fd139f62f5628f7aee14882e5dc47b19ce745137d27da1fb,0x75a0a374eb9244e219c653ea47c153baa3a04486b795b6e99ca91e688e40256,0xa97174174bfe11a8219ad16c0ebdd379d9d23644049db25c9a13adca55566c7,0x9ebab9ae92ce943f050673fa28c37b5a1741898d659599a940994a0971f6a8e,0x19e4036561cceb8a8361f892fe44c30b0ec3c4611efc14962153a510a3ec1221,0xf94277eafa88a30b0d6749a68a16e99c80ae1839a8c011de20605569981b71,0x179c629abb00903d7b2735e5f685c0279f68edfedf6257ae8ae8c6d180114f32,0x4fa1a4b7e4c6b3c5a33aaa8d84840bc60650345f228275df690ce18586163cb,0x1e121ff70766043ec1e33a170371a1950bf3c09efba7d555981ed339b8f2d911,0x8bfda31250d0f77134dcaef7946d943f1993c95f9729d0ebe336fe92a58fd48];
    
            uint256[] memory gammaABC = new uint[](4);
    
    
			gammaABC[0] = 0xd931e18f57150f7be929e766e4c8f4475df1c55d52fafbdca4018a56e157f91;
			gammaABC[1] = 0x6f80dd4e45f13f537099bd9e954d6dbfff5ea4072a50f08004fbe57ed0ce0e3;
			gammaABC[2] = 0x2a8fcc63df9eb867297a0f43700d8a41718641109415a2c172e02182102a63a6;
			gammaABC[3] = 0x1493b5ca8cbbc4b79e2f3e30dd6108bfa77395537654169d6b2d99a17c86d715;

    
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
            uint256[14] memory vkey = [0x26ab69014f27fcf8d26707f6da3587dfc7271dcb742767384c9c5134cfb70593,0xc5e52b0adb627dcc66d7f0a173f9c7400053f07ac2ad5b63857f050bcde3d92,0x98ea725df8b240c6f1fde7dfbe0b6aa8f53845adb663cb8cf1ef40f45b76614,0x14c15a3903a88eb6a9c40a2a05f3bfed0a6723b3e0cedfc82ee7a9c077d60862,0x1eb73b776726ca12775dd79347315d30274196d0d4a6957912bc1da0ebcd27f7,0x1db40cd50c5cd999085f925bc6ae7ff2be8212fd97306b32daa1e7de8b653e13,0x4f90f25e94b1627c7d0621e33f59d833727b7dda114ca523350ffe02deab6ca,0x20093b46798739f6d0b4e3b1a4100f8e271e1bb7680dc1639f9314d4e8d55df9,0x16f52b51b1713f4aef64eb90510020d3b8e94e11f4692d6632f0536cb146c056,0x1e4bb63bf4e465fee53be58149883b7f4ac2c90d6f1ed6e2671919f52bf9551c,0x1f1be774fa8107470ea4be6bc42a878a2004a29fe0e86d095c4982de9cddcf4e,0x22cb1cfc3e759bfb312f974a28ecc844cf3f94dbe163f7c42f826e5e273d0b5a,0x170f76e6a27437f2af03f8158f83685c19b889725a78982c746e3d50630b4bbe,0x26c31bb89072048cd18fcc7cb405017b3783f832afce5654fc1e49abf4439b52];
    
            uint256[] memory gammaABC = new uint[](140);
    
    
			gammaABC[0] = 0x952d879ac07f6b888d1e90b1a4687a900d9cba3c9eb888fd1e8ff05c49f7c61;
			gammaABC[1] = 0x148aa85a71f280dd551eb97112902183b4f6ce2f8247fe5e12a3729a68c8cd10;
			gammaABC[2] = 0xabd00421c67179ce528c29a5d35301907b5b2c28c609f7c80db99ed8d326bd9;
			gammaABC[3] = 0x2e05f447a240cfece138a9a509886ae1a2ea65cc873007d07d754e1861352941;
			gammaABC[4] = 0x2298ffe3f67055fb759cd2387655980d081bea7490efe391f2c0a0f156ec8cc7;
			gammaABC[5] = 0x1608c1a4cf81b636400e4247f0ccd7761f1a2cfaecee5cd7281f746c24fd33cf;
			gammaABC[6] = 0x1058c5250fb6747886aa16f3a31a50615f73f4c7ce2d2ac2fea9a70dbaef849b;
			gammaABC[7] = 0x143c20a5e1b4c2a36b0713d648fdbfdb7405a00a7b829e22e364af69fccddd58;
			gammaABC[8] = 0x181cf6bc0172d70524d91243acfeeaa3dce13241378202caa16035003d3cfb42;
			gammaABC[9] = 0x18e778ccbaf2ab177d48b4eb9ff914c2027683cb94c9e39351fcfbac28650ccd;
			gammaABC[10] = 0x16331487d456e08dac26e10f3e0183d4c7ab267eba71715d841b6b97b7f3ae3c;
			gammaABC[11] = 0x1296dd03c0096d644679ffb1bee3d10d4561d40da5b6c11f6faf3d1c22ea8455;
			gammaABC[12] = 0x1ed2d01bedd4507aef94f6149214ef731b7f7b5484e2c8ec5d9eee7b1244b976;
			gammaABC[13] = 0xc225ecde344a634bd1dac3da0130537649d422000f83658641d9ef207554bb5;
			gammaABC[14] = 0x1413215aa1c013a88ecf8e10bd6084fa8b65332a24f3e632715b4f93d472c4c6;
			gammaABC[15] = 0x197dba3b3d2609287985edd70547d2f52233ae38ae83b1b59576ee7e8e10f473;
			gammaABC[16] = 0x2e6f24c2b6be9f29a2e68e64f1d7d74731ad3108f15d0312854791bf99c1c02;
			gammaABC[17] = 0x234aa1eb74936898aed3d1afe9a1530f3ce7719cc846219039a275d8ea6ca5fb;
			gammaABC[18] = 0x2650cb70cf908d012ba682677215e2ff466fabc25fbf7c136f27e7c6a918e6e1;
			gammaABC[19] = 0x1dc2753e8b758b2b5572f526e1ee064cc2cc6188c5e3f1676c67398b9e9f7b96;
			gammaABC[20] = 0x1c41a2c6bdbe3e1424e52d4afdcb84101ccc8f2e13c49e5474e07cf3f4758d3c;
			gammaABC[21] = 0xb8daf41a054e2fbe3935ad17ac645577eab6fc7bb1744c43554f0f9f55b3d02;
			gammaABC[22] = 0x14ce1351e6a4b1b367cd1d5ae1887b0627bc9c4ec5bf9e811cf8c38b255b6c8b;
			gammaABC[23] = 0x1350cfa77b5f57b542666e331ab4b5ed1c21114f769ced262e79eed069345ed7;
			gammaABC[24] = 0x1d7b70adb11f5375a3503f98330d7c5e07a0ab9513ce46d81450c9dda0569312;
			gammaABC[25] = 0x1eeeed303bea6910b241689b249fab5e8ed2d61e0630243a44306f8d5aa2a4ca;
			gammaABC[26] = 0x10eb2a797b895fd16b5124c6b8316958a3afc13c37f240862e49832fedbbb708;
			gammaABC[27] = 0x15bf127292a4a8df910ee9aeda721db64921a146e0b64997a966d63b12ed96aa;
			gammaABC[28] = 0x22c51e7b1c9b0f824c9d290ed551aac2de08cdedc484c0a8a9ea122945a8348a;
			gammaABC[29] = 0x174786acfc62872c72fb62dcf030f66bcd53f0368b191bc6367f3df0c7b2edcd;
			gammaABC[30] = 0x201ba9735a081d9aa9f80b0b51c17c218813ff3e14723876ffa9d4615bb78e80;
			gammaABC[31] = 0x1b48900d90c24449d70d1f978037a1e59468708245100a18d8119d948a10697a;
			gammaABC[32] = 0x2aa8a3c6601fb9080ec91f419a1e5de2cddd7025a282d4984b690f7d980bc2d0;
			gammaABC[33] = 0x1ae745225d7d3e0ab270dd34b7ed7bb05b52567e4120713924e7883d4de05c05;
			gammaABC[34] = 0x2cc844b43623477d497432e936032ff1503e33c103bf299d5af9f3668910168d;
			gammaABC[35] = 0x2a62d1d889adc48a2ae357b4875d1728524d3a87348e2c91a588eeaea7bfd635;
			gammaABC[36] = 0x242edcf2491ae05beedac85c3735ad496edf4398c0965b150ad78e3305964543;
			gammaABC[37] = 0x23156caad0ddcbc110c2fe24aeedb81f8ce5f0ccc894ad7786427e6c5353bf36;
			gammaABC[38] = 0x2d3db8953593de4b5203e229f29f7e47726f236cd498486d5db97464708b8dd3;
			gammaABC[39] = 0xd3fb1f155dae008d41b861ed5df0fa5565faf5e471947143da5dded71ae9c15;
			gammaABC[40] = 0x1955e698a38fb264bfeacb38fd7cca5d378d95e5a360c8a49b7081aed432760a;
			gammaABC[41] = 0x11bebab3910d5561fc88e84f8ec3ad0f65839d2cdb231812bf0dea9fa90e7fc2;
			gammaABC[42] = 0x28ffcf703ad524860da6dd0cbbc7c3e1fa754dd25c05762c8d4e249d6041f95d;
			gammaABC[43] = 0x1ee56588a51346691516441cc011df16701260151bae55619dc402cbc3ddc9d2;
			gammaABC[44] = 0x80042a0939516e0b476ff748b7f22eaeee2a1e50704af1b7de11f4bc7827d61;
			gammaABC[45] = 0xd182b63fde4ead6ca8d63d92304e760a0e63023f9d70f922866fd4a139d234e;
			gammaABC[46] = 0xd06c7c99abca0c804234debf76915d30d6e8b6e410d33a8a0fb9eb5ce715512;
			gammaABC[47] = 0xcd6ceaca39f992ff69c658f139225458c2bf1550a3dfddd888fa02647104783;
			gammaABC[48] = 0x57d39e3186202a5527e5b6702c9583950e9d9e27f59164354fc0a59408dbeec;
			gammaABC[49] = 0x12606ac3c450dec04b936869b481138768a438141e2761f7705b80d919a7b7eb;
			gammaABC[50] = 0x2616e01d48916cfc65fefd337af7a700216a1f1ab073926c2be960e5da559c47;
			gammaABC[51] = 0x24623bec2483856c7539cce660d4f6c14e5fabdc5b9cabf7aa4eb4b0b51adc0;
			gammaABC[52] = 0x5bb5a4d0d33ecdd6afc4bcad1e93ab2929a473fdbbea1d8301a0186fa402815;
			gammaABC[53] = 0x17e043929c1e0741f0b0b66423d2ba0579c09abc3c2d3724d59dcada369874f7;
			gammaABC[54] = 0x2fb6eb86fe11a75d279f4388f0f9ce1e3bc07edda3c90f3ed1009f3460f3647b;
			gammaABC[55] = 0xc9c832dab2c60a7971ee723152a187c4a134c76261720afa7140cb03486e5c5;
			gammaABC[56] = 0x25301fbe5f480e6860e32ce794a7228ff89a27767bcde557b8b42c7939a4d4eb;
			gammaABC[57] = 0x30047ffd447f3711ef8e10f8b3e811e7239fc788d92cc33412cecbf24087c6eb;
			gammaABC[58] = 0x28b94560a9a7babadffc0ad99da50ed46ccad13714c8e2807f8091a7fa1417d1;
			gammaABC[59] = 0x18ad4c6ef1ec758e09fe2fed29118a9ad0e23afa93b4c5199df67808d896a17b;
			gammaABC[60] = 0x1c979d72a78a93948002bb7365dc9282d2cc7f5474e2f5cf6e95c50dd52bbba1;
			gammaABC[61] = 0x1885417248a0d9beea0b61dc793e39d8d676f9eeb80863bd99ce529659e3ac82;
			gammaABC[62] = 0xca35a966e356aaa853a17d6fc8b742e8d3e606fad24ec17022babbdb620ab9c;
			gammaABC[63] = 0x6de071b89b94646e15e2170fea345fcf4121c24b762799caa9d023f1d11ea2e;
			gammaABC[64] = 0x1ba4f7db284916beac66862777655232690f69679c964ff5b691fc1bfd6fd196;
			gammaABC[65] = 0x6abd1c2019815c9b5fd92902333e6453b6db95992f0d59b33c4799fa979107b;
			gammaABC[66] = 0x10fb77b7db65351c1fb266ad569b6d385a2e32632ff49d39bb4d3be90e20b04b;
			gammaABC[67] = 0xed13a5c8e63912f5057ac9ff6efa8c03a09feeb78d1f5e59fbcf18c1a841cd8;
			gammaABC[68] = 0x2f07b6a5b7377b0d1f2820dbdeed15a3c20b4b2b210bd364e9fac590adb36f5a;
			gammaABC[69] = 0x1c8155d33f39da30ef9a06ad6465883ea01567706d0931d199f38524d26e4147;
			gammaABC[70] = 0x1cebc9eadc90a6e48d2b05dee4d9d775b19c7fc7de40d9febe045830084616d1;
			gammaABC[71] = 0x17eb759ee0c307d3e9b69f76e44eea42482f08c58af90f62e4ccf7f68227075d;
			gammaABC[72] = 0x1c24166e0c1d06e68d22d45b21e7f10b7c4e7f324f1b203ea0c0d10ef9f2f223;
			gammaABC[73] = 0x221614d8d33fc4ab8d5b13f2bbb60463532173e2d1b8931d424331816d3460a1;
			gammaABC[74] = 0x27d637670a1c3ddc19b18a50a0c50a1c035a6895fbfac06530e90b646b48ef61;
			gammaABC[75] = 0x27f78c79bbb70aebb1e5eb152132fb3b0749ecbf4263f811919c5ca8a2752647;
			gammaABC[76] = 0x113bafbee0f9a3da9d2471c636d3a9cdbab33990431d604b2588722a33056769;
			gammaABC[77] = 0x21dbae582ba5a906190a30c8fc084c44a3aee2b9623448740904de95a59aca5b;
			gammaABC[78] = 0x2aa7a135575f3ae114dc5b2f14ebb1b9c437c6dde75af0d58d88d88572136afa;
			gammaABC[79] = 0x3a8dd32885d28e8f458fbd596d903c6209d63e5025dd08bb05c7050a20ea029;
			gammaABC[80] = 0x91fd2d177cef1cb0811287493c100fba4a611b57c7d226ead925da69174016c;
			gammaABC[81] = 0x29c5f254b305e545654d120ebcdc9a5334d5d8cbc68d9576a33e231dff2c92d9;
			gammaABC[82] = 0x166646398bb949ed7944be77c31e49e0a7fc0f0f9a2f084c93ffca809a62de5;
			gammaABC[83] = 0x206885821310f6f8bab0c30c328a6705ba59d34cd6b8c50a837a9e501af1cda7;
			gammaABC[84] = 0xf5f302b4feedeb53deef7c4e9615a11c51fe74c622d800ddd72532b924a0c00;
			gammaABC[85] = 0x17131759747229e2112dfdf1e4eb39e0932058711e378cae715379a4b5569425;
			gammaABC[86] = 0x268b4b17b28da2f1550e8ce8a3cfed62fcee3dd0d15ee1183aebf5fd6e6e686a;
			gammaABC[87] = 0x1bbb58809900faf428f37c1c12a962b26fe79c9cc9b09e1c4913e0fe2eff320d;
			gammaABC[88] = 0x10ce976ccbfd48be9decf2351394f42e86141102b0c2d733226e862197d877b8;
			gammaABC[89] = 0x13d60cc2430f09ad645cff7facf1a4b3348a5bf457dbf1e0613d6a4e7cd55406;
			gammaABC[90] = 0x9345c4a98a7d7619c0dc707f23b5634179643e01507d69c1e8315d9e6137d57;
			gammaABC[91] = 0x2b65c62921cdb4dbf1aa5b88c622713d20bbacf75bf9008683b01fc5dc31cb7;
			gammaABC[92] = 0x1ae174050a3a58c483f8256bb250b46e035c837a581760bdf10617ca16784ae5;
			gammaABC[93] = 0x33ff339caa74f75eac8398b0b86d8294325d7217c07e89f2195209ddc613a40;
			gammaABC[94] = 0x1a9a2d7db79958c4a6c5399ba0cd82abd7bc35dea287e0983b7020a87386f175;
			gammaABC[95] = 0x271b4ae74ad30fab1e7d979eb09ff480c646df4d0f941412c32a42e48c824f62;
			gammaABC[96] = 0x1a0c3ef6879b6376ffc6b4414bb021525c9931bcb630a42a1aa3033ac6d5496d;
			gammaABC[97] = 0x2872741a2940c56ee1455362e1fb6048ea8c1c7021d2442f0b1567ffb6bc8159;
			gammaABC[98] = 0x2a4822b852ec7a202afd2449afde3f4763208947f41264a0f61cd27131381dca;
			gammaABC[99] = 0x1d0b2f2209d3edabc0b6d7db7efc52784dfcf49d2b8386cb5d053b25a85f7687;
			gammaABC[100] = 0x644fef5a80fcf5b242cb4063be32c5910c8ff1f855f7e3f3ea910180b8a0b59;
			gammaABC[101] = 0x1d171c960ffffc8a55393325c918a4c3504b5ca5e62c62841f957bec7bbaa1d1;
			gammaABC[102] = 0x22ac87035568ae2b0a25f4fe5c11985aa5b2dfa28bb10c99194b1386d0b55b8b;
			gammaABC[103] = 0x23838125cb6d7aa5bc557a8efc7a92375b46ebe2ef19074b36328f0db4cae7d2;
			gammaABC[104] = 0x2b6530c155ad058f2d94b790df967b80c84f36ba9bbfebc3c819fe9a44674ed6;
			gammaABC[105] = 0x4878ae0a099bb9ce884ec820eb069e6484245cc2c451742869d81b0856444db;
			gammaABC[106] = 0x2c7d96412160ea5bc9d90a7a5db32a957d694e299c955ce00d85c5b72559265;
			gammaABC[107] = 0x29903a46b8e4413f535b05018227b88a4be5a062785a3f95a4109ed9b6514579;
			gammaABC[108] = 0xb880f4c06ef4c3b54a4931dec9fae74c40935b9304edaa1c97044808b43ce39;
			gammaABC[109] = 0x81368fd227be13cbc09cdd6d0b7191a260d6ea9dd98a84776e2b7b60c368ecf;
			gammaABC[110] = 0xfe8b862b9f314b207cdfa96abaca3bdd5e8633bb6d23d9cf127271c256ea828;
			gammaABC[111] = 0x204efcf70ea1cd9d1b7390f06fcbd2eb260cd6f837797fbc7d9b5f6ae9d086bd;
			gammaABC[112] = 0x4a659ed31c5ce570f7fd0f06cc005027fd931ef3f67cb5eea13d83c4f8e767;
			gammaABC[113] = 0x2b3c39c7afd4686ef2a4852efce4a6a3aa76582b81fb38cf1f3c57376c13cd20;
			gammaABC[114] = 0x2c67e4bf0caa4cbc8885ff337bcaae3068006a4d79d9c7e6091e388dbc3df153;
			gammaABC[115] = 0x11dd4b1370ba97b46ce79259187730f5de70c7ffd1c8de5401a9b67dd2ed118b;
			gammaABC[116] = 0x8ee864f0d90a9ceadea56d4383a4abcb23b5b535e82dcf60422abff5c526436;
			gammaABC[117] = 0x2cdbdfefcaf93293b84cd6405f744ccab94ae410c7e471689a9f0acf07fd9c7c;
			gammaABC[118] = 0x2d51999fa53c837b39097867959487393be7e905e299e1c88c1b28238b000631;
			gammaABC[119] = 0x1780bbd46aec74671d2109e0a6b5a81bc7c7b00b089afd53b1b01902ab0b7c25;
			gammaABC[120] = 0x1beab9f7f566b63d2ef9679acd5eb5ae65bb3ebe140322e224550ccd622b119e;
			gammaABC[121] = 0x26a6764f2dd7496adf9906ca1a146f93b2cd566c44e4ea5e276e3f5b99c0154b;
			gammaABC[122] = 0x778cf7e2448fc9e6aaea9c0ed4123a41526ef6ec7c2c02899184c8749b78187;
			gammaABC[123] = 0x156834b52f7f97a84d4cecfac41f18252c06313fa2105b755387c5ccc511a781;
			gammaABC[124] = 0x5020a03d2ded3daed32e1ad22c34f3d8e0966ddfa7ba03cb93e560810db7d5a;
			gammaABC[125] = 0xf37068e343ea4d4ea3ff138030236b32605b1b8b996c3fe5bad7760bb81a7a5;
			gammaABC[126] = 0x1ecd29d466e631079c78a6496b33b788324aeba0d37590b160dabf4f1253a965;
			gammaABC[127] = 0x2266153564ae631a1fe3fc3a0316a1d475f15a034c84d8d00253304dad01b905;
			gammaABC[128] = 0xeae75699cffa2aaa9047183414af66aa05e065e8b5157b1b9e45707271b2eb2;
			gammaABC[129] = 0x2d719e335a56bf53e8a83b6d97965d4c384962eb04220592b98f8c2f2de46d63;
			gammaABC[130] = 0x29e6a21696d4f72992bc5eccd541fb298c071373147af8440fc99c7af291691a;
			gammaABC[131] = 0x144a67c63d0d8285c10668a482d116f6ec83b74854148ed3a6290ad8a0565b5c;
			gammaABC[132] = 0x293cb1ff6a1746e3a2e7a20741d6194a6e237c9ff687178e57faeac0fe8b26b8;
			gammaABC[133] = 0x2f61bcdba54b1e2a1986adb6143f2290a383043fdad4f53b1c8141b5b61bba5;
			gammaABC[134] = 0x1a1000df5d507220b13d325207f4cc24ffee246a36aaa3648a128dd5c48828f6;
			gammaABC[135] = 0xe1de750fb165fd4373c2502e34f4385d3201ff41d0c58d24c2fddd2ad0a089e;
			gammaABC[136] = 0x2d1ba8d41d0854da6435c71aedf068dbb39632e72d84baf5aaf7f4f64f40254f;
			gammaABC[137] = 0x1e3f3b3d9c6a897ecaeb6a977130990a6a8fd74f98cd2fc11fabb1593fbf9e09;
			gammaABC[138] = 0xa479bd805b5b3b2e7ca76196183ff36a69ede3f8625b4c4875f6346cab02229;
			gammaABC[139] = 0x1e39dfa442ecf5a6829fe33ddb7922b509e84c39e402c2bc8b405766c376bf55;

    
            return Verify(vkey, gammaABC, in_proof, proof_inputs);
        }
    }
    