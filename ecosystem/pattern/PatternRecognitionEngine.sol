// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PatternRecognitionEngine
 * @notice AI-style pattern recognition for credit market analysis
 * @dev Uses historical data, trend analysis, and predictive modeling
 */

struct Pattern {
    bytes32 patternId;
    string patternType;         // "trend", "cycle", "anomaly", "correlation"
    bytes32[] dataPoints;
    uint256 startTime;
    uint256 endTime;
    uint256 confidence;         // 0-10000
    uint256 strength;           // Pattern intensity
    bytes32 parentPattern;      // Hierarchical patterns
    bytes32[] childPatterns;
    bool isActive;
    uint256 detectionCount;
}

struct TrendAnalysis {
    uint256 trendId;
    bytes32 patternId;
    int256 slope;               // Positive/negative trend
    uint256 volatility;         // Standard deviation
    uint256 momentum;           // Rate of change
    uint256 supportLevel;
    uint256 resistanceLevel;
    uint256 predictionWindow;   // How far ahead to predict
    uint256 accuracy;           // Historical accuracy
}

struct MarketSignal {
    uint256 signalId;
    bytes32 patternId;
    uint256 signalType;         // 1=buy, 2=sell, 3=hold, 4=anomaly
    uint256 intensity;          // 0-10000
    uint256 confidence;
    bytes32[] correlatedAssets;
    uint256 timestamp;
    bool isExecuted;
}

struct CorrelationMatrix {
    bytes32 assetA;
    bytes32 assetB;
    int256 correlation;         // -10000 to 10000
    uint256 timeWindow;
    uint256 significance;         // Statistical significance
    bool isPositive;
}

contract PatternRecognitionEngine {
    
    mapping(bytes32 => Pattern) public patterns;
    mapping(uint256 => TrendAnalysis) public trends;
    mapping(uint256 => MarketSignal) public signals;
    mapping(bytes32 => mapping(bytes32 => CorrelationMatrix)) public correlations;
    
    bytes32[] public activePatterns;
    uint256 public patternCounter;
    uint256 public trendCounter;
    uint256 public signalCounter;
    
    // Historical data storage (circular buffer pattern)
    mapping(bytes32 => uint256[]) public priceHistory;
    mapping(bytes32 => uint256[]) public volumeHistory;
    mapping(bytes32 => uint256) public historyIndex;
    uint256 public constant HISTORY_SIZE = 1000;
    
    // Pattern matching weights
    uint256 public constant TREND_WEIGHT = 3000;
    uint256 public constant VOLATILITY_WEIGHT = 2000;
    uint256 public constant MOMENTUM_WEIGHT = 2500;
    uint256 public constant CORRELATION_WEIGHT = 2500;
    
    address public oracle;
    address public admin;
    
    event PatternDetected(bytes32 indexed patternId, string patternType, uint256 confidence);
    event TrendIdentified(uint256 indexed trendId, bytes32 indexed patternId, int256 slope);
    event SignalGenerated(uint256 indexed signalId, uint256 signalType, uint256 intensity);
    event CorrelationUpdated(bytes32 indexed assetA, bytes32 indexed assetB, int256 correlation);
    event AnomalyDetected(bytes32 indexed patternId, bytes32 dataPoint, uint256 deviation);
    
    modifier onlyOracle() {
        require(msg.sender == oracle, "PATTERN: Not oracle");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "PATTERN: Not admin");
        _;
    }
    
    constructor(address _oracle) {
        oracle = _oracle;
        admin = msg.sender;
    }
    
    /**
     * @notice Feed market data for pattern analysis
     * @dev Oracle feeds price/volume data continuously
     */
    function feedMarketData(
        bytes32 assetId,
        uint256 price,
        uint256 volume,
        uint256 timestamp
    ) external onlyOracle {
        
        uint256 idx = historyIndex[assetId];
        
        if (priceHistory[assetId].length < HISTORY_SIZE) {
            priceHistory[assetId].push(price);
            volumeHistory[assetId].push(volume);
        } else {
            priceHistory[assetId][idx] = price;
            volumeHistory[assetId][idx] = volume;
        }
        
        historyIndex[assetId] = (idx + 1) % HISTORY_SIZE;
        
        // Trigger pattern detection
        _detectPatterns(assetId, price);
    }
    
    /**
     * @notice Detect patterns in market data
     * @dev Analyzes historical data for trend/cycle/anomaly detection
     */
    function detectPattern(bytes32 assetId) external returns (bytes32 patternId) {
        require(priceHistory[assetId].length > 10, "PATTERN: Insufficient data");
        
        uint256 currentPrice = _getLatestPrice(assetId);
        return _detectPatterns(assetId, currentPrice);
    }
    
    /**
     * @notice Generate trading signal based on patterns
     * @dev Combines multiple pattern indicators into actionable signal
     */
    function generateSignal(bytes32 assetId) external returns (uint256 signalId) {
        require(priceHistory[assetId].length > 20, "PATTERN: Insufficient data");
        
        signalId = ++signalCounter;
        
        // Calculate composite score
        uint256 trendScore = _calculateTrendScore(assetId);
        uint256 momentumScore = _calculateMomentumScore(assetId);
        uint256 volatilityScore = _calculateVolatilityScore(assetId);
        
        // Weighted combination
        uint256 compositeScore = (
            trendScore * TREND_WEIGHT +
            momentumScore * MOMENTUM_WEIGHT +
            volatilityScore * VOLATILITY_WEIGHT
        ) / 10000;
        
        // Determine signal type
        uint256 signalType;
        if (compositeScore > 7000) {
            signalType = 1; // Strong buy
        } else if (compositeScore > 5500) {
            signalType = 3; // Hold/buy
        } else if (compositeScore < 3000) {
            signalType = 2; // Strong sell
        } else if (compositeScore < 4500) {
            signalType = 3; // Hold/sell
        } else {
            signalType = 3; // Hold
        }
        
        signals[signalId] = MarketSignal({
            signalId: signalId,
            patternId: bytes32(0), // Could link to specific pattern
            signalType: signalType,
            intensity: compositeScore,
            confidence: (trendScore + momentumScore) / 2,
            correlatedAssets: _findCorrelatedAssets(assetId),
            timestamp: block.timestamp,
            isExecuted: false
        });
        
        emit SignalGenerated(signalId, signalType, compositeScore);
        
        return signalId;
    }
    
    /**
     * @notice Analyze correlation between two assets
     * @dev Calculates Pearson correlation coefficient
     */
    function analyzeCorrelation(
        bytes32 assetA,
        bytes32 assetB,
        uint256 timeWindow
    ) external returns (int256 correlation, uint256 significance) {
        require(
            priceHistory[assetA].length >= timeWindow &&
            priceHistory[assetB].length >= timeWindow,
            "PATTERN: Insufficient history"
        );
        
        uint256[] memory pricesA = _getRecentPrices(assetA, timeWindow);
        uint256[] memory pricesB = _getRecentPrices(assetB, timeWindow);
        
        (correlation, significance) = _calculateCorrelation(pricesA, pricesB);
        
        correlations[assetA][assetB] = CorrelationMatrix({
            assetA: assetA,
            assetB: assetB,
            correlation: correlation,
            timeWindow: timeWindow,
            significance: significance,
            isPositive: correlation > 0
        });
        
        correlations[assetB][assetA] = correlations[assetA][assetB]; // Symmetric
        
        emit CorrelationUpdated(assetA, assetB, correlation);
    }
    
    /**
     * @notice Predict price movement
     * @dev Simple linear regression prediction
     */
    function predictPrice(bytes32 assetId, uint256 horizon) 
        external 
        view 
        returns (uint256 predictedPrice, uint256 confidence)
    {
        require(priceHistory[assetId].length > horizon, "PATTERN: Insufficient data");
        
        uint256[] memory recentPrices = _getRecentPrices(assetId, 50);
        
        // Simple moving average prediction
        uint256 sum;
        for (uint256 i = 0; i < recentPrices.length; i++) {
            sum += recentPrices[i];
        }
        
        uint256 sma = sum / recentPrices.length;
        
        // Trend adjustment
        int256 trend = _calculateRawTrend(recentPrices);
        
        predictedPrice = uint256(int256(sma) + (trend * int256(horizon)));
        
        // Confidence based on volatility
        uint256 volatility = _calculateRawVolatility(recentPrices);
        confidence = volatility > 0 ? 10000 - (volatility * 10000 / sma) : 10000;
        if (confidence > 10000) confidence = 10000;
    }
    
    /**
     * @notice Detect market anomalies
     * @dev Identifies outliers and unusual patterns
     */
    function detectAnomaly(bytes32 assetId) external returns (bool isAnomaly, uint256 severity) {
        uint256 currentPrice = _getLatestPrice(assetId);
        uint256[] memory recentPrices = _getRecentPrices(assetId, 30);
        
        uint256 mean = _calculateMean(recentPrices);
        uint256 stdDev = _calculateStdDev(recentPrices, mean);
        
        // Z-score calculation
        uint256 deviation = currentPrice > mean ? currentPrice - mean : mean - currentPrice;
        
        if (deviation > stdDev * 3) {
            // 3-sigma event (99.7% confidence anomaly)
            severity = (deviation * 10000) / mean;
            
            bytes32 patternId = keccak256(abi.encodePacked(
                assetId,
                "anomaly",
                block.timestamp
            ));
            
            patterns[patternId] = Pattern({
                patternId: patternId,
                patternType: "anomaly",
                dataPoints: _toBytes32Array(recentPrices),
                startTime: block.timestamp - 30 minutes,
                endTime: block.timestamp,
                confidence: 9970, // 99.7%
                strength: severity,
                parentPattern: bytes32(0),
                childPatterns: new bytes32[](0),
                isActive: true,
                detectionCount: 1
            });
            
            activePatterns.push(patternId);
            emit AnomalyDetected(patternId, bytes32(currentPrice), severity);
            
            return (true, severity);
        }
        
        return (false, 0);
    }
    
    /**
     * @notice Get pattern strength ranking
     * @dev Returns top patterns by confidence
     */
    function getTopPatterns(uint256 count) external view returns (bytes32[] memory topPatterns) {
        require(count <= activePatterns.length, "PATTERN: Count too high");
        
        // Simple bubble sort by confidence (in production, use heap)
        bytes32[] memory sorted = new bytes32[](activePatterns.length);
        for (uint256 i = 0; i < activePatterns.length; i++) {
            sorted[i] = activePatterns[i];
        }
        
        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = 0; j < sorted.length - i - 1; j++) {
                if (patterns[sorted[j]].confidence < patterns[sorted[j + 1]].confidence) {
                    bytes32 temp = sorted[j];
                    sorted[j] = sorted[j + 1];
                    sorted[j + 1] = temp;
                }
            }
        }
        
        topPatterns = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            topPatterns[i] = sorted[i];
        }
    }
    
    /**
     * @notice Batch analyze multiple assets
     * @dev Gas-optimized batch pattern detection
     */
    function batchAnalyze(bytes32[] calldata assetIds) 
        external 
        returns (bytes32[] memory detectedPatterns, uint256[] memory signalScores) 
    {
        detectedPatterns = new bytes32[](assetIds.length);
        signalScores = new uint256[](assetIds.length);
        
        for (uint256 i = 0; i < assetIds.length; i++) {
            if (priceHistory[assetIds[i]].length > 20) {
                uint256 currentPrice = _getLatestPrice(assetIds[i]);
                detectedPatterns[i] = _detectPatterns(assetIds[i], currentPrice);
                signalScores[i] = _calculateTrendScore(assetIds[i]);
            }
        }
    }
    
    /**
     * @notice Get comprehensive asset analysis
     */
    function getAssetAnalysis(bytes32 assetId) external view returns (
        uint256 currentPrice,
        uint256 trendScore,
        uint256 momentumScore,
        uint256 volatilityScore,
        uint256 avgVolume,
        uint256 dataPoints
    ) {
        currentPrice = _getLatestPrice(assetId);
        trendScore = _calculateTrendScore(assetId);
        momentumScore = _calculateMomentumScore(assetId);
        volatilityScore = _calculateVolatilityScore(assetId);
        avgVolume = _calculateAvgVolume(assetId);
        dataPoints = priceHistory[assetId].length;
    }
    
    // Internal functions
    
    function _detectPatterns(bytes32 assetId, uint256 currentPrice) internal returns (bytes32 patternId) {
        uint256[] memory recentPrices = _getRecentPrices(assetId, 20);
        
        // Detect trend
        int256 trend = _calculateRawTrend(recentPrices);
        uint256 trendStrength = trend > 0 ? uint256(trend) : uint256(-trend);
        
        patternId = keccak256(abi.encodePacked(
            assetId,
            trend > 0 ? "uptrend" : "downtrend",
            block.timestamp
        ));
        
        uint256 confidence = trendStrength > 100 ? 8000 : 5000;
        
        patterns[patternId] = Pattern({
            patternId: patternId,
            patternType: trend > 0 ? "uptrend" : "downtrend",
            dataPoints: _toBytes32Array(recentPrices),
            startTime: block.timestamp - 20 minutes,
            endTime: block.timestamp,
            confidence: confidence,
            strength: trendStrength,
            parentPattern: bytes32(0),
            childPatterns: new bytes32[](0),
            isActive: true,
            detectionCount: 1
        });
        
        activePatterns.push(patternId);
        
        // Create trend analysis
        uint256 trendId = ++trendCounter;
        trends[trendId] = TrendAnalysis({
            trendId: trendId,
            patternId: patternId,
            slope: trend,
            volatility: _calculateRawVolatility(recentPrices),
            momentum: _calculateRawMomentum(recentPrices),
            supportLevel: _findSupport(recentPrices),
            resistanceLevel: _findResistance(recentPrices),
            predictionWindow: 10,
            accuracy: confidence
        });
        
        emit PatternDetected(patternId, trend > 0 ? "uptrend" : "downtrend", confidence);
        emit TrendIdentified(trendId, patternId, trend);
        
        return patternId;
    }
    
    function _calculateTrendScore(bytes32 assetId) internal view returns (uint256) {
        uint256[] memory prices = _getRecentPrices(assetId, 20);
        int256 trend = _calculateRawTrend(prices);
        
        // Normalize to 0-10000
        uint256 score = trend > 0 ? uint256(trend) : 0;
        if (score > 10000) score = 10000;
        return score;
    }
    
    function _calculateMomentumScore(bytes32 assetId) internal view returns (uint256) {
        uint256[] memory prices = _getRecentPrices(assetId, 10);
        uint256 momentum = _calculateRawMomentum(prices);
        return momentum > 10000 ? 10000 : momentum;
    }
    
    function _calculateVolatilityScore(bytes32 assetId) internal view returns (uint256) {
        uint256[] memory prices = _getRecentPrices(assetId, 30);
        uint256 mean = _calculateMean(prices);
        uint256 stdDev = _calculateStdDev(prices, mean);
        
        // Lower volatility = higher score (for stability)
        uint256 score = mean > 0 ? 10000 - ((stdDev * 10000) / mean) : 5000;
        return score;
    }
    
    function _calculateCorrelation(
        uint256[] memory pricesA,
        uint256[] memory pricesB
    ) internal pure returns (int256 correlation, uint256 significance) {
        require(pricesA.length == pricesB.length, "PATTERN: Length mismatch");
        
        uint256 n = pricesA.length;
        uint256 sumA;
        uint256 sumB;
        
        for (uint256 i = 0; i < n; i++) {
            sumA += pricesA[i];
            sumB += pricesB[i];
        }
        
        uint256 meanA = sumA / n;
        uint256 meanB = sumB / n;
        
        int256 numerator;
        uint256 denomA;
        uint256 denomB;
        
        for (uint256 i = 0; i < n; i++) {
            int256 diffA = int256(pricesA[i]) - int256(meanA);
            int256 diffB = int256(pricesB[i]) - int256(meanB);
            
            numerator += diffA * diffB;
            denomA += uint256(diffA * diffA);
            denomB += uint256(diffB * diffB);
        }
        
        uint256 denominator = sqrt(denomA * denomB);
        
        if (denominator == 0) return (0, 0);
        
        correlation = (numerator * 10000) / int256(denominator);
        significance = n > 30 ? 9500 : (n * 300); // Rough significance approximation
        
        return (correlation, significance);
    }
    
    function _findCorrelatedAssets(bytes32 assetId) internal view returns (bytes32[] memory) {
        // Simplified - return empty for now
        return new bytes32[](0);
    }
    
    function _getLatestPrice(bytes32 assetId) internal view returns (uint256) {
        uint256 idx = historyIndex[assetId];
        if (idx == 0) idx = HISTORY_SIZE;
        return priceHistory[assetId][idx - 1];
    }
    
    function _getRecentPrices(bytes32 assetId, uint256 count) internal view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](count);
        uint256 currentIdx = historyIndex[assetId];
        
        for (uint256 i = 0; i < count; i++) {
            uint256 idx = (currentIdx + HISTORY_SIZE - count + i) % HISTORY_SIZE;
            prices[i] = priceHistory[assetId][idx];
        }
        
        return prices;
    }
    
    function _calculateMean(uint256[] memory values) internal pure returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
        return sum / values.length;
    }
    
    function _calculateStdDev(uint256[] memory values, uint256 mean) internal pure returns (uint256) {
        uint256 sumSquaredDiff;
        for (uint256 i = 0; i < values.length; i++) {
            int256 diff = int256(values[i]) - int256(mean);
            sumSquaredDiff += uint256(diff * diff);
        }
        return sqrt(sumSquaredDiff / values.length);
    }
    
    function _calculateRawTrend(uint256[] memory prices) internal pure returns (int256) {
        if (prices.length < 2) return 0;
        uint256 first = prices[0];
        uint256 last = prices[prices.length - 1];
        
        if (last > first) {
            return int256(((last - first) * 10000) / first);
        } else {
            return -int256(((first - last) * 10000) / first);
        }
    }
    
    function _calculateRawMomentum(uint256[] memory prices) internal pure returns (uint256) {
        if (prices.length < 2) return 0;
        uint256 sumChanges;
        for (uint256 i = 1; i < prices.length; i++) {
            sumChanges += prices[i] > prices[i - 1] ? prices[i] - prices[i - 1] : 0;
        }
        return (sumChanges * 10000) / prices.length;
    }
    
    function _calculateRawVolatility(uint256[] memory prices) internal pure returns (uint256) {
        uint256 mean = _calculateMean(prices);
        return _calculateStdDev(prices, mean);
    }
    
    function _findSupport(uint256[] memory prices) internal pure returns (uint256) {
        uint256 min = type(uint256).max;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] < min) min = prices[i];
        }
        return min;
    }
    
    function _findResistance(uint256[] memory prices) internal pure returns (uint256) {
        uint256 max = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] > max) max = prices[i];
        }
        return max;
    }
    
    function _calculateAvgVolume(bytes32 assetId) internal view returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < volumeHistory[assetId].length; i++) {
            sum += volumeHistory[assetId][i];
        }
        return volumeHistory[assetId].length > 0 ? sum / volumeHistory[assetId].length : 0;
    }
    
    function _toBytes32Array(uint256[] memory values) internal pure returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            result[i] = bytes32(values[i]);
        }
        return result;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
    
    // Admin functions
    
    function setOracle(address _oracle) external onlyAdmin {
        oracle = _oracle;
    }
}
