export const APP_NAME = 'TheBaseTree';
export const APP_VERSION = '1.0.0';

export const SUPPORTED_CHAINS = [
  { id: 8453, name: 'Base Mainnet' },
  { id: 84532, name: 'Base Sepolia' },
] as const;

export const TOKEN_DECIMALS = 18;
export const DEFAULT_GAS_LIMIT = 300000;

export const MARKETPLACE_FEE = 100; // 1% in basis points
export const MIN_LISTING_AMOUNT = 1; // Minimum 1 credit
