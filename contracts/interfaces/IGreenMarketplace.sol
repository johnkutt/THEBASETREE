// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGreenMarketplace {
    struct Listing {
        uint256 listingId;
        address seller;
        uint256 creditId;
        uint256 amount;
        uint256 pricePerUnit;
        bool isActive;
    }

    function listCredits(
        uint256 creditId,
        uint256 amount,
        uint256 pricePerUnit
    ) external returns (uint256 listingId);

    function buyCredits(uint256 listingId, uint256 amount) external;
    function getListing(uint256 listingId) external view returns (Listing memory);
    function getAllListings() external view returns (Listing[] memory);
}
