# Deployment Guide

## Prerequisites

- Node.js 18+
- Git
- Base Chain wallet with ETH

## Local Development

```bash
# Install dependencies
cd contracts && npm install

# Start local node
npx hardhat node

# Deploy contracts
npx hardhat run scripts/deploy.js --network localhost
```

## Testnet Deployment

```bash
# Set environment
cp .env.example .env
# Edit .env with your keys

# Deploy to Base Sepolia
npx hardhat run scripts/deploy.js --network baseSepolia
```

## Mainnet Deployment

1. Audit contracts
2. Test thoroughly on testnet
3. Use multi-sig for admin
4. Deploy with timelock
