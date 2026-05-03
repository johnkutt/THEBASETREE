// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title NuclearFission
 * @notice Exponential growth through self-replicating fission cascades
 * @dev Each fission event triggers chain reactions of expansion
 */

struct FissionCore {
    uint256 coreId;
    bytes32 seedHash;
    uint256 energyLevel;        // Critical mass threshold
    uint256 fissionCount;
    uint256 neutronCount;       // Catalysts for more fission
    bool isCritical;
    uint256 lastReactionTime;
    uint256 halfLife;           // Decay rate of the core
    uint256[] childCores;       // Direct fission products
    uint256 generation;         // How many fissions deep
}

struct ChainReaction {
    uint256 reactionId;
    uint256 sourceCore;
    uint256 waveNumber;         // Which wave in the cascade
    uint256 nodesTriggered;
    uint256 totalEnergy;
    bool isComplete;
    uint256 startTime;
    uint256 endTime;
}

struct ExponentialNode {
    uint256 nodeId;
    uint256 parentNode;
    uint256 depth;              // In the exponential tree
    bytes payload;
    uint256 replicationFactor;  // How many children to spawn
    bool isActive;
    uint256 spawnCount;
    uint256 maxSpawns;
    bytes32 stateHash;
}

contract NuclearFission {
    
    mapping(uint256 => FissionCore) public fissionCores;
    mapping(uint256 => ChainReaction) public chainReactions;
    mapping(uint256 => ExponentialNode) public expNodes;
    
    uint256 public coreCounter;
    uint256 public reactionCounter;
    uint256 public nodeCounter;
    
    // Physics constants for fission simulation
    uint256 public constant CRITICAL_MASS = 1000;
    uint256 public constant NEUTRON_MULTIPLIER = 2; // Each fission spawns 2 more
    uint256 public constant FISSION_DELAY = 1; // 1 second between waves
    uint256 public constant MAX_GENERATIONS = 10;
    uint256 public constant ENERGY_RELEASE_BASE = 1e18;
    
    // Tracking
    mapping(uint256 => uint256[]) public coreChildren;
    mapping(uint256 => uint256[]) public reactionWaves;
    mapping(uint256 => uint256[]) public nodeChildren;
    
    uint256 public totalFissions;
    uint256 public totalEnergyReleased;
    uint256 public maxDepthReached;
    
    event FissionInitiated(uint256 indexed coreId, bytes32 seedHash, uint256 initialEnergy);
    event CriticalMassAchieved(uint256 indexed coreId, uint256 timestamp);
    event ChainReactionStarted(uint256 indexed reactionId, uint256 sourceCore);
    event FissionWave(uint256 indexed reactionId, uint256 waveNumber, uint256 nodesInWave);
    event NodeSpawned(uint256 indexed nodeId, uint256 indexed parentNode, uint256 depth);
    event CascadeComplete(uint256 indexed reactionId, uint256 totalNodes, uint256 totalEnergy);
    event ExponentialGrowth(uint256 indexed coreId, uint256 generation, uint256 nodeCount);
    
    /**
     * @notice Initialize a fission core
     * @dev Creates the seed for exponential growth
     */
    function initiateFissionCore(
        bytes32 seedHash,
        uint256 initialEnergy,
        uint256 halfLife
    ) external returns (uint256 coreId) {
        coreId = ++coreCounter;
        
        fissionCores[coreId] = FissionCore({
            coreId: coreId,
            seedHash: seedHash,
            energyLevel: initialEnergy,
            fissionCount: 0,
            neutronCount: 1,
            isCritical: initialEnergy >= CRITICAL_MASS,
            lastReactionTime: block.timestamp,
            halfLife: halfLife,
            childCores: new uint256[](0),
            generation: 0
        });
        
        emit FissionInitiated(coreId, seedHash, initialEnergy);
        
        // Auto-trigger if already critical
        if (initialEnergy >= CRITICAL_MASS) {
            emit CriticalMassAchieved(coreId, block.timestamp);
            _triggerChainReaction(coreId);
        }
        
        return coreId;
    }
    
    /**
     * @notice Add energy to reach critical mass
     * @dev Accumulate until threshold for fission
     */
    function feedCore(uint256 coreId, uint256 energy) external {
        FissionCore storage core = fissionCores[coreId];
        require(core.coreId != 0, "FISSION: Core not found");
        
        core.energyLevel += energy;
        
        // Check for criticality
        if (!core.isCritical && core.energyLevel >= CRITICAL_MASS) {
            core.isCritical = true;
            emit CriticalMassAchieved(coreId, block.timestamp);
            _triggerChainReaction(coreId);
        }
    }
    
    /**
     * @notice Start exponential cascade from a core
     * @dev Creates the chain reaction and first wave of fissions
     */
    function _triggerChainReaction(uint256 coreId) internal returns (uint256 reactionId) {
        reactionId = ++reactionCounter;
        
        chainReactions[reactionId] = ChainReaction({
            reactionId: reactionId,
            sourceCore: coreId,
            waveNumber: 0,
            nodesTriggered: 0,
            totalEnergy: 0,
            isComplete: false,
            startTime: block.timestamp,
            endTime: 0
        });
        
        emit ChainReactionStarted(reactionId, coreId);
        
        // First wave: spawn initial nodes
        _executeFissionWave(reactionId, coreId, 0);
        
        return reactionId;
    }
    
    /**
     * @notice Execute one wave of the fission cascade
     * @dev Each node spawns children, creating exponential growth
     */
    function _executeFissionWave(
        uint256 reactionId,
        uint256 coreId,
        uint256 waveNumber
    ) internal {
        ChainReaction storage reaction = chainReactions[reactionId];
        FissionCore storage core = fissionCores[coreId];
        
        // Calculate nodes in this wave
        uint256 nodesInWave = waveNumber == 0 
            ? core.neutronCount 
            : core.neutronCount * (NEUTRON_MULTIPLIER ** waveNumber);
        
        // Cap to prevent explosion
        if (nodesInWave > 1000) nodesInWave = 1000;
        
        uint256[] memory waveNodes = new uint256[](nodesInWave);
        
        // Spawn nodes
        for (uint256 i = 0; i < nodesInWave; i++) {
            uint256 nodeId = _spawnExponentialNode(
                0, // No parent for wave 0
                waveNumber,
                core.seedHash,
                core.generation + 1
            );
            waveNodes[i] = nodeId;
            reaction.nodesTriggered++;
        }
        
        reactionWaves[reactionId].push(waveNumber);
        core.fissionCount += nodesInWave;
        totalFissions += nodesInWave;
        
        // Calculate energy release (E=mc² style)
        uint256 waveEnergy = (nodesInWave * ENERGY_RELEASE_BASE * core.energyLevel) / CRITICAL_MASS;
        reaction.totalEnergy += waveEnergy;
        totalEnergyReleased += waveEnergy;
        
        emit FissionWave(reactionId, waveNumber, nodesInWave);
        
        // Recursive next wave if energy remains
        if (waveNumber < MAX_GENERATIONS && core.energyLevel > 0) {
            // Decay energy
            core.energyLevel = (core.energyLevel * 80) / 100; // 20% loss per wave
            core.neutronCount *= NEUTRON_MULTIPLIER;
            
            // Schedule next wave (simulated - in reality would use automation)
            _executeFissionWave(reactionId, coreId, waveNumber + 1);
        } else {
            // Cascade complete
            reaction.isComplete = true;
            reaction.endTime = block.timestamp;
            emit CascadeComplete(reactionId, reaction.nodesTriggered, reaction.totalEnergy);
        }
    }
    
    /**
     * @notice Spawn an exponential growth node
     * @dev Each node can replicate, creating tree-like expansion
     */
    function _spawnExponentialNode(
        uint256 parentNode,
        uint256 depth,
        bytes32 seed,
        uint256 generation
    ) internal returns (uint256 nodeId) {
        nodeId = ++nodeCounter;
        
        uint256 maxSpawns = NEUTRON_MULTIPLIER ** (MAX_GENERATIONS - depth);
        if (maxSpawns > 100) maxSpawns = 100;
        
        expNodes[nodeId] = ExponentialNode({
            nodeId: nodeId,
            parentNode: parentNode,
            depth: depth,
            payload: abi.encodePacked(seed, nodeId, depth),
            replicationFactor: NEUTRON_MULTIPLIER,
            isActive: true,
            spawnCount: 0,
            maxSpawns: maxSpawns,
            stateHash: keccak256(abi.encodePacked(seed, nodeId, block.timestamp))
        });
        
        if (parentNode != 0) {
            nodeChildren[parentNode].push(nodeId);
        }
        
        if (depth > maxDepthReached) {
            maxDepthReached = depth;
        }
        
        emit NodeSpawned(nodeId, parentNode, depth);
        
        // Auto-replicate if conditions met
        if (depth < MAX_GENERATIONS && generation < MAX_GENERATIONS) {
            _replicateNode(nodeId, generation);
        }
        
        return nodeId;
    }
    
    /**
     * @notice Force a node to replicate (spawn children)
     * @dev Manual trigger for exponential expansion
     */
    function forceReplication(uint256 nodeId, uint256 childCount) external {
        ExponentialNode storage node = expNodes[nodeId];
        require(node.isActive, "FISSION: Node not active");
        require(node.spawnCount + childCount <= node.maxSpawns, "FISSION: Spawn limit reached");
        
        for (uint256 i = 0; i < childCount; i++) {
            uint256 childId = _spawnExponentialNode(
                nodeId,
                node.depth + 1,
                node.stateHash,
                0 // Reset generation counter for branch
            );
            node.spawnCount++;
        }
    }
    
    /**
     * @notice Split a core (nuclear fission of fission)
     * @dev Core divides into daughter cores, each capable of further fission
     */
    function splitCore(uint256 coreId, uint256 splitCount) external {
        FissionCore storage parent = fissionCores[coreId];
        require(parent.isCritical, "FISSION: Core not critical");
        require(splitCount > 1 && splitCount <= 5, "FISSION: Split count 2-5");
        
        uint256 energyPerChild = parent.energyLevel / splitCount;
        
        for (uint256 i = 0; i < splitCount; i++) {
            uint256 childId = ++coreCounter;
            
            fissionCores[childId] = FissionCore({
                coreId: childId,
                seedHash: keccak256(abi.encodePacked(parent.seedHash, i)),
                energyLevel: energyPerChild,
                fissionCount: 0,
                neutronCount: parent.neutronCount / splitCount,
                isCritical: energyPerChild >= CRITICAL_MASS,
                lastReactionTime: block.timestamp,
                halfLife: parent.halfLife,
                childCores: new uint256[](0),
                generation: parent.generation + 1
            });
            
            coreChildren[coreId].push(childId);
            
            if (energyPerChild >= CRITICAL_MASS) {
                emit CriticalMassAchieved(childId, block.timestamp);
                _triggerChainReaction(childId);
            }
        }
        
        parent.isCritical = false;
        parent.energyLevel = 0;
        
        emit ExponentialGrowth(coreId, parent.generation + 1, splitCount);
    }
    
    /**
     * @notice Get full cascade tree
     * @dev Returns all nodes from a chain reaction
     */
    function getCascadeTree(uint256 reactionId) 
        external 
        view 
        returns (uint256[] memory allNodes) 
    {
        ChainReaction storage reaction = chainReactions[reactionId];
        allNodes = new uint256[](reaction.nodesTriggered);
        
        uint256 idx = 0;
        for (uint256 i = 1; i <= nodeCounter && idx < reaction.nodesTriggered; i++) {
            // Check if node belongs to this reaction by depth analysis
            if (expNodes[i].isActive) {
                allNodes[idx++] = i;
            }
        }
    }
    
    /**
     * @notice Calculate exponential growth projection
     * @dev Theoretical maximum nodes from a core
     */
    function calculateGrowthProjection(uint256 coreId) external view returns (
        uint256 maxNodes,
        uint256 estimatedEnergy,
        uint256 timeToCompletion
    ) {
        FissionCore storage core = fissionCores[coreId];
        
        // Geometric series sum
        maxNodes = 0;
        for (uint256 i = 0; i < MAX_GENERATIONS; i++) {
            uint256 waveNodes = core.neutronCount * (NEUTRON_MULTIPLIER ** i);
            if (waveNodes > 1000) waveNodes = 1000;
            maxNodes += waveNodes;
        }
        
        estimatedEnergy = (maxNodes * ENERGY_RELEASE_BASE * core.energyLevel) / CRITICAL_MASS;
        timeToCompletion = MAX_GENERATIONS * FISSION_DELAY;
    }
    
    /**
     * @notice Get core descendants (all child cores recursively)
     */
    function getCoreDescendants(uint256 coreId) external view returns (uint256[] memory) {
        uint256[] memory descendants = new uint256[](coreCounter);
        uint256 count = 0;
        
        uint256[] memory queue = new uint256[](coreCounter);
        uint256 head = 0;
        uint256 tail = 0;
        
        // Add direct children to queue
        for (uint256 i = 0; i < coreChildren[coreId].length; i++) {
            queue[tail++] = coreChildren[coreId][i];
        }
        
        // BFS traversal
        while (head < tail && count < coreCounter) {
            uint256 current = queue[head++];
            descendants[count++] = current;
            
            for (uint256 i = 0; i < coreChildren[current].length; i++) {
                queue[tail++] = coreChildren[current][i];
            }
        }
        
        // Trim array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = descendants[i];
        }
        return result;
    }
    
    /**
     * @notice Emergency shutdown - poison the reaction
     * @dev Stops all fission activity for a core
     */
    function poisonCore(uint256 coreId) external {
        FissionCore storage core = fissionCores[coreId];
        core.isCritical = false;
        core.energyLevel = 0;
        core.neutronCount = 0;
        
        // Deactivate all child cores
        for (uint256 i = 0; i < coreChildren[coreId].length; i++) {
            FissionCore storage child = fissionCores[coreChildren[coreId][i]];
            child.isCritical = false;
            child.energyLevel = 0;
        }
    }
    
    // Internal helpers
    
    function _replicateNode(uint256 nodeId, uint256 generation) internal {
        ExponentialNode storage node = expNodes[nodeId];
        
        if (generation >= MAX_GENERATIONS) return;
        if (node.spawnCount >= node.maxSpawns) return;
        
        uint256 spawnCount = node.replicationFactor;
        if (node.spawnCount + spawnCount > node.maxSpawns) {
            spawnCount = node.maxSpawns - node.spawnCount;
        }
        
        for (uint256 i = 0; i < spawnCount; i++) {
            uint256 childId = _spawnExponentialNode(
                nodeId,
                node.depth + 1,
                node.stateHash,
                generation + 1
            );
            node.spawnCount++;
            
            // Recursively replicate children
            _replicateNode(childId, generation + 1);
        }
    }
}
