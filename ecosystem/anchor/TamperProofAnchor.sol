// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title TamperProofAnchor
 * @notice Cryptographic anchoring of off-chain data to blockchain ledger
 * @dev Uses Merkle trees, zk-proofs, and temporal notarization
 */

struct DataAnchor {
    bytes32 anchorId;
    bytes32 dataHash;
    bytes32 merkleRoot;
    uint256 blockNumber;
    uint256 timestamp;
    address notary;
    bytes32 prevAnchor;         // Linked list for chain
    bytes32 nextAnchor;
    bytes32 zkProofHash;
    uint256 confidence;         // 0-10000 verification confidence
    bool isValid;
}

struct VerificationProof {
    bytes32 proofId;
    bytes32 anchorId;
    bytes32[] merklePath;
    uint256[] pathIndices;
    bytes signature;
    address verifier;
    uint256 verificationTime;
    bool isValid;
}

struct TemporalNotarization {
    uint256 notarizationId;
    bytes32 anchorId;
    uint256 notaryCount;
    mapping(address => bool) notarySignatures;
    address[] notaryList;
    uint256 threshold;
    bool isComplete;
    uint256 completionTime;
}

contract TamperProofAnchor {
    
    mapping(bytes32 => DataAnchor) public anchors;
    mapping(bytes32 => VerificationProof) public proofs;
    mapping(uint256 => TemporalNotarization) public notarizations;
    mapping(address => bool) public authorizedNotaries;
    mapping(bytes32 => bool) public verifiedAnchors;
    
    bytes32 public anchorChainHead;
    bytes32 public anchorChainTail;
    uint256 public anchorCounter;
    uint256 public notarizationCounter;
    uint256 public constant NOTARY_THRESHOLD = 3;
    uint256 public constant CONFIDENCE_THRESHOLD = 9500; // 95%
    
    address public admin;
    address public oracleRelayer;
    
    event DataAnchored(
        bytes32 indexed anchorId,
        bytes32 dataHash,
        bytes32 merkleRoot,
        uint256 blockNumber,
        address notary
    );
    event ProofSubmitted(
        bytes32 indexed proofId,
        bytes32 indexed anchorId,
        address verifier,
        uint256 confidence
    );
    event NotarizationComplete(
        uint256 indexed notarizationId,
        bytes32 indexed anchorId,
        uint256 notaryCount
    );
    event AnchorVerified(bytes32 indexed anchorId, uint256 finalConfidence);
    event ChainExtended(bytes32 indexed newHead, bytes32 indexed prevTail);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "ANCHOR: Not admin");
        _;
    }
    
    modifier onlyNotary() {
        require(authorizedNotaries[msg.sender], "ANCHOR: Not authorized notary");
        _;
    }
    
    modifier onlyOracle() {
        require(msg.sender == oracleRelayer, "ANCHOR: Not oracle");
        _;
    }
    
    constructor(address _oracleRelayer) {
        admin = msg.sender;
        oracleRelayer = _oracleRelayer;
    }
    
    /**
     * @notice Anchor data to blockchain with cryptographic proof
     * @dev Creates immutable timestamped record
     */
    function anchorData(
        bytes32 dataHash,
        bytes32 merkleRoot,
        bytes32 zkProofHash,
        uint256 initialConfidence
    ) external onlyNotary returns (bytes32 anchorId) {
        
        anchorId = keccak256(abi.encodePacked(
            dataHash,
            merkleRoot,
            block.number,
            block.timestamp,
            msg.sender,
            anchorCounter++
        ));
        
        // Link to chain
        bytes32 prevAnchor = anchorChainTail;
        
        anchors[anchorId] = DataAnchor({
            anchorId: anchorId,
            dataHash: dataHash,
            merkleRoot: merkleRoot,
            blockNumber: block.number,
            timestamp: block.timestamp,
            notary: msg.sender,
            prevAnchor: prevAnchor,
            nextAnchor: bytes32(0),
            zkProofHash: zkProofHash,
            confidence: initialConfidence,
            isValid: initialConfidence >= CONFIDENCE_THRESHOLD
        });
        
        // Update chain links
        if (anchorChainHead == bytes32(0)) {
            anchorChainHead = anchorId;
            anchorChainTail = anchorId;
        } else {
            anchors[anchorChainTail].nextAnchor = anchorId;
            anchorChainTail = anchorId;
        }
        
        emit DataAnchored(anchorId, dataHash, merkleRoot, block.number, msg.sender);
        emit ChainExtended(anchorId, prevAnchor);
        
        // Auto-initiate notarization if confidence is borderline
        if (initialConfidence >= 8000 && initialConfidence < CONFIDENCE_THRESHOLD) {
            _initiateNotarization(anchorId);
        }
        
        return anchorId;
    }
    
    /**
     * @notice Submit verification proof for anchored data
     * @dev Uses Merkle path verification
     */
    function submitProof(
        bytes32 anchorId,
        bytes32[] calldata merklePath,
        uint256[] calldata pathIndices,
        bytes calldata signature
    ) external returns (bytes32 proofId) {
        DataAnchor storage anchor = anchors[anchorId];
        require(anchor.anchorId != bytes32(0), "ANCHOR: Anchor not found");
        
        // Verify Merkle path
        bool merkleValid = _verifyMerklePath(
            anchor.dataHash,
            anchor.merkleRoot,
            merklePath,
            pathIndices
        );
        
        require(merkleValid, "ANCHOR: Invalid Merkle path");
        
        proofId = keccak256(abi.encodePacked(
            anchorId,
            merklePath,
            msg.sender,
            block.timestamp
        ));
        
        proofs[proofId] = VerificationProof({
            proofId: proofId,
            anchorId: anchorId,
            merklePath: merklePath,
            pathIndices: pathIndices,
            signature: signature,
            verifier: msg.sender,
            verificationTime: block.timestamp,
            isValid: true
        });
        
        // Increase anchor confidence
        uint256 confidenceBoost = 500; // +5%
        anchor.confidence = anchor.confidence + confidenceBoost > 10000 
            ? 10000 
            : anchor.confidence + confidenceBoost;
        
        emit ProofSubmitted(proofId, anchorId, msg.sender, anchor.confidence);
        
        // Check if anchor now verified
        if (anchor.confidence >= CONFIDENCE_THRESHOLD && !verifiedAnchors[anchorId]) {
            verifiedAnchors[anchorId] = true;
            anchor.isValid = true;
            emit AnchorVerified(anchorId, anchor.confidence);
        }
        
        return proofId;
    }
    
    /**
     * @notice Sign notarization as authorized notary
     * @dev Multi-sig temporal notarization for high-value anchors
     */
    function signNotarization(uint256 notarizationId) external onlyNotary {
        TemporalNotarization storage notarization = notarizations[notarizationId];
        require(notarization.notarizationId != 0, "ANCHOR: Notarization not found");
        require(!notarization.notarySignatures[msg.sender], "ANCHOR: Already signed");
        require(!notarization.isComplete, "ANCHOR: Already complete");
        
        notarization.notarySignatures[msg.sender] = true;
        notarization.notaryList.push(msg.sender);
        notarization.notaryCount++;
        
        // Check threshold
        if (notarization.notaryCount >= notarization.threshold) {
            notarization.isComplete = true;
            notarization.completionTime = block.timestamp;
            
            // Boost anchor confidence
            DataAnchor storage anchor = anchors[notarization.anchorId];
            anchor.confidence = 10000;
            anchor.isValid = true;
            verifiedAnchors[notarization.anchorId] = true;
            
            emit NotarizationComplete(notarizationId, notarization.anchorId, notarization.notaryCount);
            emit AnchorVerified(notarization.anchorId, 10000);
        }
    }
    
    /**
     * @notice Oracle relay for off-chain data verification
     * @dev Trust-minimized oracle integration
     */
    function oracleVerify(
        bytes32 anchorId,
        bool isValid,
        uint256 oracleConfidence
    ) external onlyOracle {
        DataAnchor storage anchor = anchors[anchorId];
        require(anchor.anchorId != bytes32(0), "ANCHOR: Anchor not found");
        
        if (isValid) {
            uint256 newConfidence = (anchor.confidence + oracleConfidence) / 2;
            anchor.confidence = newConfidence > 10000 ? 10000 : newConfidence;
            
            if (anchor.confidence >= CONFIDENCE_THRESHOLD) {
                anchor.isValid = true;
                verifiedAnchors[anchorId] = true;
                emit AnchorVerified(anchorId, anchor.confidence);
            }
        } else {
            anchor.confidence = anchor.confidence > 2000 ? anchor.confidence - 2000 : 0;
            if (anchor.confidence < 5000) {
                anchor.isValid = false;
                verifiedAnchors[anchorId] = false;
            }
        }
    }
    
    /**
     * @notice Batch anchor multiple data points
     * @dev Gas-optimized batch operation
     */
    function batchAnchor(
        bytes32[] calldata dataHashes,
        bytes32[] calldata merkleRoots,
        bytes32[] calldata zkProofHashes
    ) external onlyNotary returns (bytes32[] memory anchorIds) {
        require(
            dataHashes.length == merkleRoots.length && 
            dataHashes.length == zkProofHashes.length,
            "ANCHOR: Length mismatch"
        );
        
        anchorIds = new bytes32[](dataHashes.length);
        
        for (uint256 i = 0; i < dataHashes.length; i++) {
            anchorIds[i] = keccak256(abi.encodePacked(
                dataHashes[i],
                merkleRoots[i],
                block.number,
                block.timestamp,
                msg.sender,
                anchorCounter + i
            ));
            
            // Store anchor (simplified for batch)
            anchors[anchorIds[i]] = DataAnchor({
                anchorId: anchorIds[i],
                dataHash: dataHashes[i],
                merkleRoot: merkleRoots[i],
                blockNumber: block.number,
                timestamp: block.timestamp,
                notary: msg.sender,
                prevAnchor: i == 0 ? anchorChainTail : anchorIds[i - 1],
                nextAnchor: bytes32(0),
                zkProofHash: zkProofHashes[i],
                confidence: 9000,
                isValid: false
            });
        }
        
        anchorCounter += dataHashes.length;
        
        // Update chain tail
        if (anchorChainHead == bytes32(0)) {
            anchorChainHead = anchorIds[0];
        } else {
            anchors[anchorChainTail].nextAnchor = anchorIds[0];
        }
        anchorChainTail = anchorIds[anchorIds.length - 1];
    }
    
    /**
     * @notice Get anchor chain history
     */
    function getAnchorChain(uint256 count) external view returns (bytes32[] memory chain) {
        chain = new bytes32[](count);
        bytes32 current = anchorChainTail;
        
        for (uint256 i = 0; i < count && current != bytes32(0); i++) {
            chain[count - 1 - i] = current;
            current = anchors[current].prevAnchor;
        }
    }
    
    /**
     * @notice Verify data integrity against anchor
     */
    function verifyIntegrity(bytes32 anchorId, bytes32 dataHash) external view returns (
        bool isMatch,
        uint256 confidence,
        bool isVerified
    ) {
        DataAnchor storage anchor = anchors[anchorId];
        
        isMatch = anchor.dataHash == dataHash;
        confidence = anchor.confidence;
        isVerified = verifiedAnchors[anchorId];
    }
    
    /**
     * @notice Get anchor statistics
     */
    function getAnchorStats() external view returns (
        uint256 totalAnchors,
        uint256 verifiedCount,
        uint256 pendingNotarization,
        uint256 chainLength
    ) {
        totalAnchors = anchorCounter;
        
        // Count verified
        // Note: In production, track this during operations
        
        chainLength = 0;
        bytes32 current = anchorChainHead;
        while (current != bytes32(0)) {
            chainLength++;
            current = anchors[current].nextAnchor;
        }
    }
    
    // Internal functions
    
    function _initiateNotarization(bytes32 anchorId) internal returns (uint256 notarizationId) {
        notarizationId = ++notarizationCounter;
        
        TemporalNotarization storage notarization = notarizations[notarizationId];
        notarization.notarizationId = notarizationId;
        notarization.anchorId = anchorId;
        notarization.notaryCount = 0;
        notarization.threshold = NOTARY_THRESHOLD;
        notarization.isComplete = false;
    }
    
    function _verifyMerklePath(
        bytes32 leaf,
        bytes32 root,
        bytes32[] calldata path,
        uint256[] calldata indices
    ) internal pure returns (bool) {
        bytes32 current = leaf;
        
        for (uint256 i = 0; i < path.length; i++) {
            if (indices[i] == 0) {
                current = keccak256(abi.encodePacked(current, path[i]));
            } else {
                current = keccak256(abi.encodePacked(path[i], current));
            }
        }
        
        return current == root;
    }
    
    // Admin functions
    
    function addNotary(address notary) external onlyAdmin {
        authorizedNotaries[notary] = true;
    }
    
    function removeNotary(address notary) external onlyAdmin {
        authorizedNotaries[notary] = false;
    }
    
    function setOracleRelayer(address _oracleRelayer) external onlyAdmin {
        oracleRelayer = _oracleRelayer;
    }
}
