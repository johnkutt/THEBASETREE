// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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

contract GreenToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RETIRER_ROLE = keccak256("RETIRER_ROLE");

    mapping(uint256 => CreditMetadata) public creditMetadata;
    mapping(uint256 => uint256) public creditToAmount;
    uint256 public nextCreditId;

    event CreditMinted(
        uint256 indexed creditId,
        address indexed to,
        uint256 amount,
        string projectId
    );
    event CreditRetired(
        uint256 indexed creditId,
        address indexed by,
        uint256 amount,
        string retirementProofURI
    );

    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(RETIRER_ROLE, admin);
    }

    function mintWithMetadata(
        address to,
        uint256 amount,
        string calldata projectId,
        string calldata projectName,
        string calldata location,
        string calldata methodology,
        uint256 vintage,
        string calldata registry
    ) external onlyRole(MINTER_ROLE) returns (uint256 creditId) {
        require(amount > 0, "GT: amount must be > 0");
        creditId = nextCreditId++;

        creditMetadata[creditId] = CreditMetadata({
            projectId: projectId,
            projectName: projectName,
            location: location,
            methodology: methodology,
            vintage: vintage,
            registry: registry,
            issuedAt: block.timestamp,
            retiredAt: 0,
            isRetired: false
        });
        creditToAmount[creditId] = amount;

        _mint(to, amount);
        emit CreditMinted(creditId, to, amount, projectId);
    }

    function retire(
        uint256 creditId,
        uint256 amount,
        string calldata retirementProofURI
    ) external onlyRole(RETIRER_ROLE) {
        require(!creditMetadata[creditId].isRetired, "GT: already retired");
        require(
            creditToAmount[creditId] >= amount,
            "GT: insufficient credit amount"
        );

        creditMetadata[creditId].isRetired = true;
        creditMetadata[creditId].retiredAt = block.timestamp;

        _burn(msg.sender, amount);
        emit CreditRetired(creditId, msg.sender, amount, retirementProofURI);
    }

    function retireFrom(
        address account,
        uint256 creditId,
        uint256 amount,
        string calldata retirementProofURI
    ) external onlyRole(RETIRER_ROLE) {
        require(!creditMetadata[creditId].isRetired, "GT: already retired");
        require(
            creditToAmount[creditId] >= amount,
            "GT: insufficient credit amount"
        );

        creditMetadata[creditId].isRetired = true;
        creditMetadata[creditId].retiredAt = block.timestamp;

        _burn(account, amount);
        emit CreditRetired(creditId, account, amount, retirementProofURI);
    }

    function getMetadata(
        uint256 creditId
    ) external view returns (CreditMetadata memory) {
        return creditMetadata[creditId];
    }
}
