// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CircularGreenEngine
 * @notice Circular economy integration for regenerative credit systems
 * @dev Enables waste-to-credit, recycling rewards, and regenerative loops
 */

struct CircularLoop {
    uint256 loopId;
    string loopType;            // "recycling", "composting", "energy", "water"
    bytes32 inputResource;      // Hash of input (waste, emissions, etc)
    bytes32 outputCredit;       // Generated green credit
    uint256 inputAmount;
    uint256 outputAmount;
    uint256 conversionRate;     // Efficiency of conversion
    uint256 participants;
    uint256 totalProcessed;
    bool isActive;
    uint256 regenerationFactor; // How much it regenerates (1.0+ = regenerative)
}

struct ResourceFlow {
    uint256 flowId;
    uint256 loopId;
    address participant;
    bytes32 resourceHash;       // Proof of resource delivery
    uint256 amount;
    uint256 timestamp;
    uint256 quality;            // Quality score of input
    uint256 rewardEarned;
    bool isVerified;
    address verifier;
}

struct RegenerationPool {
    uint256 poolId;
    uint256 loopId;
    uint256 totalDeposited;
    uint256 totalWithdrawn;
    uint256 regenerationRate;   // APR-style regeneration rate
    mapping(address => uint256) balances;
    mapping(address => uint256) lastHarvest;
    uint256 harvestInterval;
}

struct SymbioticLink {
    uint256 linkId;
    uint256 primaryLoop;
    uint256 secondaryLoop;
    uint256 exchangeRate;       // Primary:Secondary ratio
    uint256 mutualBenefit;      // Combined efficiency gain
    bool isActive;
    uint256 creationTime;
}

contract CircularGreenEngine {
    
    mapping(uint256 => CircularLoop) public loops;
    mapping(uint256 => ResourceFlow) public flows;
    mapping(uint256 => RegenerationPool) public pools;
    mapping(uint256 => SymbioticLink) public symbioticLinks;
    
    uint256 public loopCounter;
    uint256 public flowCounter;
    uint256 public poolCounter;
    uint256 public linkCounter;
    
    // Participant tracking
    mapping(address => uint256[]) public participantFlows;
    mapping(address => uint256) public totalResourcesContributed;
    mapping(address => uint256) public totalCreditsEarned;
    
    // Verifiers
    mapping(address => bool) public authorizedVerifiers;
    mapping(address => mapping(uint256 => bool)) public verifierForLoop;
    
    address public admin;
    address public thebasetree;
    
    // Constants
    uint256 public constant CONVERSION_SCALE = 10000; // For percentages
    uint256 public constant MIN_REGENERATION = 10000; // 1.0x minimum
    uint256 public constant HARVEST_COOLDOWN = 1 days;
    
    // Events
    event LoopCreated(uint256 indexed loopId, string loopType, uint256 regenerationFactor);
    event ResourceFlowed(uint256 indexed flowId, uint256 indexed loopId, address participant, uint256 amount);
    event RewardIssued(uint256 indexed flowId, address participant, uint256 reward);
    event PoolHarvested(uint256 indexed poolId, address participant, uint256 amount);
    event SymbioticLinkCreated(uint256 indexed linkId, uint256 primaryLoop, uint256 secondaryLoop);
    event MutualBenefitRealized(uint256 indexed linkId, uint256 combinedEfficiency);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "CIRCULAR: Not admin");
        _;
    }
    
    modifier onlyVerifier(uint256 loopId) {
        require(
            authorizedVerifiers[msg.sender] && verifierForLoop[msg.sender][loopId],
            "CIRCULAR: Not authorized verifier"
        );
        _;
    }
    
    constructor(address _thebasetree) {
        admin = msg.sender;
        thebasetree = _thebasetree;
    }
    
    /**
     * @notice Create circular loop for resource conversion
     * @param loopType Type of circular process
     * @param conversionRate Efficiency percentage (0-10000)
     * @param regenerationFactor How regenerative (>10000 = positive)
     */
    function createCircularLoop(
        string calldata loopType,
        uint256 conversionRate,
        uint256 regenerationFactor
    ) external onlyAdmin returns (uint256 loopId) {
        loopId = ++loopCounter;
        
        loops[loopId] = CircularLoop({
            loopId: loopId,
            loopType: loopType,
            inputResource: bytes32(0),
            outputCredit: bytes32(0),
            inputAmount: 0,
            outputAmount: 0,
            conversionRate: conversionRate,
            participants: 0,
            totalProcessed: 0,
            isActive: true,
            regenerationFactor: regenerationFactor
        });
        
        // Create associated regeneration pool
        poolCounter++;
        pools[poolCounter] = RegenerationPool({
            poolId: poolCounter,
            loopId: loopId,
            totalDeposited: 0,
            totalWithdrawn: 0,
            regenerationRate: regenerationFactor / 100, // Convert to APR-like rate
            harvestInterval: HARVEST_COOLDOWN
        });
        
        emit LoopCreated(loopId, loopType, regenerationFactor);
        
        return loopId;
    }
    
    /**
     * @notice Submit resource to circular loop
     * @dev Participant contributes waste/resource for conversion
     */
    function submitResource(
        uint256 loopId,
        bytes32 resourceHash,
        uint256 amount,
        uint256 quality
    ) external returns (uint256 flowId) {
        CircularLoop storage loop = loops[loopId];
        require(loop.isActive, "CIRCULAR: Loop not active");
        require(amount > 0, "CIRCULAR: Amount must be > 0");
        require(quality > 0 && quality <= 10000, "CIRCULAR: Invalid quality");
        
        flowId = ++flowCounter;
        
        // Calculate reward based on amount, quality, and conversion rate
        uint256 baseReward = (amount * loop.conversionRate) / CONVERSION_SCALE;
        uint256 qualityBonus = (baseReward * quality) / CONVERSION_SCALE;
        uint256 totalReward = baseReward + (qualityBonus / 10); // 10% quality bonus
        
        flows[flowId] = ResourceFlow({
            flowId: flowId,
            loopId: loopId,
            participant: msg.sender,
            resourceHash: resourceHash,
            amount: amount,
            timestamp: block.timestamp,
            quality: quality,
            rewardEarned: totalReward,
            isVerified: false,
            verifier: address(0)
        });
        
        participantFlows[msg.sender].push(flowId);
        totalResourcesContributed[msg.sender] += amount;
        
        loop.participants++;
        loop.inputAmount += amount;
        
        emit ResourceFlowed(flowId, loopId, msg.sender, amount);
        
        return flowId;
    }
    
    /**
     * @notice Verify resource submission
     * @dev Verifier confirms physical delivery of resource
     */
    function verifyResource(uint256 flowId) external onlyVerifier(flows[flowId].loopId) {
        ResourceFlow storage flow = flows[flowId];
        require(!flow.isVerified, "CIRCULAR: Already verified");
        
        flow.isVerified = true;
        flow.verifier = msg.sender;
        
        CircularLoop storage loop = loops[flow.loopId];
        loop.totalProcessed += flow.amount;
        loop.outputAmount += flow.rewardEarned;
        
        // Update regeneration pool
        RegenerationPool storage pool = pools[flow.loopId];
        pool.totalDeposited += flow.rewardEarned;
        pool.balances[flow.participant] += flow.rewardEarned;
        pool.lastHarvest[flow.participant] = block.timestamp;
        
        totalCreditsEarned[flow.participant] += flow.rewardEarned;
        
        emit RewardIssued(flowId, flow.participant, flow.rewardEarned);
    }
    
    /**
     * @notice Harvest from regeneration pool
     * @dev Time-based harvesting of accumulated regeneration
     */
    function harvest(uint256 poolId) external returns (uint256 harvestAmount) {
        RegenerationPool storage pool = pools[poolId];
        require(pool.poolId != 0, "CIRCULAR: Pool not found");
        
        uint256 balance = pool.balances[msg.sender];
        require(balance > 0, "CIRCULAR: No balance");
        
        uint256 lastHarvestTime = pool.lastHarvest[msg.sender];
        require(
            block.timestamp >= lastHarvestTime + pool.harvestInterval,
            "CIRCULAR: Harvest cooldown"
        );
        
        uint256 timeElapsed = block.timestamp - lastHarvestTime;
        uint256 periods = timeElapsed / pool.harvestInterval;
        
        // Calculate regeneration: balance * rate * periods
        harvestAmount = (balance * pool.regenerationRate * periods) / (CONVERSION_SCALE * 365);
        
        require(harvestAmount > 0, "CIRCULAR: Nothing to harvest");
        
        pool.totalWithdrawn += harvestAmount;
        pool.balances[msg.sender] += harvestAmount; // Add regeneration to balance
        pool.lastHarvest[msg.sender] = block.timestamp;
        
        emit PoolHarvested(poolId, msg.sender, harvestAmount);
        
        return harvestAmount;
    }
    
    /**
     * @notice Create symbiotic link between loops
     * @dev Two loops benefit each other (e.g., composting + agriculture)
     */
    function createSymbioticLink(
        uint256 primaryLoop,
        uint256 secondaryLoop,
        uint256 exchangeRate
    ) external onlyAdmin returns (uint256 linkId) {
        require(loops[primaryLoop].isActive, "CIRCULAR: Primary loop inactive");
        require(loops[secondaryLoop].isActive, "CIRCULAR: Secondary loop inactive");
        
        linkId = ++linkCounter;
        
        // Calculate mutual benefit
        uint256 combinedEfficiency = loops[primaryLoop].conversionRate + 
                                     loops[secondaryLoop].conversionRate;
        uint256 mutualBenefit = (combinedEfficiency * exchangeRate) / CONVERSION_SCALE;
        
        symbioticLinks[linkId] = SymbioticLink({
            linkId: linkId,
            primaryLoop: primaryLoop,
            secondaryLoop: secondaryLoop,
            exchangeRate: exchangeRate,
            mutualBenefit: mutualBenefit,
            isActive: true,
            creationTime: block.timestamp
        });
        
        emit SymbioticLinkCreated(linkId, primaryLoop, secondaryLoop);
        emit MutualBenefitRealized(linkId, mutualBenefit);
        
        return linkId;
    }
    
    /**
     * @notice Trigger symbiotic exchange
     * @dev Resources flow between linked loops
     */
    function exchangeSymbiotic(uint256 linkId, uint256 amount) external {
        SymbioticLink storage link = symbioticLinks[linkId];
        require(link.isActive, "CIRCULAR: Link not active");
        
        CircularLoop storage primary = loops[link.primaryLoop];
        CircularLoop storage secondary = loops[link.secondaryLoop];
        
        uint256 exchangeAmount = (amount * link.exchangeRate) / CONVERSION_SCALE;
        
        // Update both loops
        primary.outputAmount += amount;
        secondary.inputAmount += exchangeAmount;
        
        // Boost both regeneration factors
        primary.regenerationFactor = (primary.regenerationFactor * 101) / 100; // +1%
        secondary.regenerationFactor = (secondary.regenerationFactor * 101) / 100;
    }
    
    /**
     * @notice Get participant circular economy stats
     */
    function getParticipantStats(address participant) external view returns (
        uint256 resourcesContributed,
        uint256 creditsEarned,
        uint256 activeFlows,
        uint256[] memory flowIds
    ) {
        resourcesContributed = totalResourcesContributed[participant];
        creditsEarned = totalCreditsEarned[participant];
        activeFlows = participantFlows[participant].length;
        flowIds = participantFlows[participant];
    }
    
    /**
     * @notice Get loop performance metrics
     */
    function getLoopMetrics(uint256 loopId) external view returns (
        uint256 efficiency,
        uint256 totalInput,
        uint256 totalOutput,
        uint256 participantCount,
        uint256 regenerationScore,
        bool isRegenerative
    ) {
        CircularLoop storage loop = loops[loopId];
        
        efficiency = loop.conversionRate;
        totalInput = loop.inputAmount;
        totalOutput = loop.outputAmount;
        participantCount = loop.participants;
        regenerationScore = loop.regenerationFactor;
        isRegenerative = loop.regenerationFactor > MIN_REGENERATION;
    }
    
    /**
     * @notice Calculate system-wide circularity
     * @dev Overall circular economy health score
     */
    function calculateSystemCircularity() external view returns (
        uint256 totalLoops,
        uint256 regenerativeLoops,
        uint256 totalResources,
        uint256 totalCredits,
        uint256 averageEfficiency,
        uint256 circularityScore
    ) {
        totalLoops = loopCounter;
        
        for (uint256 i = 1; i <= loopCounter; i++) {
            if (loops[i].regenerationFactor > MIN_REGENERATION) {
                regenerativeLoops++;
            }
            totalResources += loops[i].inputAmount;
            totalCredits += loops[i].outputAmount;
            averageEfficiency += loops[i].conversionRate;
        }
        
        if (loopCounter > 0) {
            averageEfficiency = averageEfficiency / loopCounter;
        }
        
        // Circularity score: (regenerative / total) * efficiency * 100
        if (totalLoops > 0) {
            circularityScore = (regenerativeLoops * averageEfficiency * 100) / totalLoops;
        }
    }
    
    /**
     * @notice Batch process multiple flows
     * @dev Gas-efficient batch verification
     */
    function batchVerify(uint256[] calldata flowIds) external {
        for (uint256 i = 0; i < flowIds.length; i++) {
            uint256 loopId = flows[flowIds[i]].loopId;
            if (verifierForLoop[msg.sender][loopId] && !flows[flowIds[i]].isVerified) {
                // Inline verification to save gas
                flows[flowIds[i]].isVerified = true;
                flows[flowIds[i]].verifier = msg.sender;
                
                loops[loopId].totalProcessed += flows[flowIds[i]].amount;
                loops[loopId].outputAmount += flows[flowIds[i]].rewardEarned;
                
                totalCreditsEarned[flows[flowIds[i]].participant] += flows[flowIds[i]].rewardEarned;
                
                emit RewardIssued(flowIds[i], flows[flowIds[i]].participant, flows[flowIds[i]].rewardEarned);
            }
        }
    }
    
    /**
     * @notice Create TheBaseTree credit from circular loop
     * @dev Integration with main credit system
     */
    function mintCircularCredit(
        uint256 loopId,
        uint256 amount,
        string calldata projectName,
        string calldata location
    ) external onlyAdmin returns (bytes32 creditHash) {
        CircularLoop storage loop = loops[loopId];
        require(loop.outputAmount >= amount, "CIRCULAR: Insufficient output");
        
        // Generate credit hash (would integrate with TheBaseTree in production)
        creditHash = keccak256(abi.encodePacked(
            loopId,
            amount,
            projectName,
            block.timestamp
        ));
        
        loop.outputAmount -= amount;
        
        // Emit event for TheBaseTree integration
        emit RewardIssued(0, address(0), amount); // Event re-use for credit minting
    }
    
    /**
     * @notice Get all symbiotic links for a loop
     */
    function getLoopSymbiosis(uint256 loopId) external view returns (uint256[] memory links) {
        uint256 count = 0;
        for (uint256 i = 1; i <= linkCounter; i++) {
            if (symbioticLinks[i].primaryLoop == loopId || 
                symbioticLinks[i].secondaryLoop == loopId) {
                count++;
            }
        }
        
        links = new uint256[](count);
        uint256 idx = 0;
        for (uint256 i = 1; i <= linkCounter; i++) {
            if (symbioticLinks[i].primaryLoop == loopId || 
                symbioticLinks[i].secondaryLoop == loopId) {
                links[idx++] = i;
            }
        }
    }
    
    // Admin functions
    
    function addVerifier(address verifier, uint256 loopId) external onlyAdmin {
        authorizedVerifiers[verifier] = true;
        verifierForLoop[verifier][loopId] = true;
    }
    
    function updateLoopStatus(uint256 loopId, bool isActive) external onlyAdmin {
        loops[loopId].isActive = isActive;
    }
    
    function setTheBaseTree(address _thebasetree) external onlyAdmin {
        thebasetree = _thebasetree;
    }
}
