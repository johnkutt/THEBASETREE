// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface IGreenMarketplace {
    function buyAndRetire(uint256 listingId, uint256 amount, string calldata proofURI) external;
    function paymentToken() external view returns (IERC20);
}

struct Policy {
    uint256 weeklySpendLimit;
    uint256 maxSinglePurchase;
    uint256 minimumListingId;
    bool active;
}

struct Session {
    address agent;
    uint256 expiresAt;
    bytes4[] allowedFunctions;
}

contract GreenAgent {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public owner;
    IGreenMarketplace public marketplace;
    IERC20 public paymentToken;

    Policy public policy;
    mapping(bytes32 => Session) public sessions;
    mapping(uint256 => uint256) public weeklySpent;
    uint256 public constant WEEK = 7 days;

    event PolicyUpdated(uint256 weeklyLimit, uint256 maxSingle);
    event SessionCreated(bytes32 indexed sessionId, address agent, uint256 expiresAt);
    event AutoRetirement(
        bytes32 indexed sessionId,
        uint256 listingId,
        uint256 amount,
        string proofURI
    );
    event EmergencyShutdown(bytes32 indexed sessionId);

    modifier onlyOwner() {
        require(msg.sender == owner, "GA: not owner");
        _;
    }

    modifier validSession(bytes32 sessionId) {
        Session memory s = sessions[sessionId];
        require(s.agent != address(0), "GA: no session");
        require(block.timestamp < s.expiresAt, "GA: expired");
        _;
    }

    constructor(address _marketplace, address _paymentToken, address _owner) {
        marketplace = IGreenMarketplace(_marketplace);
        paymentToken = IERC20(_paymentToken);
        owner = _owner;
    }

    function setPolicy(
        uint256 weeklySpendLimit,
        uint256 maxSinglePurchase,
        uint256 minimumListingId
    ) external onlyOwner {
        policy = Policy({
            weeklySpendLimit: weeklySpendLimit,
            maxSinglePurchase: maxSinglePurchase,
            minimumListingId: minimumListingId,
            active: true
        });
        emit PolicyUpdated(weeklySpendLimit, maxSinglePurchase);
    }

    function createSession(
        address agent,
        uint256 duration,
        bytes4[] calldata allowedFunctions
    ) external onlyOwner returns (bytes32 sessionId) {
        sessionId = keccak256(abi.encodePacked(agent, block.timestamp));
        sessions[sessionId] = Session({
            agent: agent,
            expiresAt: block.timestamp + duration,
            allowedFunctions: allowedFunctions
        });
        emit SessionCreated(sessionId, agent, block.timestamp + duration);
    }

    function revokeSession(bytes32 sessionId) external onlyOwner {
        delete sessions[sessionId];
        emit EmergencyShutdown(sessionId);
    }

    function autoRetire(
        bytes32 sessionId,
        uint256 listingId,
        uint256 amount,
        string calldata proofURI,
        bytes calldata signature
    ) external validSession(sessionId) {
        Session memory session = sessions[sessionId];
        require(session.agent == msg.sender, "GA: not agent");
        require(_isFunctionAllowed(session.allowedFunctions, this.autoRetire.selector), "GA: function not allowed");
        require(policy.active, "GA: policy inactive");
        require(amount <= policy.maxSinglePurchase, "GA: exceeds single max");
        require(listingId >= policy.minimumListingId, "GA: listing not approved");

        uint256 week = block.timestamp / WEEK;
        uint256 cost = getPurchaseCost(listingId, amount);
        require(weeklySpent[week] + cost <= policy.weeklySpendLimit, "GA: weekly limit exceeded");

        bytes32 hash = keccak256(abi.encodePacked(
            sessionId,
            listingId,
            amount,
            proofURI,
            block.timestamp
        ));
        require(_verifySignature(hash, signature, owner), "GA: invalid sig");

        weeklySpent[week] += cost;
        paymentToken.approve(address(marketplace), cost);
        marketplace.buyAndRetire(listingId, amount, proofURI);

        emit AutoRetirement(sessionId, listingId, amount, proofURI);
    }

    function getPurchaseCost(uint256 listingId, uint256 amount) internal view returns (uint256) {
        (,, uint256 pricePerUnit,,) = getListingData(listingId);
        return amount * pricePerUnit;
    }

    function getListingData(uint256 listingId) internal view returns (
        address seller,
        uint256 creditId,
        uint256 pricePerUnit,
        uint256 amount,
        bool active
    ) {
        bytes memory data = abi.encodeWithSignature("listings(uint256)", listingId);
        (bool success, bytes memory result) = address(marketplace).staticcall(data);
        require(success, "GA: fetch failed");
        return abi.decode(result, (address, uint256, uint256, uint256, bool));
    }

    function _isFunctionAllowed(bytes4[] memory allowed, bytes4 target) internal pure returns (bool) {
        for (uint i = 0; i < allowed.length; i++) {
            if (allowed[i] == target) return true;
        }
        return false;
    }

    function _verifySignature(bytes32 hash, bytes memory signature, address signer) internal pure returns (bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }

    receive() external payable {
        payable(owner).transfer(msg.value);
    }
}
