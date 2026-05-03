export interface Credit {
  id: string;
  projectName: string;
  location: string;
  methodology: string;
  vintage: number;
  amount: bigint;
  price: bigint;
  seller: string;
}

export interface Listing {
  id: number;
  seller: string;
  creditId: number;
  amount: bigint;
  pricePerUnit: bigint;
  isActive: boolean;
}

export interface Retirement {
  id: string;
  creditId: string;
  amount: bigint;
  timestamp: number;
  beneficiary: string;
  proofURI: string;
}

export interface UserStats {
  totalRetired: bigint;
  totalPurchased: bigint;
  activeListings: number;
  nftsOwned: number;
}
