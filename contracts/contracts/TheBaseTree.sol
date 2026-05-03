// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GreenToken.sol";
import "./GreenMarketplace.sol";
import "./RetirementRegistry.sol";

contract TheBaseTree {
    GreenToken public greenToken;
    GreenMarketplace public marketplace;
    RetirementRegistry public registry;
    RetirementProofNFT public proofNFT;

    address public owner;
    bool public initialized;

    event Initialized(
        address token,
        address marketplace,
        address registry,
        address proofNFT
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "TBT: not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function initialize(
        address paymentToken,
        address admin,
        uint256 platformFeeBps,
        address feeRecipient
    ) external onlyOwner {
        require(!initialized, "TBT: already initialized");

        greenToken = new GreenToken("BaseTree Green Credit", "BTGC", address(this));
        greenToken.grantRole(greenToken.MINTER_ROLE(), admin);
        greenToken.grantRole(greenToken.RETIRER_ROLE(), address(this));
        greenToken.grantRole(greenToken.DEFAULT_ADMIN_ROLE(), admin);
        greenToken.renounceRole(greenToken.DEFAULT_ADMIN_ROLE(), address(this));

        proofNFT = new RetirementProofNFT(address(this));
        proofNFT.grantRole(proofNFT.MINTER_ROLE(), address(this));
        proofNFT.grantRole(proofNFT.DEFAULT_ADMIN_ROLE(), admin);
        proofNFT.renounceRole(proofNFT.DEFAULT_ADMIN_ROLE(), address(this));

        registry = new RetirementRegistry(
            address(greenToken),
            address(proofNFT),
            address(this)
        );
        registry.grantRole(registry.REGISTRAR_ROLE(), address(this));
        registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), admin);
        registry.renounceRole(registry.DEFAULT_ADMIN_ROLE(), address(this));

        marketplace = new GreenMarketplace(
            paymentToken,
            address(greenToken),
            admin,
            platformFeeBps,
            feeRecipient
        );

        initialized = true;

        emit Initialized(
            address(greenToken),
            address(marketplace),
            address(registry),
            address(proofNFT)
        );
    }

    function retireWithProof(
        uint256 creditId,
        uint256 amount,
        string calldata proofURI,
        string calldata message
    ) external returns (uint256 proofTokenId) {
        require(initialized, "TBT: not initialized");
        
        greenToken.retireFrom(msg.sender, creditId, amount, proofURI);
        
        proofTokenId = proofNFT.mintProof(
            msg.sender,
            creditId,
            amount,
            proofURI,
            message
        );
        
        registry.recordRetirement(
            msg.sender,
            creditId,
            amount,
            proofURI,
            message
        );
    }

    function mintAndList(
        uint256 amount,
        uint256 pricePerUnit,
        string calldata projectId,
        string calldata projectName,
        string calldata location,
        string calldata methodology,
        uint256 vintage,
        string calldata registry
    ) external returns (uint256 creditId, uint256 listingId) {
        require(initialized, "TBT: not initialized");
        require(
            greenToken.hasRole(greenToken.MINTER_ROLE(), msg.sender),
            "TBT: not minter"
        );

        creditId = greenToken.mintWithMetadata(
            msg.sender,
            amount,
            projectId,
            projectName,
            location,
            methodology,
            vintage,
            registry
        );

        listingId = marketplace.listCredits(creditId, amount, pricePerUnit);
    }
}
