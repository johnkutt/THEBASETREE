// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title RegionalCreditAdapter
 * @notice Multi-jurisdiction credit market adapter for ASEAN + India
 * @dev Handles Malaysia, Singapore, India credit standards and regulations
 */

struct RegionalMarket {
    uint256 marketId;
    string countryCode;         // "MY", "SG", "IN", etc
    string currency;            // "MYR", "SGD", "INR"
    uint256 carbonPrice;        // Local price per tonne (in local currency, scaled)
    uint256 minCreditUnit;      // Minimum tradable unit
    uint256 regulatoryTier;     // 1=strict, 2=moderate, 3=emerging
    address registryContract;
    bool isActive;
    uint256 tradingVolume24h;
    uint256 totalRetired;
}

struct RegulatoryCompliance {
    uint256 complianceId;
    uint256 marketId;
    string standardType;        // "VCS", "GoldStandard", "MYCarbon", "CCEI"
    bytes32 certificateHash;
    uint256 issueDate;
    uint256 expiryDate;
    bool isVerified;
    address auditor;
}

struct CrossBorderTrade {
    uint256 tradeId;
    uint256 sourceMarket;
    uint256 targetMarket;
    bytes32 creditId;
    uint256 amount;
    uint256 conversionRate;     // FX rate at time of trade
    uint256 fees;
    uint256 status;             // 1=pending, 2=approved, 3=settled, 4=rejected
    uint256 timestamp;
}

struct EconomicIndicator {
    bytes32 indicatorId;
    uint256 marketId;
    string metricType;          // "GDP", "Inflation", "CreditDemand", "ESGScore"
    uint256 value;
    uint256 timestamp;
    uint256 confidence;         // 0-10000
    bytes32 dataSource;         // Oracle source hash
}

contract RegionalCreditAdapter {
    
    // Market registry
    mapping(uint256 => RegionalMarket) public markets;
    mapping(string => uint256) public countryToMarket;
    uint256 public marketCounter;
    
    // Compliance tracking
    mapping(uint256 => RegulatoryCompliance) public compliances;
    mapping(uint256 => uint256[]) public marketCompliances;
    uint256 public complianceCounter;
    
    // Cross-border trades
    mapping(uint256 => CrossBorderTrade) public trades;
    mapping(uint256 => uint256[]) public marketTrades;
    uint256 public tradeCounter;
    
    // Economic indicators
    mapping(bytes32 => EconomicIndicator) public indicators;
    mapping(uint256 => bytes32[]) public marketIndicators;
    
    // FX rates (scaled by 1e6)
    mapping(string => mapping(string => uint256)) public fxRates;
    mapping(string => uint256) public rateLastUpdate;
    
    // Local validators
    mapping(uint256 => address[]) public marketValidators;
    mapping(address => mapping(uint256 => bool)) public isValidatorForMarket;
    
    address public oracle;
    address public admin;
    
    // Constants
    uint256 public constant FX_SCALE = 1e6;
    uint256 public constant CARBON_PRICE_SCALE = 1e2; // 2 decimal places
    
    // Events
    event MarketRegistered(uint256 indexed marketId, string countryCode, string currency);
    event ComplianceCertified(uint256 indexed complianceId, uint256 indexed marketId, string standardType);
    event CrossBorderInitiated(uint256 indexed tradeId, uint256 sourceMarket, uint256 targetMarket, bytes32 creditId);
    event TradeSettled(uint256 indexed tradeId, uint256 finalAmount, uint256 fees);
    event IndicatorUpdated(bytes32 indexed indicatorId, uint256 marketId, string metricType, uint256 value);
    event FXRateUpdated(string fromCurrency, string toCurrency, uint256 rate);
    
    modifier onlyOracle() {
        require(msg.sender == oracle, "REGIONAL: Not oracle");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "REGIONAL: Not admin");
        _;
    }
    
    modifier onlyValidator(uint256 marketId) {
        require(isValidatorForMarket[msg.sender][marketId], "REGIONAL: Not validator");
        _;
    }
    
    constructor(address _oracle) {
        oracle = _oracle;
        admin = msg.sender;
        
        // Auto-initialize major markets
        _initializeDefaultMarkets();
    }
    
    /**
     * @notice Initialize default regional markets
     */
    function _initializeDefaultMarkets() internal {
        // Malaysia
        _registerMarket("MY", "MYR", 8500, 100, 2); // Moderate regulation
        
        // Singapore
        _registerMarket("SG", "SGD", 12000, 10, 1); // Strict regulation
        
        // India
        _registerMarket("IN", "INR", 4500, 1000, 3); // Emerging, larger units
        
        // Indonesia
        _registerMarket("ID", "IDR", 3200, 500, 3);
        
        // Thailand
        _registerMarket("TH", "THB", 5800, 100, 2);
        
        // Vietnam
        _registerMarket("VN", "VND", 2100, 1000, 3);
        
        // Philippines
        _registerMarket("PH", "PHP", 3900, 100, 2);
        
        // Set initial FX rates (scaled by 1e6)
        fxRates["USD"]["MYR"] = 4700000;  // 1 USD = 4.70 MYR
        fxRates["USD"]["SGD"] = 1340000; // 1 USD = 1.34 SGD
        fxRates["USD"]["INR"] = 83000000; // 1 USD = 83.00 INR
        fxRates["USD"]["IDR"] = 15600000000; // 1 USD = 15,600 IDR
        fxRates["USD"]["THB"] = 35000000; // 1 USD = 35.00 THB
        fxRates["USD"]["VND"] = 245000000000; // 1 USD = 24,500 VND
        fxRates["USD"]["PHP"] = 56000000; // 1 USD = 56.00 PHP
    }
    
    /**
     * @notice Register new regional market
     */
    function registerMarket(
        string calldata countryCode,
        string calldata currency,
        uint256 carbonPrice,
        uint256 minCreditUnit,
        uint256 regulatoryTier
    ) external onlyAdmin returns (uint256 marketId) {
        return _registerMarket(countryCode, currency, carbonPrice, minCreditUnit, regulatoryTier);
    }
    
    function _registerMarket(
        string memory countryCode,
        string memory currency,
        uint256 carbonPrice,
        uint256 minCreditUnit,
        uint256 regulatoryTier
    ) internal returns (uint256 marketId) {
        marketId = ++marketCounter;
        
        markets[marketId] = RegionalMarket({
            marketId: marketId,
            countryCode: countryCode,
            currency: currency,
            carbonPrice: carbonPrice,
            minCreditUnit: minCreditUnit,
            regulatoryTier: regulatoryTier,
            registryContract: address(0),
            isActive: true,
            tradingVolume24h: 0,
            totalRetired: 0
        });
        
        countryToMarket[countryCode] = marketId;
        
        emit MarketRegistered(marketId, countryCode, currency);
    }
    
    /**
     * @notice Certify compliance for a credit
     * @dev Regional auditors validate credits against local standards
     */
    function certifyCompliance(
        uint256 marketId,
        bytes32 creditId,
        string calldata standardType,
        bytes32 certificateHash,
        uint256 validityPeriod
    ) external onlyValidator(marketId) returns (uint256 complianceId) {
        require(markets[marketId].isActive, "REGIONAL: Market not active");
        
        complianceId = ++complianceCounter;
        
        compliances[complianceId] = RegulatoryCompliance({
            complianceId: complianceId,
            marketId: marketId,
            standardType: standardType,
            certificateHash: certificateHash,
            issueDate: block.timestamp,
            expiryDate: block.timestamp + validityPeriod,
            isVerified: true,
            auditor: msg.sender
        });
        
        marketCompliances[marketId].push(complianceId);
        
        emit ComplianceCertified(complianceId, marketId, standardType);
    }
    
    /**
     * @notice Initiate cross-border credit trade
     * @dev Handles FX conversion and regulatory compliance
     */
    function initiateCrossBorderTrade(
        uint256 sourceMarketId,
        uint256 targetMarketId,
        bytes32 creditId,
        uint256 amount
    ) external returns (uint256 tradeId) {
        require(markets[sourceMarketId].isActive, "REGIONAL: Source market inactive");
        require(markets[targetMarketId].isActive, "REGIONAL: Target market inactive");
        
        RegionalMarket storage source = markets[sourceMarketId];
        RegionalMarket storage target = markets[targetMarketId];
        
        // Check minimum unit requirements
        require(amount >= source.minCreditUnit, "REGIONAL: Below source minimum");
        require(amount >= target.minCreditUnit, "REGIONAL: Below target minimum");
        
        // Calculate FX conversion
        uint256 conversionRate = _getFXRate(source.currency, target.currency);
        uint256 convertedAmount = (amount * conversionRate) / FX_SCALE;
        
        // Calculate fees (0.5% base + tier adjustment)
        uint256 baseFee = (convertedAmount * 50) / 10000;
        uint256 tierFee = baseFee * (source.regulatoryTier + target.regulatoryTier) / 4;
        uint256 totalFees = baseFee + tierFee;
        
        tradeId = ++tradeCounter;
        
        trades[tradeId] = CrossBorderTrade({
            tradeId: tradeId,
            sourceMarket: sourceMarketId,
            targetMarket: targetMarketId,
            creditId: creditId,
            amount: amount,
            conversionRate: conversionRate,
            fees: totalFees,
            status: 1, // Pending
            timestamp: block.timestamp
        });
        
        marketTrades[sourceMarketId].push(tradeId);
        marketTrades[targetMarketId].push(tradeId);
        
        emit CrossBorderInitiated(tradeId, sourceMarketId, targetMarketId, creditId);
        
        return tradeId;
    }
    
    /**
     * @notice Settle cross-border trade after validation
     */
    function settleTrade(uint256 tradeId) external onlyValidator(trades[tradeId].targetMarket) {
        CrossBorderTrade storage trade = trades[tradeId];
        require(trade.status == 1, "REGIONAL: Trade not pending");
        
        // Update volumes
        markets[trade.sourceMarket].tradingVolume24h += trade.amount;
        markets[trade.targetMarket].tradingVolume24h += trade.amount - trade.fees;
        
        trade.status = 3; // Settled
        
        emit TradeSettled(tradeId, trade.amount - trade.fees, trade.fees);
    }
    
    /**
     * @notice Update economic indicator for a market
     * @dev Oracle feeds macroeconomic data
     */
    function updateEconomicIndicator(
        uint256 marketId,
        string calldata metricType,
        uint256 value,
        uint256 confidence,
        bytes32 dataSource
    ) external onlyOracle returns (bytes32 indicatorId) {
        require(markets[marketId].isActive, "REGIONAL: Market not active");
        
        indicatorId = keccak256(abi.encodePacked(
            marketId,
            metricType,
            block.timestamp
        ));
        
        indicators[indicatorId] = EconomicIndicator({
            indicatorId: indicatorId,
            marketId: marketId,
            metricType: metricType,
            value: value,
            timestamp: block.timestamp,
            confidence: confidence,
            dataSource: dataSource
        });
        
        marketIndicators[marketId].push(indicatorId);
        
        emit IndicatorUpdated(indicatorId, marketId, metricType, value);
    }
    
    /**
     * @notice Update FX rates
     */
    function updateFXRate(
        string calldata fromCurrency,
        string calldata toCurrency,
        uint256 rate
    ) external onlyOracle {
        fxRates[fromCurrency][toCurrency] = rate;
        rateLastUpdate[fromCurrency] = block.timestamp;
        
        emit FXRateUpdated(fromCurrency, toCurrency, rate);
    }
    
    /**
     * @notice Get optimal trading route
     * @dev Calculates best path for cross-border trades
     */
    function getOptimalRoute(
        uint256 sourceMarketId,
        uint256 targetMarketId,
        uint256 amount
    ) external view returns (
        uint256[] memory route,
        uint256 totalFees,
        uint256 finalAmount
    ) {
        // Simplified: direct route only
        // In production: implement graph search (Dijkstra)
        
        route = new uint256[](2);
        route[0] = sourceMarketId;
        route[1] = targetMarketId;
        
        RegionalMarket storage source = markets[sourceMarketId];
        RegionalMarket storage target = markets[targetMarketId];
        
        uint256 conversionRate = _getFXRate(source.currency, target.currency);
        uint256 converted = (amount * conversionRate) / FX_SCALE;
        
        uint256 baseFee = (converted * 50) / 10000;
        uint256 tierFee = baseFee * (source.regulatoryTier + target.regulatoryTier) / 4;
        totalFees = baseFee + tierFee;
        
        finalAmount = converted - totalFees;
    }
    
    /**
     * @notice Get regional market comparison
     */
    function getMarketComparison(uint256[] calldata marketIds) 
        external 
        view 
        returns (
            string[] memory countryCodes,
            uint256[] memory carbonPrices,
            uint256[] memory minUnits,
            uint256[] memory volumes,
            uint256[] memory regulatoryTiers
        ) 
    {
        countryCodes = new string[](marketIds.length);
        carbonPrices = new uint256[](marketIds.length);
        minUnits = new uint256[](marketIds.length);
        volumes = new uint256[](marketIds.length);
        regulatoryTiers = new uint256[](marketIds.length);
        
        for (uint256 i = 0; i < marketIds.length; i++) {
            RegionalMarket storage market = markets[marketIds[i]];
            countryCodes[i] = market.countryCode;
            carbonPrices[i] = market.carbonPrice;
            minUnits[i] = market.minCreditUnit;
            volumes[i] = market.tradingVolume24h;
            regulatoryTiers[i] = market.regulatoryTier;
        }
    }
    
    /**
     * @notice Get Indian economic growth stage indicators
     * @dev Specialized analysis for India market
     */
    function getIndiaGrowthMetrics() external view returns (
        uint256 gdpGrowth,
        uint256 creditDemand,
        uint256 esgScore,
        uint256 marketMaturity
    ) {
        uint256 indiaMarketId = countryToMarket["IN"];
        
        // Aggregate recent indicators
        bytes32[] storage indIndicators = marketIndicators[indiaMarketId];
        
        for (uint256 i = 0; i < indIndicators.length && i < 100; i++) {
            EconomicIndicator storage ind = indicators[indIndicators[i]];
            
            if (keccak256(bytes(ind.metricType)) == keccak256(bytes("GDP"))) {
                gdpGrowth = ind.value;
            } else if (keccak256(bytes(ind.metricType)) == keccak256(bytes("CreditDemand"))) {
                creditDemand = ind.value;
            } else if (keccak256(bytes(ind.metricType)) == keccak256(bytes("ESGScore"))) {
                esgScore = ind.value;
            }
        }
        
        // Calculate market maturity based on regulatory tier and volume
        RegionalMarket storage india = markets[indiaMarketId];
        marketMaturity = (india.tradingVolume24h / 1e6) + (4 - india.regulatoryTier) * 25;
    }
    
    /**
     * @notice Validate credit for multi-jurisdiction trading
     */
    function validateForTrading(
        bytes32 creditId,
        uint256 sourceMarketId,
        uint256 targetMarketId
    ) external view returns (
        bool isValid,
        uint256 complianceScore,
        string[] memory missingRequirements
    ) {
        // Check source market compliance
        uint256[] storage sourceCompliances = marketCompliances[sourceMarketId];
        bool sourceValid = false;
        
        for (uint256 i = 0; i < sourceCompliances.length; i++) {
            if (compliances[sourceCompliances[i]].certificateHash == creditId &&
                compliances[sourceCompliances[i]].expiryDate > block.timestamp) {
                sourceValid = true;
                break;
            }
        }
        
        // Check target market acceptance
        uint256[] storage targetCompliances = marketCompliances[targetMarketId];
        bool targetAcceptable = targetMarketId == sourceMarketId; // Same market always valid
        
        for (uint256 i = 0; i < targetCompliances.length && !targetAcceptable; i++) {
            if (compliances[targetCompliances[i]].certificateHash == creditId &&
                compliances[targetCompliances[i]].expiryDate > block.timestamp) {
                targetAcceptable = true;
                break;
            }
        }
        
        isValid = sourceValid && targetAcceptable;
        complianceScore = isValid ? 10000 : (sourceValid ? 5000 : 0);
        
        // Return missing requirements
        if (!isValid) {
            missingRequirements = new string[](2);
            if (!sourceValid) missingRequirements[0] = "Source compliance missing";
            if (!targetAcceptable) missingRequirements[1] = "Target market acceptance missing";
        }
    }
    
    // Internal functions
    
    function _getFXRate(string memory from, string memory to) internal view returns (uint256) {
        if (keccak256(bytes(from)) == keccak256(bytes(to))) {
            return FX_SCALE; // 1:1
        }
        
        // Try direct rate
        uint256 directRate = fxRates[from][to];
        if (directRate > 0) return directRate;
        
        // Try via USD
        uint256 fromUSD = fxRates["USD"][from];
        uint256 toUSD = fxRates["USD"][to];
        
        if (fromUSD > 0 && toUSD > 0) {
            return (toUSD * FX_SCALE) / fromUSD;
        }
        
        return FX_SCALE; // Default 1:1 if no rate found
    }
    
    // Admin functions
    
    function addValidator(uint256 marketId, address validator) external onlyAdmin {
        marketValidators[marketId].push(validator);
        isValidatorForMarket[validator][marketId] = true;
    }
    
    function removeValidator(uint256 marketId, address validator) external onlyAdmin {
        isValidatorForMarket[validator][marketId] = false;
    }
    
    function updateMarketStatus(uint256 marketId, bool isActive) external onlyAdmin {
        markets[marketId].isActive = isActive;
    }
    
    function setMarketRegistry(uint256 marketId, address registry) external onlyAdmin {
        markets[marketId].registryContract = registry;
    }
    
    function setOracle(address _oracle) external onlyAdmin {
        oracle = _oracle;
    }
}
