// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IGreenToken {
    function getMetadata(uint256) external view returns (
        string memory projectId,
        string memory projectName,
        string memory location,
        string memory methodology,
        uint256 vintage,
        string memory registry,
        uint256 issuedAt,
        uint256 retiredAt,
        bool isRetired
    );
}

struct RetirementProof {
    uint256 creditId;
    address beneficiary;
    uint256 amount;
    uint256 retiredAt;
    string proofURI;
    string retirementMessage;
}

contract RetirementProofNFT is ERC721, ERC721Enumerable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public nextTokenId;
    mapping(uint256 => RetirementProof) public proofs;

    event RetirementProofMinted(
        uint256 indexed tokenId,
        address indexed beneficiary,
        uint256 creditId,
        uint256 amount,
        string proofURI
    );

    constructor(address admin) ERC721("TheBaseTree Retirement Proof", "BTRP") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function mintProof(
        address beneficiary,
        uint256 creditId,
        uint256 amount,
        string calldata proofURI,
        string calldata retirementMessage
    ) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _mint(beneficiary, tokenId);
        proofs[tokenId] = RetirementProof({
            creditId: creditId,
            beneficiary: beneficiary,
            amount: amount,
            retiredAt: block.timestamp,
            proofURI: proofURI,
            retirementMessage: retirementMessage
        });
        emit RetirementProofMinted(tokenId, beneficiary, creditId, amount, proofURI);
    }

    function getProof(uint256 tokenId) external view returns (RetirementProof memory) {
        return proofs[tokenId];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

contract RetirementRegistry is AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    IGreenToken public greenToken;
    RetirementProofNFT public proofNFT;

    mapping(address => uint256[]) public userRetirements;
    mapping(uint256 => uint256[]) public creditRetirements;
    uint256 public totalRetired;

    event RetirementRecorded(
        address indexed beneficiary,
        uint256 indexed creditId,
        uint256 amount,
        uint256 proofTokenId,
        string message
    );

    constructor(address _greenToken, address _proofNFT, address admin) {
        greenToken = IGreenToken(_greenToken);
        proofNFT = RetirementProofNFT(_proofNFT);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
    }

    function recordRetirement(
        address beneficiary,
        uint256 creditId,
        uint256 amount,
        string calldata proofURI,
        string calldata message
    ) external onlyRole(REGISTRAR_ROLE) returns (uint256 proofTokenId) {
        proofTokenId = proofNFT.mintProof(
            beneficiary,
            creditId,
            amount,
            proofURI,
            message
        );
        userRetirements[beneficiary].push(proofTokenId);
        creditRetirements[creditId].push(proofTokenId);
        totalRetired += amount;

        emit RetirementRecorded(beneficiary, creditId, amount, proofTokenId, message);
    }

    function getUserRetirements(address user) external view returns (uint256[] memory) {
        return userRetirements[user];
    }

    function getCreditRetirements(uint256 creditId) external view returns (uint256[] memory) {
        return creditRetirements[creditId];
    }
}
