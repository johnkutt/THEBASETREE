// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGreenToken {
    function mintWithMetadata(
        address to,
        uint256 amount,
        string calldata projectId,
        string calldata projectName,
        string calldata location,
        string calldata methodology,
        uint256 vintage,
        string calldata registry
    ) external returns (uint256 creditId);

    function retire(
        uint256 creditId,
        uint256 amount,
        string calldata retirementProofURI
    ) external;

    function getCreditMetadata(uint256 creditId) external view returns (
        string memory projectId,
        string memory projectName,
        string memory location,
        string memory methodology,
        uint256 vintage
    );
}
