# TheBaseTree API Reference

## Smart Contract API

### GreenToken

#### mintWithMetadata
```solidity
function mintWithMetadata(
    address to,
    uint256 amount,
    string calldata projectId,
    string calldata projectName,
    string calldata location,
    string calldata methodology,
    uint256 vintage,
    string calldata registry
) external returns (uint256 creditId)
```

#### retire
```solidity
function retire(
    uint256 creditId,
    uint256 amount,
    string calldata retirementProofURI
) external
```

### GreenMarketplace

#### listCredits
```solidity
function listCredits(
    uint256 creditId,
    uint256 amount,
    uint256 pricePerUnit
) external returns (uint256 listingId)
```

#### buyCredits
```solidity
function buyCredits(uint256 listingId, uint256 amount) external
```

## Frontend Hooks

### useCredits
```typescript
const { balance, retire } = useCredits(account);
```

### useMarketplace
```typescript
const { listings, buy } = useMarketplace();
```
