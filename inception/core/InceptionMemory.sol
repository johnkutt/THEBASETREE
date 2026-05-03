// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title InceptionMemory
 * @notice Layered memory architecture - Dreams within dreams
 * @dev Each dream level has its own state, time dilation, and memory storage
 */

struct DreamLevel {
    uint256 levelId;
    uint256 depth;              // How deep in the dream stack
    uint256 timeDilation;       // Time moves slower deeper (1x, 12x, 20x)
    uint256 stability;          // 0-100, risk of collapse
    bytes32 parentHash;         // Previous level anchor
    bytes32 stateRoot;          // Merkle root of this level's state
    uint256 inceptionTime;
    bool isActive;
    uint256 kickThreshold;      // When to wake up
}

struct MemoryFragment {
    bytes32 fragmentId;
    uint256 dreamLevel;
    bytes data;
    uint256 timestamp;
    bytes32 prevFragment;       // Linked list within level
    bytes32 nextFragment;
    uint256 weight;             // Importance/importance for propagation
    bool isAnchor;              // Kick-resistant memory
}

struct KickEvent {
    uint256 kickId;
    uint256 sourceLevel;
    uint256 targetLevel;
    bytes32 kickSignature;
    uint256 force;              // How hard the kick hits
    uint256 cascadeDepth;       // How many levels it penetrates
}

contract InceptionMemory {
    
    // Dream layers - Level 0 is reality, deeper is dream
    mapping(uint256 => DreamLevel) public dreamLevels;
    mapping(uint256 => mapping(bytes32 => MemoryFragment)) public levelMemories;
    mapping(uint256 => bytes32[]) public levelFragments;
    
    uint256 public currentMaxLevel;
    uint256 public constant REALITY_LEVEL = 0;
    uint256 public constant LIMBO_LEVEL = 5;
    
    // Atomic precision tracking
    mapping(bytes32 => uint256) public atomicWeights;
    mapping(bytes32 => bool) public isAtomicAnchor;
    
    // Fission tracking
    mapping(uint256 => uint256) public fissionCount;
    mapping(uint256 => uint256) public lastFissionTime;
    
    event DreamIncepted(uint256 indexed levelId, uint256 depth, uint256 timeDilation);
    event MemoryImplanted(bytes32 indexed fragmentId, uint256 indexed levelId, uint256 weight);
    event KickInitiated(uint256 indexed kickId, uint256 sourceLevel, uint256 cascadeDepth);
    event LevelCollapsed(uint256 indexed levelId, bytes32 finalState);
    event FissionTriggered(uint256 indexed levelId, uint256 newLevelId, uint256 expansionFactor);
    
    modifier validLevel(uint256 levelId) {
        require(dreamLevels[levelId].isActive, "INCEPTION: Level not active");
        _;
    }
    
    function inceptDreamLevel(uint256 parentLevel) external returns (uint256 newLevelId) {
        require(dreamLevels[parentLevel].isActive || parentLevel == 0, "INCEPTION: Parent must be active");
        
        newLevelId = ++currentMaxLevel;
        uint256 depth = parentLevel == 0 ? 1 : dreamLevels[parentLevel].depth + 1;
        
        // Time dilation increases with depth (atomic blonde precision)
        uint256 dilation = calculateTimeDilation(depth);
        
        dreamLevels[newLevelId] = DreamLevel({
            levelId: newLevelId,
            depth: depth,
            timeDilation: dilation,
            stability: 100 - (depth * 10), // Deeper = less stable
            parentHash: dreamLevels[parentLevel].stateRoot,
            stateRoot: bytes32(0),
            inceptionTime: block.timestamp,
            isActive: true,
            kickThreshold: 100 - (depth * 15)
        });
        
        emit DreamIncepted(newLevelId, depth, dilation);
        
        // Trigger fission if depth warrants expansion
        if (depth >= 3) {
            _triggerFission(newLevelId);
        }
    }
    
    function implantMemory(
        uint256 levelId,
        bytes calldata data,
        uint256 weight,
        bool anchor
    ) external validLevel(levelId) returns (bytes32 fragmentId) {
        
        fragmentId = keccak256(abi.encodePacked(
            levelId,
            data,
            block.timestamp,
            levelFragments[levelId].length
        ));
        
        bytes32 prevFragment = levelFragments[levelId].length > 0 
            ? levelFragments[levelId][levelFragments[levelId].length - 1]
            : bytes32(0);
        
        MemoryFragment memory fragment = MemoryFragment({
            fragmentId: fragmentId,
            dreamLevel: levelId,
            data: data,
            timestamp: block.timestamp,
            prevFragment: prevFragment,
            nextFragment: bytes32(0),
            weight: weight,
            isAnchor: anchor
        });
        
        // Update linked list
        if (prevFragment != bytes32(0)) {
            levelMemories[levelId][prevFragment].nextFragment = fragmentId;
        }
        
        levelMemories[levelId][fragmentId] = fragment;
        levelFragments[levelId].push(fragmentId);
        
        if (anchor) {
            isAtomicAnchor[fragmentId] = true;
        }
        
        atomicWeights[fragmentId] = weight;
        
        // Update state root
        _updateStateRoot(levelId);
        
        emit MemoryImplanted(fragmentId, levelId, weight);
    }
    
    function initiateKick(uint256 sourceLevel, uint256 force) external validLevel(sourceLevel) {
        uint256 kickId = uint256(keccak256(abi.encodePacked(sourceLevel, force, block.timestamp)));
        
        // Calculate cascade - kicks penetrate upward through dream levels
        uint256 cascadeDepth = 0;
        for (uint256 i = sourceLevel; i > 0; i--) {
            if (dreamLevels[i].stability < force) {
                cascadeDepth++;
                _collapseLevel(i);
            }
        }
        
        emit KickInitiated(kickId, sourceLevel, cascadeDepth);
    }
    
    function extractMemoryChain(uint256 levelId, bytes32 startFragment) 
        external 
        view 
        returns (MemoryFragment[] memory chain) 
    {
        uint256 count = 0;
        bytes32 current = startFragment;
        
        // Count chain length
        while (current != bytes32(0) && count < 100) {
            count++;
            current = levelMemories[levelId][current].nextFragment;
        }
        
        chain = new MemoryFragment[](count);
        current = startFragment;
        
        for (uint256 i = 0; i < count; i++) {
            chain[i] = levelMemories[levelId][current];
            current = levelMemories[levelId][current].nextFragment;
        }
    }
    
    function _updateStateRoot(uint256 levelId) internal {
        bytes32 newRoot = keccak256(abi.encodePacked(levelFragments[levelId]));
        dreamLevels[levelId].stateRoot = newRoot;
    }
    
    function _collapseLevel(uint256 levelId) internal {
        dreamLevels[levelId].isActive = false;
        emit LevelCollapsed(levelId, dreamLevels[levelId].stateRoot);
    }
    
    function _triggerFission(uint256 sourceLevel) internal {
        // Nuclear fission: One level splits into multiple parallel simulations
        uint256 expansionFactor = dreamLevels[sourceLevel].depth;
        
        for (uint256 i = 0; i < expansionFactor; i++) {
            uint256 fissionLevel = ++currentMaxLevel;
            
            dreamLevels[fissionLevel] = DreamLevel({
                levelId: fissionLevel,
                depth: dreamLevels[sourceLevel].depth,
                timeDilation: dreamLevels[sourceLevel].timeDilation * 2,
                stability: dreamLevels[sourceLevel].stability / 2,
                parentHash: dreamLevels[sourceLevel].stateRoot,
                stateRoot: bytes32(0),
                inceptionTime: block.timestamp,
                isActive: true,
                kickThreshold: dreamLevels[sourceLevel].kickThreshold / 2
            });
            
            // Copy critical memories to fission level
            _copyAnchoredMemories(sourceLevel, fissionLevel);
        }
        
        fissionCount[sourceLevel] += expansionFactor;
        lastFissionTime[sourceLevel] = block.timestamp;
        
        emit FissionTriggered(sourceLevel, currentMaxLevel, expansionFactor);
    }
    
    function _copyAnchoredMemories(uint256 sourceLevel, uint256 targetLevel) internal {
        bytes32[] storage fragments = levelFragments[sourceLevel];
        
        for (uint256 i = 0; i < fragments.length; i++) {
            if (levelMemories[sourceLevel][fragments[i]].isAnchor) {
                MemoryFragment memory source = levelMemories[sourceLevel][fragments[i]];
                
                bytes32 newFragmentId = keccak256(abi.encodePacked(
                    source.fragmentId,
                    targetLevel,
                    block.timestamp
                ));
                
                levelMemories[targetLevel][newFragmentId] = MemoryFragment({
                    fragmentId: newFragmentId,
                    dreamLevel: targetLevel,
                    data: source.data,
                    timestamp: block.timestamp,
                    prevFragment: bytes32(0),
                    nextFragment: bytes32(0),
                    weight: source.weight / 2, // Weight dilutes in fission
                    isAnchor: true
                });
                
                levelFragments[targetLevel].push(newFragmentId);
            }
        }
    }
    
    function calculateTimeDilation(uint256 depth) public pure returns (uint256) {
        // Atomic blonde precision - time moves geometrically slower
        if (depth == 1) return 12;  // 1 minute = 12 dream minutes
        if (depth == 2) return 60;  // 1 minute = 1 dream hour
        if (depth == 3) return 600; // 1 minute = 10 dream hours
        if (depth >= 4) return 6000; // Limbo: 1 minute = 100 dream hours
        return 1;
    }
    
    function getDreamPath(uint256 levelId) external view returns (uint256[] memory path) {
        uint256 depth = dreamLevels[levelId].depth;
        path = new uint256[](depth + 1);
        
        uint256 current = levelId;
        for (uint256 i = depth; i > 0; i--) {
            path[i] = current;
            // Simplified - would traverse parent in full implementation
            current = current > 0 ? current - 1 : 0;
        }
        path[0] = REALITY_LEVEL;
    }
    
    function getActiveLevels() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentMaxLevel; i++) {
            if (dreamLevels[i].isActive) count++;
        }
        
        uint256[] memory active = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 1; i <= currentMaxLevel; i++) {
            if (dreamLevels[i].isActive) {
                active[idx++] = i;
            }
        }
        return active;
    }
}
