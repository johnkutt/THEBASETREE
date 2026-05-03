// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

interface IGreenToken {
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
}

interface IGreenMarketplace {
    function setPlatformFee(uint256) external;
    function setFeeRecipient(address) external;
}

struct ProjectCategory {
    string name;
    string methodology;
    bool approved;
}

struct VerificationStandard {
    string registry;
    string standardURI;
    bool active;
}

contract GreenGovernance is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => ProjectCategory) public approvedCategories;
    mapping(uint256 => VerificationStandard) public verificationStandards;
    mapping(address => bool) public approvedMinters;
    uint256 public nextCategoryId;
    uint256 public nextStandardId;

    event CategoryApproved(uint256 indexed id, string name, string methodology);
    event StandardApproved(uint256 indexed id, string registry, string uri);
    event MinterApproved(address indexed minter);
    event MinterRevoked(address indexed minter);

    constructor(
        IVotes _token,
        TimelockController _timelock,
        string memory name
    )
        Governor(name)
        GovernorSettings(1 days, 7 days, 1000e18)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    function proposeCategory(
        string calldata name,
        string calldata methodology
    ) public returns (uint256 proposalId) {
        address[] memory targets = new address[](1);
        targets[0] = address(this);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            this.approveCategory.selector,
            name,
            methodology
        );
        string memory description = string(
            abi.encodePacked("Approve category: ", name)
        );
        proposalId = propose(targets, values, calldatas, description);
    }

    function proposeMinterApproval(
        address minter,
        address greenToken
    ) public returns (uint256 proposalId) {
        address[] memory targets = new address[](1);
        targets[0] = greenToken;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            IGreenToken.grantRole.selector,
            MINTER_ROLE,
            minter
        );
        string memory description = string(
            abi.encodePacked("Approve minter: ", toAsciiString(minter))
        );
        proposalId = propose(targets, values, calldatas, description);
    }

    function approveCategory(
        string calldata name,
        string calldata methodology
    ) external onlyGovernance {
        uint256 id = nextCategoryId++;
        approvedCategories[id] = ProjectCategory({
            name: name,
            methodology: methodology,
            approved: true
        });
        emit CategoryApproved(id, name, methodology);
    }

    function approveVerificationStandard(
        string calldata registry,
        string calldata standardURI
    ) external onlyGovernance {
        uint256 id = nextStandardId++;
        verificationStandards[id] = VerificationStandard({
            registry: registry,
            standardURI: standardURI,
            active: true
        });
        emit StandardApproved(id, registry, standardURI);
    }

    function approveMinter(address minter, address greenToken) external onlyGovernance {
        approvedMinters[minter] = true;
        IGreenToken(greenToken).grantRole(MINTER_ROLE, minter);
        emit MinterApproved(minter);
    }

    function revokeMinter(address minter, address greenToken) external onlyGovernance {
        approvedMinters[minter] = false;
        IGreenToken(greenToken).revokeRole(MINTER_ROLE, minter);
        emit MinterRevoked(minter);
    }

    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(
        uint256 blockNumber
    )
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19-i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
