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
    contract AuctionWithoutPseudo {
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
        
        uint sold = 0;
        uint NUM_FOR_SALE = 64;
    
        constructor(
            
        ) {
            nft = new SampleNFT();
            
        }

        function ClaimPrizes(uint idx) public {
            if (sold < NUM_FOR_SALE) {
                nft.awardItem(msg.sender, "https://game.example/item-id-1");
                sold += 1;
            }
        }
    }