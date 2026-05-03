// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ConnectionMatrix
 * @notice File interlinking system - connects all inception modules
 * @dev Creates a web of interconnected states across all systems
 */

struct MatrixNode {
    bytes32 nodeId;
    address contractAddress;
    bytes4 functionSelector;
    bytes32 stateHash;
    uint256 timestamp;
    uint256 weight;
    bool isActive;
    bytes32[] connections;      // Connected nodes
    bytes32[] dependencies;     // Must resolve first
}

struct Link {
    bytes32 linkId;
    bytes32 sourceNode;
    bytes32 targetNode;
    uint256 strength;           // Connection weight
    uint256 linkType;           // 1=Data, 2=Control, 3=Fission, 4=Dream
    bool isBidirectional;
    uint256 createdAt;
    bool isActive;
}

struct FlowChannel {
    uint256 channelId;
    bytes32[] path;             // Sequence of nodes
    uint256 bandwidth;          // Data throughput capacity
    uint256 latency;            // Delay in propagation
    bool isOpen;
    uint256 packetCount;
    bytes32 lastPacket;
}

struct Resonance {
    bytes32 resonanceId;
    bytes32[] participatingNodes;
    uint256 frequency;          // Sync frequency
    uint256 amplitude;          // Signal strength
    uint256 phase;              // Timing offset
    bool isHarmonic;
    uint256 lastPulse;
}

contract ConnectionMatrix {
    
    mapping(bytes32 => MatrixNode) public nodes;
    mapping(bytes32 => Link) public links;
    mapping(uint256 => FlowChannel) public channels;
    mapping(bytes32 => Resonance) public resonances;
    
    bytes32[] public allNodes;
    bytes32[] public allLinks;
    uint256 public channelCounter;
    uint256 public resonanceCounter;
    
    // System registries
    mapping(address => bytes32[]) public contractNodes;
    mapping(uint256 => bytes32[]) public levelNodes;
    
    // Propagation tracking
    mapping(bytes32 => uint256) public propagationDepth;
    mapping(bytes32 => bool) public visited;
    
    event NodeRegistered(bytes32 indexed nodeId, address contractAddr, bytes4 selector);
    event LinkEstablished(bytes32 indexed linkId, bytes32 source, bytes32 target, uint256 strength);
    event ChannelOpened(uint256 indexed channelId, bytes32[] path);
    event ResonanceDetected(bytes32 indexed resonanceId, bytes32[] nodes);
    event DataPropagated(bytes32 indexed source, bytes32[] path, uint256 depth);
    event MatrixCollapsed(bytes32 indexed trigger, uint256 nodesAffected);
    event HarmonicAchieved(bytes32 indexed resonanceId, uint256 frequency);
    
    /**
     * @notice Register a new node in the matrix
     * @dev Connects a contract function as a matrix node
     */
    function registerNode(
        address contractAddr,
        bytes4 functionSelector,
        bytes32 stateHash,
        uint256 weight,
        bytes32[] calldata dependencies
    ) external returns (bytes32 nodeId) {
        nodeId = keccak256(abi.encodePacked(
            contractAddr,
            functionSelector,
            block.timestamp,
            allNodes.length
        ));
        
        MatrixNode storage node = nodes[nodeId];
        node.nodeId = nodeId;
        node.contractAddress = contractAddr;
        node.functionSelector = functionSelector;
        node.stateHash = stateHash;
        node.timestamp = block.timestamp;
        node.weight = weight;
        node.isActive = true;
        node.dependencies = dependencies;
        
        allNodes.push(nodeId);
        contractNodes[contractAddr].push(nodeId);
        
        emit NodeRegistered(nodeId, contractAddr, functionSelector);
        
        // Auto-connect to dependencies
        for (uint256 i = 0; i < dependencies.length; i++) {
            if (nodes[dependencies[i]].isActive) {
                _createLink(dependencies[i], nodeId, 100, 2, true); // Control link
            }
        }
        
        return nodeId;
    }
    
    /**
     * @notice Create a link between nodes
     * @dev Establishes connection with type and strength
     */
    function createLink(
        bytes32 sourceNode,
        bytes32 targetNode,
        uint256 strength,
        uint256 linkType,
        bool bidirectional
    ) external returns (bytes32 linkId) {
        require(nodes[sourceNode].isActive, "MATRIX: Source not active");
        require(nodes[targetNode].isActive, "MATRIX: Target not active");
        
        linkId = keccak256(abi.encodePacked(
            sourceNode,
            targetNode,
            block.timestamp
        ));
        
        links[linkId] = Link({
            linkId: linkId,
            sourceNode: sourceNode,
            targetNode: targetNode,
            strength: strength,
            linkType: linkType,
            isBidirectional: bidirectional,
            createdAt: block.timestamp,
            isActive: true
        });
        
        allLinks.push(linkId);
        
        // Update node connections
        nodes[sourceNode].connections.push(targetNode);
        if (bidirectional) {
            nodes[targetNode].connections.push(sourceNode);
        }
        
        emit LinkEstablished(linkId, sourceNode, targetNode, strength);
        
        return linkId;
    }
    
    /**
     * @notice Open a flow channel through multiple nodes
     * @dev Creates data pathway for propagation
     */
    function openChannel(bytes32[] calldata path) external returns (uint256 channelId) {
        require(path.length > 1, "MATRIX: Path needs at least 2 nodes");
        
        // Validate all nodes exist and are connected
        for (uint256 i = 0; i < path.length - 1; i++) {
            require(nodes[path[i]].isActive, "MATRIX: Node not active");
            require(_areConnected(path[i], path[i + 1]), "MATRIX: Nodes not connected");
        }
        
        channelId = ++channelCounter;
        
        // Calculate bandwidth (minimum of all link strengths in path)
        uint256 minBandwidth = type(uint256).max;
        uint256 totalLatency = 0;
        
        for (uint256 i = 0; i < path.length - 1; i++) {
            bytes32 linkId = _getLinkId(path[i], path[i + 1]);
            if (links[linkId].strength < minBandwidth) {
                minBandwidth = links[linkId].strength;
            }
            totalLatency += propagationDepth[path[i]];
        }
        
        channels[channelId] = FlowChannel({
            channelId: channelId,
            path: path,
            bandwidth: minBandwidth,
            latency: totalLatency,
            isOpen: true,
            packetCount: 0,
            lastPacket: bytes32(0)
        });
        
        emit ChannelOpened(channelId, path);
        
        return channelId;
    }
    
    /**
     * @notice Propagate data through the matrix
     * @dev Sends signal through connected nodes with exponential fan-out
     */
    function propagate(bytes32 sourceNode, bytes calldata data) external returns (uint256 nodesReached) {
        require(nodes[sourceNode].isActive, "MATRIX: Source not active");
        
        // BFS with depth limiting
        bytes32[] memory queue = new bytes32[](allNodes.length);
        uint256 head = 0;
        uint256 tail = 0;
        
        // Clear visited
        for (uint256 i = 0; i < allNodes.length; i++) {
            visited[allNodes[i]] = false;
        }
        
        queue[tail++] = sourceNode;
        visited[sourceNode] = true;
        propagationDepth[sourceNode] = 0;
        nodesReached = 1;
        
        bytes32[] memory path = new bytes32[](allNodes.length);
        uint256 pathIdx = 0;
        path[pathIdx++] = sourceNode;
        
        while (head < tail && nodesReached < 100) {
            bytes32 current = queue[head++];
            MatrixNode storage node = nodes[current];
            
            // Check all connections
            for (uint256 i = 0; i < node.connections.length; i++) {
                bytes32 neighbor = node.connections[i];
                
                if (!visited[neighbor] && nodes[neighbor].isActive) {
                    // Check link strength
                    bytes32 linkId = _getLinkId(current, neighbor);
                    if (links[linkId].strength > 50) { // Minimum strength threshold
                        visited[neighbor] = true;
                        propagationDepth[neighbor] = propagationDepth[current] + 1;
                        queue[tail++] = neighbor;
                        nodesReached++;
                        path[pathIdx++] = neighbor;
                    }
                }
            }
        }
        
        // Trim path
        bytes32[] memory finalPath = new bytes32[](nodesReached);
        for (uint256 i = 0; i < nodesReached; i++) {
            finalPath[i] = path[i];
        }
        
        emit DataPropagated(sourceNode, finalPath, nodesReached);
        
        // Check for resonance patterns
        _detectResonance(sourceNode, nodesReached);
        
        return nodesReached;
    }
    
    /**
     * @notice Create fission cascade through matrix
     * @dev Triggers nuclear fission-style expansion across connections
     */
    function triggerCascade(bytes32 seedNode, uint256 depth) external returns (uint256 totalTriggers) {
        require(nodes[seedNode].isActive, "MATRIX: Seed not active");
        
        totalTriggers = 1; // Seed
        bytes32[] memory currentLevel = new bytes32[](1);
        currentLevel[0] = seedNode;
        
        for (uint256 d = 0; d < depth && totalTriggers < 100; d++) {
            uint256 levelSize = currentLevel.length;
            bytes32[] memory nextLevel = new bytes32[](levelSize * 2);
            uint256 nextIdx = 0;
            
            for (uint256 i = 0; i < levelSize; i++) {
                MatrixNode storage node = nodes[currentLevel[i]];
                
                for (uint256 j = 0; j < node.connections.length && nextIdx < nextLevel.length; j++) {
                    bytes32 neighbor = node.connections[j];
                    
                    // Fission multiplier - each node can trigger multiple children
                    uint256 fissionCount = _getFissionMultiplier(node.weight);
                    
                    for (uint256 k = 0; k < fissionCount && nextIdx < nextLevel.length; k++) {
                        if (nodes[neighbor].isActive) {
                            nextLevel[nextIdx++] = neighbor;
                            totalTriggers++;
                        }
                    }
                }
            }
            
            currentLevel = nextLevel;
        }
        
        emit MatrixCollapsed(seedNode, totalTriggers);
    }
    
    /**
     * @notice Synchronize nodes to achieve harmonic resonance
     * @dev Creates stable oscillation pattern across nodes
     */
    function achieveHarmony(bytes32[] calldata nodeList, uint256 targetFrequency) 
        external 
        returns (bytes32 resonanceId) 
    {
        require(nodeList.length >= 2, "MATRIX: Need at least 2 nodes");
        
        // Verify all nodes active
        for (uint256 i = 0; i < nodeList.length; i++) {
            require(nodes[nodeList[i]].isActive, "MATRIX: Node not active");
        }
        
        resonanceId = keccak256(abi.encodePacked(nodeList, targetFrequency, block.timestamp));
        
        uint256 avgAmplitude = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < nodeList.length; i++) {
            avgAmplitude += nodes[nodeList[i]].weight;
            totalWeight += nodes[nodeList[i]].weight;
        }
        
        avgAmplitude = avgAmplitude / nodeList.length;
        
        resonances[resonanceId] = Resonance({
            resonanceId: resonanceId,
            participatingNodes: nodeList,
            frequency: targetFrequency,
            amplitude: avgAmplitude,
            phase: 0,
            isHarmonic: true,
            lastPulse: block.timestamp
        });
        
        resonanceCounter++;
        
        emit HarmonicAchieved(resonanceId, targetFrequency);
        emit ResonanceDetected(resonanceId, nodeList);
        
        return resonanceId;
    }
    
    /**
     * @notice Pulse a resonance to propagate signal
     * @dev Sends harmonic pulse through all participating nodes
     */
    function pulseResonance(bytes32 resonanceId) external {
        Resonance storage res = resonances[resonanceId];
        require(res.isHarmonic, "MATRIX: Not harmonic");
        
        // Update phase
        res.phase = (res.phase + 1) % 360;
        res.lastPulse = block.timestamp;
        
        // Pulse through all nodes
        for (uint256 i = 0; i < res.participatingNodes.length; i++) {
            bytes32 nodeId = res.participatingNodes[i];
            
            // Update node state with resonance
            nodes[nodeId].stateHash = keccak256(abi.encodePacked(
                nodes[nodeId].stateHash,
                resonanceId,
                res.phase
            ));
            nodes[nodeId].timestamp = block.timestamp;
        }
    }
    
    /**
     * @notice Get node network subgraph
     * @dev Returns all nodes connected to a given node within depth
     */
    function getNetworkSubgraph(bytes32 centerNode, uint256 maxDepth) 
        external 
        view 
        returns (
            bytes32[] memory subgraphNodes,
            bytes32[] memory subgraphLinks
        ) 
    {
        require(nodes[centerNode].isActive, "MATRIX: Center not active");
        
        // BFS to find all nodes within depth
        bytes32[] memory foundNodes = new bytes32[](allNodes.length);
        bytes32[] memory foundLinks = new bytes32[](allLinks.length);
        uint256 nodeCount = 0;
        uint256 linkCount = 0;
        
        mapping(bytes32 => bool) memory localVisited;
        mapping(bytes32 => uint256) memory localDepth;
        
        bytes32[] memory queue = new bytes32[](allNodes.length);
        uint256 head = 0;
        uint256 tail = 0;
        
        queue[tail++] = centerNode;
        localVisited[centerNode] = true;
        localDepth[centerNode] = 0;
        foundNodes[nodeCount++] = centerNode;
        
        while (head < tail && nodeCount < allNodes.length) {
            bytes32 current = queue[head++];
            MatrixNode storage node = nodes[current];
            
            if (localDepth[current] >= maxDepth) continue;
            
            for (uint256 i = 0; i < node.connections.length; i++) {
                bytes32 neighbor = node.connections[i];
                
                if (!localVisited[neighbor] && nodes[neighbor].isActive) {
                    localVisited[neighbor] = true;
                    localDepth[neighbor] = localDepth[current] + 1;
                    queue[tail++] = neighbor;
                    foundNodes[nodeCount++] = neighbor;
                    
                    // Add link
                    bytes32 linkId = _getLinkId(current, neighbor);
                    if (links[linkId].isActive) {
                        foundLinks[linkCount++] = linkId;
                    }
                }
            }
        }
        
        // Trim arrays
        subgraphNodes = new bytes32[](nodeCount);
        subgraphLinks = new bytes32[](linkCount);
        
        for (uint256 i = 0; i < nodeCount; i++) {
            subgraphNodes[i] = foundNodes[i];
        }
        for (uint256 i = 0; i < linkCount; i++) {
            subgraphLinks[i] = foundLinks[i];
        }
    }
    
    /**
     * @notice Get shortest path between nodes
     * @dev Dijkstra's algorithm implementation
     */
    function getShortestPath(bytes32 start, bytes32 end) 
        external 
        view 
        returns (bytes32[] memory path, uint256 totalWeight) 
    {
        require(nodes[start].isActive && nodes[end].isActive, "MATRIX: Nodes not active");
        
        // Simplified BFS for shortest path (unweighted)
        mapping(bytes32 => bool) memory visited;
        mapping(bytes32 => bytes32) memory parent;
        
        bytes32[] memory queue = new bytes32[](allNodes.length);
        uint256 head = 0;
        uint256 tail = 0;
        
        queue[tail++] = start;
        visited[start] = true;
        parent[start] = bytes32(0);
        
        bool found = false;
        
        while (head < tail && !found) {
            bytes32 current = queue[head++];
            MatrixNode storage node = nodes[current];
            
            for (uint256 i = 0; i < node.connections.length; i++) {
                bytes32 neighbor = node.connections[i];
                
                if (!visited[neighbor] && nodes[neighbor].isActive) {
                    visited[neighbor] = true;
                    parent[neighbor] = current;
                    queue[tail++] = neighbor;
                    
                    if (neighbor == end) {
                        found = true;
                        break;
                    }
                }
            }
        }
        
        require(found, "MATRIX: No path found");
        
        // Reconstruct path
        uint256 pathLength = 0;
        bytes32 current = end;
        while (current != bytes32(0)) {
            pathLength++;
            current = parent[current];
        }
        
        path = new bytes32[](pathLength);
        current = end;
        for (uint256 i = pathLength; i > 0; i--) {
            path[i - 1] = current;
            totalWeight += nodes[current].weight;
            current = parent[current];
        }
    }
    
    /**
     * @notice Get all connections for a node
     */
    function getNodeConnections(bytes32 nodeId) external view returns (bytes32[] memory) {
        return nodes[nodeId].connections;
    }
    
    /**
     * @notice Get matrix statistics
     */
    function getMatrixStats() external view returns (
        uint256 totalNodes,
        uint256 totalLinks,
        uint256 totalChannels,
        uint256 totalResonances,
        uint256 averageConnectivity
    ) {
        totalNodes = allNodes.length;
        totalLinks = allLinks.length;
        totalChannels = channelCounter;
        totalResonances = resonanceCounter;
        
        if (totalNodes > 0) {
            uint256 totalConnections = 0;
            for (uint256 i = 0; i < allNodes.length; i++) {
                totalConnections += nodes[allNodes[i]].connections.length;
            }
            averageConnectivity = totalConnections / totalNodes;
        }
    }
    
    // Internal helpers
    
    function _areConnected(bytes32 a, bytes32 b) internal view returns (bool) {
        for (uint256 i = 0; i < nodes[a].connections.length; i++) {
            if (nodes[a].connections[i] == b) return true;
        }
        return false;
    }
    
    function _getLinkId(bytes32 source, bytes32 target) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(source, target));
    }
    
    function _getFissionMultiplier(uint256 weight) internal pure returns (uint256) {
        if (weight > 1000) return 4;
        if (weight > 500) return 3;
        if (weight > 100) return 2;
        return 1;
    }
    
    function _detectResonance(bytes32 source, uint256 depth) internal {
        // Check if propagation creates cyclic pattern
        if (depth > 5) {
            // Potential resonance detected
            bytes32[] memory resNodes = new bytes32[](depth);
            for (uint256 i = 0; i < depth && i < allNodes.length; i++) {
                if (visited[allNodes[i]]) {
                    resNodes[i] = allNodes[i];
                }
            }
            
            emit ResonanceDetected(keccak256(abi.encodePacked(source, block.timestamp)), resNodes);
        }
    }
    
    function _createLink(
        bytes32 source,
        bytes32 target,
        uint256 strength,
        uint256 linkType,
        bool bidirectional
    ) internal returns (bytes32 linkId) {
        linkId = keccak256(abi.encodePacked(source, target, block.timestamp));
        
        links[linkId] = Link({
            linkId: linkId,
            sourceNode: source,
            targetNode: target,
            strength: strength,
            linkType: linkType,
            isBidirectional: bidirectional,
            createdAt: block.timestamp,
            isActive: true
        });
        
        allLinks.push(linkId);
        nodes[source].connections.push(target);
        if (bidirectional) {
            nodes[target].connections.push(source);
        }
    }
}
