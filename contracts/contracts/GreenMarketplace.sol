// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IGreenToken {
    struct CreditMetadata {
        string projectId;
        string projectName;
        string location;
        string methodology;
        uint256 vintage;
        string registry;
        uint256 issuedAt;
        uint256 retiredAt;
        bool isRetired;
    }

    function creditMetadata(uint256) external view returns (CreditMetadata memory);
    function retire(uint256, uint256, string calldata) external;
    function retireFrom(address, uint256, uint256, string calldata) external;
    function getMetadata(uint256) external view returns (CreditMetadata memory);
}

struct Listing {
    address seller;
    uint256 creditId;
    uint256 amount;
    uint256 pricePerUnit;
    bool active;
}

contract GreenMarketplace is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 public paymentToken;
    IGreenToken public greenToken;

    uint256 public nextListingId;
    mapping(uint256 => Listing) public listings;
    mapping(address => uint256[]) public sellerListings;

    uint256 public platformFeeBps;
    address public feeRecipient;

    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        uint256 creditId,
        uint256 amount,
        uint256 pricePerUnit
    );
    event Bought(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 amount,
        uint256 totalPrice
    );
    event Cancelled(uint256 indexed listingId);
    event DirectRetired(
        address indexed buyer,
        uint256 creditId,
        uint256 amount,
        string proofURI
    );

    constructor(
        address _paymentToken,
        address _greenToken,
        address admin,
        uint256 _platformFeeBps,
        address _feeRecipient
    ) {
        paymentToken = IERC20(_paymentToken);
        greenToken = IGreenToken(_greenToken);
        platformFeeBps = _platformFeeBps;
        feeRecipient = _feeRecipient;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    function listCredits(
        uint256 creditId,
        uint256 amount,
        uint256 pricePerUnit
    ) external returns (uint256 listingId) {
        require(amount > 0, "GM: amount > 0");
        require(pricePerUnit > 0, "GM: price > 0");

        listingId = nextListingId++;
        listings[listingId] = Listing({
            seller: msg.sender,
            creditId: creditId,
            amount: amount,
            pricePerUnit: pricePerUnit,
            active: true
        });
        sellerListings[msg.sender].push(listingId);

        emit Listed(listingId, msg.sender, creditId, amount, pricePerUnit);
    }

    function buyCredits(uint256 listingId, uint256 amount) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "GM: not active");
        require(amount > 0 && amount <= listing.amount, "GM: invalid amount");

        uint256 totalPrice = amount * listing.pricePerUnit;
        uint256 fee = (totalPrice * platformFeeBps) / 10000;
        uint256 sellerProceeds = totalPrice - fee;

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        paymentToken.safeTransferFrom(msg.sender, listing.seller, sellerProceeds);
        if (fee > 0 && feeRecipient != address(0)) {
            paymentToken.safeTransferFrom(msg.sender, feeRecipient, fee);
        }

        emit Bought(listingId, msg.sender, amount, totalPrice);
    }

    function buyAndRetire(
        uint256 listingId,
        uint256 amount,
        string calldata proofURI
    ) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "GM: not active");
        require(amount > 0 && amount <= listing.amount, "GM: invalid amount");

        uint256 totalPrice = amount * listing.pricePerUnit;
        uint256 fee = (totalPrice * platformFeeBps) / 10000;
        uint256 sellerProceeds = totalPrice - fee;

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        paymentToken.safeTransferFrom(msg.sender, listing.seller, sellerProceeds);
        if (fee > 0 && feeRecipient != address(0)) {
            paymentToken.safeTransferFrom(msg.sender, feeRecipient, fee);
        }

        greenToken.retireFrom(listing.seller, listing.creditId, amount, proofURI);

        emit Bought(listingId, msg.sender, amount, totalPrice);
        emit DirectRetired(msg.sender, listing.creditId, amount, proofURI);
    }

    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "GM: not seller");
        require(listing.active, "GM: not active");
        listing.active = false;
        emit Cancelled(listingId);
    }

    function getListing(
        uint256 listingId
    ) external view returns (Listing memory) {
        return listings[listingId];
    }

    function getAllActiveListings() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            if (listings[i].active) count++;
        }
        uint256[] memory active = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            if (listings[i].active) {
                active[idx++] = i;
            }
        }
        return active;
    }

    function setPlatformFee(
        uint256 newFeeBps
    ) external onlyRole(ADMIN_ROLE) {
        platformFeeBps = newFeeBps;
    }

    function setFeeRecipient(address newRecipient) external onlyRole(ADMIN_ROLE) {
        feeRecipient = newRecipient;
    }
}
