// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./core/InceptionMemory.sol";
import "./engine/AtomicBlonde.sol";
import "./fission/NuclearFission.sol";
import "./weaver/DreamWeaver.sol";
import "./matrix/ConnectionMatrix.sol";

/**
 * @title InceptionOrchestrator
 * @notice Master controller for the Inception Memory Framework
 * @dev Integrates all modules with TheBaseTree green credit system
 */

contract InceptionOrchestrator {
    
    InceptionMemory public inceptionMemory;
    AtomicBlonde public atomicBlonde;
    NuclearFission public nuclearFission;
    DreamWeaver public dreamWeaver;
    ConnectionMatrix public connectionMatrix;
    
    address public thebasetree;
    address public admin;
    
    struct InceptionSession {
        uint256 sessionId;
        address initiator;
        uint256 dreamLevel;
        uint256 fissionCore;
        uint256 executionContext;
        bytes32 targetIdea;
        bool isActive;
        uint256 inceptionTime;
        uint256 extractionTime;
    }
    
    mapping(uint256 => InceptionSession) public sessions;
    mapping(address => uint256[]) public userSessions;
    uint256 public sessionCounter;
    
    // TheBaseTree integration
    mapping(bytes32 => uint256) public creditToDreamLevel;
    mapping(uint256 => bytes32[]) public levelCredits;
    
    event InceptionLaunched(
        uint256 indexed sessionId,
        address indexed initiator,
        uint256 dreamLevel,
        bytes32 targetIdea
    );
    event CreditDreamified(bytes32 indexed creditId, uint256 indexed dreamLevel);
    event FissionCreditCreated(uint256 indexed coreId, bytes32 indexed creditHash);
    event ExtractionSuccessful(uint256 indexed sessionId, bytes32 manifestedIdea);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "ORCHESTRATOR: Not admin");
        _;
    }
    
    constructor(
        address _inceptionMemory,
        address _atomicBlonde,
        address _nuclearFission,
        address _dreamWeaver,
        address _connectionMatrix,
        address _thebasetree
    ) {
        inceptionMemory = InceptionMemory(_inceptionMemory);
        atomicBlonde = AtomicBlonde(_atomicBlonde);
        nuclearFission = NuclearFission(_nuclearFission);
        dreamWeaver = DreamWeaver(_dreamWeaver);
        connectionMatrix = ConnectionMatrix(_connectionMatrix);
        thebasetree = _thebasetree;
        admin = msg.sender;
    }
    
    /**
     * @notice Launch a complete inception session
     * @dev Spawns all subsystems for an idea implantation
     */
    function launchInception(
        bytes32 targetIdea,
        uint256 requiredDepth,
        uint256 fissionEnergy
    ) external returns (uint256 sessionId) {
        sessionId = ++sessionCounter;
        
        // 1. Create dream level
        uint256 dreamLevel = inceptionMemory.inceptDreamLevel(0);
        
        // 2. Initiate fission core
        uint256 fissionCore = nuclearFission.initiateFissionCore(
            targetIdea,
            fissionEnergy,
            1 days
        );
        
        // 3. Architect execution plan
        uint256 planId = dreamWeaver.architectPlan(targetIdea, requiredDepth, requiredDepth);
        
        // 4. Begin execution
        uint256 contextId = dreamWeaver.beginExecution(planId);
        
        // 5. Atomize the target idea
        bytes32 atomicState = atomicBlonde.atomizeState(
            abi.encodePacked(targetIdea),
            atomicBlonde.ATOMIC_PRECISION(),
            true // It's a planted idea
        );
        
        // 6. Plant deception at atomic level
        atomicBlonde.plantDeception(
            atomicState,
            abi.encodePacked("Green Credit Expansion via Inception"),
            requiredDepth,
            1 hours
        );
        
        // 7. Register nodes in connection matrix
        bytes32 dreamNode = connectionMatrix.registerNode(
            address(inceptionMemory),
            InceptionMemory.inceptDreamLevel.selector,
            bytes32(dreamLevel),
            100,
            new bytes32[](0)
        );
        
        bytes32 fissionNode = connectionMatrix.registerNode(
            address(nuclearFission),
            NuclearFission.initiateFissionCore.selector,
            bytes32(fissionCore),
            200,
            new bytes32[](0)
        );
        
        // Link the nodes
        connectionMatrix.createLink(dreamNode, fissionNode, 150, 3, true);
        
        // 8. Store session
        sessions[sessionId] = InceptionSession({
            sessionId: sessionId,
            initiator: msg.sender,
            dreamLevel: dreamLevel,
            fissionCore: fissionCore,
            executionContext: contextId,
            targetIdea: targetIdea,
            isActive: true,
            inceptionTime: block.timestamp,
            extractionTime: 0
        });
        
        userSessions[msg.sender].push(sessionId);
        
        emit InceptionLaunched(sessionId, msg.sender, dreamLevel, targetIdea);
        
        return sessionId;
    }
    
    /**
     * @notice Dreamify a green credit
     * @dev Puts a credit into the inception framework for exponential growth
     */
    function dreamifyCredit(
        bytes32 creditId,
        uint256 dreamLevel
    ) external returns (bool) {
        // Verify credit exists in TheBaseTree (would need interface)
        
        creditToDreamLevel[creditId] = dreamLevel;
        levelCredits[dreamLevel].push(creditId);
        
        // Plant memory of this credit in the dream
        bytes32 fragmentId = inceptionMemory.implantMemory(
            dreamLevel,
            abi.encodePacked(creditId),
            1000, // High weight
            true  // Anchor it
        );
        
        // Atomize the credit state
        atomicBlonde.atomizeState(
            abi.encodePacked(creditId, dreamLevel),
            atomicBlonde.ATOMIC_PRECISION(),
            false // Not deceptive, it's real
        );
        
        emit CreditDreamified(creditId, dreamLevel);
        
        return true;
    }
    
    /**
     * @notice Trigger fission on a dreamified credit
     * @dev Splits credit into exponentially growing derivative credits
     */
    function triggerCreditFission(
        uint256 sessionId,
        uint256 splitCount
    ) external returns (uint256[] memory childCredits) {
        InceptionSession storage session = sessions[sessionId];
        require(session.isActive, "ORCHESTRATOR: Session not active");
        
        // Split the fission core
        nuclearFission.splitCore(session.fissionCore, splitCount);
        
        // Get descendants
        uint256[] memory descendants = nuclearFission.getCoreDescendants(session.fissionCore);
        
        // Create derivative credits for each descendant
        childCredits = new bytes32[](descendants.length);
        for (uint256 i = 0; i < descendants.length; i++) {
            bytes32 childCredit = keccak256(abi.encodePacked(
                session.targetIdea,
                descendants[i],
                block.timestamp
            ));
            childCredits[i] = childCredit;
            
            emit FissionCreditCreated(descendants[i], childCredit);
        }
        
        return childCredits;
    }
    
    /**
     * @notice Propagate credit through connection matrix
     * @dev Uses matrix propagation for network-wide distribution
     */
    function propagateCredit(bytes32 creditId) external returns (uint256 nodesReached) {
        uint256 dreamLevel = creditToDreamLevel[creditId];
        require(dreamLevel > 0, "ORCHESTRATOR: Credit not dreamified");
        
        // Register credit as matrix node
        bytes32 creditNode = connectionMatrix.registerNode(
            address(this),
            this.propagateCredit.selector,
            creditId,
            500,
            new bytes32[](0)
        );
        
        // Propagate
        nodesReached = connectionMatrix.propagate(creditNode, abi.encodePacked(creditId));
        
        return nodesReached;
    }
    
    /**
     * @notice Execute kick and extraction
     * @dev Completes the inception session and returns to reality
     */
    function executeExtraction(uint256 sessionId) external {
        InceptionSession storage session = sessions[sessionId];
        require(session.isActive, "ORCHESTRATOR: Session not active");
        require(
            msg.sender == session.initiator || msg.sender == admin,
            "ORCHESTRATOR: Not authorized"
        );
        
        // Initiate kick through dream weaver
        dreamWeaver.emergencyKick(session.executionContext);
        
        // Collapse dream levels
        inceptionMemory.initiateKick(session.dreamLevel, 100);
        
        // Poison fission core
        nuclearFission.poisonCore(session.fissionCore);
        
        // Complete session
        session.isActive = false;
        session.extractionTime = block.timestamp;
        
        emit ExtractionSuccessful(sessionId, session.targetIdea);
    }
    
    /**
     * @notice Get session status with full metrics
     */
    function getSessionMetrics(uint256 sessionId) external view returns (
        InceptionSession memory session,
        uint256 activeLevels,
        uint256 fissionNodes,
        uint256 planProgress,
        uint256 matrixConnections
    ) {
        session = sessions[sessionId];
        
        activeLevels = inceptionMemory.getActiveLevels().length;
        fissionNodes = nuclearFission.totalFissions();
        
        (, , planProgress, ) = dreamWeaver.getPlanProgress(
            sessions[sessionId].executionContext
        );
        
        (, , , , matrixConnections) = connectionMatrix.getMatrixStats();
    }
    
    /**
     * @notice Cascade fission through entire credit portfolio
     * @dev Triggers exponential growth across all dreamified credits
     */
    function cascadePortfolio(address user) external returns (uint256 totalTriggers) {
        uint256[] storage userSesh = userSessions[user];
        
        for (uint256 i = 0; i < userSesh.length; i++) {
            InceptionSession storage session = sessions[userSesh[i]];
            if (session.isActive) {
                // Trigger fission for each active session
                nuclearFission.feedCore(session.fissionCore, 500);
                
                // Cascade through matrix
                bytes32 seedNode = keccak256(abi.encodePacked(session.fissionCore));
                uint256 triggers = connectionMatrix.triggerCascade(seedNode, 5);
                totalTriggers += triggers;
            }
        }
    }
    
    /**
     * @notice Achieve harmonic resonance across all systems
     * @dev Synchronizes all active sessions to a common frequency
     */
    function achieveSystemHarmony(uint256 targetFrequency) external returns (bytes32 resonanceId) {
        uint256 activeCount = 0;
        bytes32[] memory activeNodes = new bytes32[](sessionCounter);
        
        // Collect all active session nodes
        for (uint256 i = 1; i <= sessionCounter; i++) {
            if (sessions[i].isActive) {
                activeNodes[activeCount++] = bytes32(sessions[i].sessionId);
            }
        }
        
        require(activeCount > 1, "ORCHESTRATOR: Need multiple active sessions");
        
        // Trim array
        bytes32[] memory finalNodes = new bytes32[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            finalNodes[i] = activeNodes[i];
        }
        
        // Achieve harmony
        resonanceId = connectionMatrix.achieveHarmony(finalNodes, targetFrequency);
        
        return resonanceId;
    }
    
    /**
     * @notice Pulse system resonance
     * @dev Propagates harmonic signal through all connected nodes
     */
    function pulseSystem(bytes32 resonanceId) external {
        connectionMatrix.pulseResonance(resonanceId);
    }
    
    /**
     * @notice Get user's inception portfolio
     */
    function getUserPortfolio(address user) external view returns (
        uint256[] memory activeSessions,
        uint256 totalDreamLevels,
        uint256 totalFissionCores,
        uint256 totalCredits
    ) {
        uint256[] storage allSessions = userSessions[user];
        
        // Count active
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allSessions.length; i++) {
            if (sessions[allSessions[i]].isActive) {
                activeCount++;
            }
        }
        
        activeSessions = new uint256[](activeCount);
        uint256 idx = 0;
        
        for (uint256 i = 0; i < allSessions.length; i++) {
            InceptionSession storage session = sessions[allSessions[i]];
            if (session.isActive) {
                activeSessions[idx++] = allSessions[i];
                totalDreamLevels++;
                totalFissionCores++;
                totalCredits += levelCredits[session.dreamLevel].length;
            }
        }
    }
    
    function setTheBaseTree(address _thebasetree) external onlyAdmin {
        thebasetree = _thebasetree;
    }
    
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }
}
