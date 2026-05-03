export const CONTRACT_ADDRESSES = {
  baseSepolia: {
    greenToken: '',
    marketplace: '',
    registry: '',
    proofNFT: '',
    greenAgent: '',
  },
  base: {
    greenToken: '',
    marketplace: '',
    registry: '',
    proofNFT: '',
    greenAgent: '',
  },
  hardhat: {
    greenToken: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    marketplace: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
    registry: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
    proofNFT: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
    greenAgent: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9',
  },
}

export const GREEN_TOKEN_ABI = [
  {
    inputs: [
      { name: 'name', type: 'string' },
      { name: 'symbol', type: 'string' },
      { name: 'admin', type: 'address' },
    ],
    stateMutability: 'nonpayable',
    type: 'constructor',
  },
  {
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' },
      { name: 'projectId', type: 'string' },
      { name: 'projectName', type: 'string' },
      { name: 'location', type: 'string' },
      { name: 'methodology', type: 'string' },
      { name: 'vintage', type: 'uint256' },
      { name: 'registry', type: 'string' },
    ],
    name: 'mintWithMetadata',
    outputs: [{ name: 'creditId', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'creditId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'retirementProofURI', type: 'string' },
    ],
    name: 'retire',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: '', type: 'uint256' }],
    name: 'creditMetadata',
    outputs: [
      { name: 'projectId', type: 'string' },
      { name: 'projectName', type: 'string' },
      { name: 'location', type: 'string' },
      { name: 'methodology', type: 'string' },
      { name: 'vintage', type: 'uint256' },
      { name: 'registry', type: 'string' },
      { name: 'issuedAt', type: 'uint256' },
      { name: 'retiredAt', type: 'uint256' },
      { name: 'isRetired', type: 'bool' },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'nextCreditId',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'account', type: 'address' },
    ],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'role', type: 'bytes32' },
      { name: 'account', type: 'address' },
    ],
    name: 'grantRole',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [],
    name: 'MINTER_ROLE',
    outputs: [{ name: '', type: 'bytes32' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: 'creditId', type: 'uint256' },
      { indexed: true, name: 'to', type: 'address' },
      { indexed: false, name: 'amount', type: 'uint256' },
      { indexed: false, name: 'projectId', type: 'string' },
    ],
    name: 'CreditMinted',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: 'creditId', type: 'uint256' },
      { indexed: true, name: 'by', type: 'address' },
      { indexed: false, name: 'amount', type: 'uint256' },
      { indexed: false, name: 'retirementProofURI', type: 'string' },
    ],
    name: 'CreditRetired',
    type: 'event',
  },
] as const

export const MARKETPLACE_ABI = [
  {
    inputs: [
      { name: '_paymentToken', type: 'address' },
      { name: '_greenToken', type: 'address' },
      { name: 'admin', type: 'address' },
      { name: '_platformFeeBps', type: 'uint256' },
      { name: '_feeRecipient', type: 'address' },
    ],
    stateMutability: 'nonpayable',
    type: 'constructor',
  },
  {
    inputs: [
      { name: 'creditId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'pricePerUnit', type: 'uint256' },
    ],
    name: 'listCredits',
    outputs: [{ name: 'listingId', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'listingId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
    ],
    name: 'buyCredits',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'listingId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'proofURI', type: 'string' },
    ],
    name: 'buyAndRetire',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'listingId', type: 'uint256' }],
    name: 'cancelListing',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: '', type: 'uint256' }],
    name: 'listings',
    outputs: [
      { name: 'seller', type: 'address' },
      { name: 'creditId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'pricePerUnit', type: 'uint256' },
      { name: 'active', type: 'bool' },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'nextListingId',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getAllActiveListings',
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: 'listingId', type: 'uint256' },
      { indexed: true, name: 'seller', type: 'address' },
      { indexed: false, name: 'creditId', type: 'uint256' },
      { indexed: false, name: 'amount', type: 'uint256' },
      { indexed: false, name: 'pricePerUnit', type: 'uint256' },
    ],
    name: 'Listed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: 'listingId', type: 'uint256' },
      { indexed: true, name: 'buyer', type: 'address' },
      { indexed: false, name: 'amount', type: 'uint256' },
      { indexed: false, name: 'totalPrice', type: 'uint256' },
    ],
    name: 'Bought',
    type: 'event',
  },
] as const

export const REGISTRY_ABI = [
  {
    inputs: [
      { name: '_greenToken', type: 'address' },
      { name: '_proofNFT', type: 'address' },
      { name: 'admin', type: 'address' },
    ],
    stateMutability: 'nonpayable',
    type: 'constructor',
  },
  {
    inputs: [
      { name: 'beneficiary', type: 'address' },
      { name: 'creditId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'proofURI', type: 'string' },
      { name: 'message', type: 'string' },
    ],
    name: 'recordRetirement',
    outputs: [{ name: 'proofTokenId', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'user', type: 'address' }],
    name: 'getUserRetirements',
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'totalRetired',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: 'beneficiary', type: 'address' },
      { indexed: true, name: 'creditId', type: 'uint256' },
      { indexed: false, name: 'amount', type: 'uint256' },
      { indexed: false, name: 'proofTokenId', type: 'uint256' },
      { indexed: false, name: 'message', type: 'string' },
    ],
    name: 'RetirementRecorded',
    type: 'event',
  },
] as const
