# 🌳 TheBaseTree

**A green credit marketplace and sustainability layer built natively on Base Chain.**

Sub-cent micro-offsets. 200ms settlements. AI agent compliance. For individuals and enterprises alike.

---

## Why Base is the Perfect Chain for Green Credit Markets

Traditional carbon markets are broken:
- Double-counting across siloed registries
- Brokers capturing margin on transactions that should cost cents
- Minimum lot sizes of 1,000+ credits excluding individuals and SMEs
- No fractional ownership - you can't offset your single flight
- Settlement times measured in days to weeks

Base solves every single one of these problems:

| Metric | Traditional Market | Ethereum L1 | Base (TheBaseTree) |
|--------|-------------------|-------------|-------------------|
| Settlement Time | 3-10 days | 12-30 seconds | **200ms (Flashblocks)** |
| Transfer Cost | $10-50 per credit | $2-15 gas | **<$0.01 gas** |
| Min Transaction | 1,000 credits | 1 credit | **0.001 credit** |
| Audit Trail | Manual/Siloed | On-chain | **On-chain + Public** |
| AI Agent Native | No | EOA-dependent | **Native AA (session keys)** |

---

## 🏗️ Architecture

### Smart Contracts

```
contracts/
├── GreenToken.sol           # ERC-20 with metadata and mandatory retirement
├── GreenMarketplace.sol     # DEX-style marketplace for credits
├── RetirementRegistry.sol   # On-chain retirement + proof NFT
├── RetirementProofNFT.sol   # ERC-721 retirement certificates
├── GreenAgent.sol           # AA compliance agent for automation
├── GreenGovernance.sol      # DAO governance for green standards
└── TheBaseTree.sol          # Main integration contract
```

### Frontend

```
frontend/
├── src/
│   ├── pages/
│   │   ├── Home.tsx         # Landing page with metrics
│   │   ├── Marketplace.tsx  # Browse/buy green credits
│   │   ├── Retirement.tsx  # Retire credits with proof
│   │   ├── Dashboard.tsx   # User stats and history
│   │   └── Compliance.tsx  # Enterprise AI agent setup
│   ├── App.tsx
│   ├── contracts.ts        # Contract ABIs and addresses
│   ├── wagmi.ts           # Wallet configuration
│   └── main.tsx
```

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- Git

### 1. Clone and Setup

```bash
git clone <repository>
cd thebasetree
```

### 2. Install Dependencies

**Contracts:**
```bash
cd contracts
npm install
```

**Frontend:**
```bash
cd frontend
npm install
```

### 3. Compile Contracts

```bash
cd contracts
npx hardhat compile
```

### 4. Deploy (Local)

```bash
# Terminal 1 - Start local node
npx hardhat node

# Terminal 2 - Deploy
npx hardhat run scripts/deploy.js --network localhost
```

### 5. Run Frontend

```bash
cd frontend
npm run dev
```

Visit `http://localhost:5173`

---

## 📝 Contract Deployment

### Environment Setup

Create `.env` in `contracts/`:

```env
PRIVATE_KEY=your_private_key
BASE_SEPOLIA_RPC=https://sepolia.base.org
BASE_RPC=https://mainnet.base.org
PAYMENT_TOKEN=0x...  # USDC or other payment token
ADMIN_ADDRESS=0x...
FEE_RECIPIENT=0x...
PLATFORM_FEE_BPS=100  # 1% = 100 bps
```

### Deploy to Base Sepolia

```bash
cd contracts
npx hardhat run scripts/deploy.js --network baseSepolia
```

### Deploy to Base Mainnet

```bash
npx hardhat run scripts/deploy.js --network base
```

---

## 🎯 Features

### For Individuals

1. **Micro-Offsets**: Offset as little as 0.001 tonnes (1kg CO2) for ~$0.001 gas
2. **Proof NFTs**: Receive verifiable ERC-721 retirement certificates
3. **Transparent Pricing**: Direct P2P trading, no brokers
4. **Low Fees**: Sub-cent gas on every transaction

### For Enterprises

1. **Green Compliance Agents**: AI-powered smart accounts with session keys
   - Auto-purchase credits based on real-time emissions
   - Weekly spend limits and single-transaction caps
   - Auto-retire purchased credits
   - Zero human approval per transaction

2. **ESG Reporting**: Export regulatory-grade reports for:
   - EU CSRD (Corporate Sustainability Reporting Directive)
   - SEC Climate Disclosure
   - India's BRSR (Business Responsibility & Sustainability Report)

3. **Real-Time Dashboard**: 200ms settlement updates via Flashblocks

---

## 🔧 Contract Functions

### GreenToken

```solidity
// Mint new green credits with metadata
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

// Permanently retire credits
function retire(
    uint256 creditId,
    uint256 amount,
    string calldata retirementProofURI
) external
```

### GreenMarketplace

```solidity
// List credits for sale
function listCredits(
    uint256 creditId,
    uint256 amount,
    uint256 pricePerUnit
) external returns (uint256 listingId)

// Buy and auto-retire in one tx
function buyAndRetire(
    uint256 listingId,
    uint256 amount,
    string calldata proofURI
) external
```

### GreenAgent (AA Compliance)

```solidity
// Configure agent policy
function setPolicy(
    uint256 weeklySpendLimit,
    uint256 maxSinglePurchase,
    uint256 minimumListingId
) external

// Auto-retire based on emissions data
function autoRetire(
    bytes32 sessionId,
    uint256 listingId,
    uint256 amount,
    string calldata proofURI,
    bytes calldata signature
) external
```

---

## 🧪 Testing

```bash
cd contracts
npx hardhat test
```

---

## 📚 Tech Stack

### Contracts
- Solidity 0.8.24
- OpenZeppelin Contracts 5.0
- Hardhat
- TypeChain (optional)

### Frontend
- React 18 + TypeScript
- Vite
- Tailwind CSS
- Wagmi + RainbowKit
- TanStack Query
- Lucide Icons

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Base team for Flashblocks and Native AA
- OpenZeppelin for secure contract libraries
- KlimaDAO and Toucan for pioneering on-chain carbon

---

**Built with 💚 on Base**

Be authentic. Be creative. Be Based. 🌳
