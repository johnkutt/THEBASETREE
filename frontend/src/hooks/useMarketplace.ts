import { useReadContract, useWriteContract } from 'wagmi';
import { MARKETPLACE_ABI, CONTRACT_ADDRESSES } from '../contracts';

const MARKETPLACE_ADDRESS = CONTRACT_ADDRESSES.hardhat.marketplace as `0x${string}`;

export function useMarketplace() {
  const { data: listings } = useReadContract({
    address: MARKETPLACE_ADDRESS,
    abi: MARKETPLACE_ABI,
    functionName: 'getAllActiveListings',
  });

  const { writeContract } = useWriteContract();

  const buyCredits = (listingId: bigint, amount: bigint) =>
    writeContract({
      address: MARKETPLACE_ADDRESS,
      abi: MARKETPLACE_ABI,
      functionName: 'buyCredits',
      args: [listingId, amount],
    });

  const listCredits = (creditId: bigint, amount: bigint, pricePerUnit: bigint) =>
    writeContract({
      address: MARKETPLACE_ADDRESS,
      abi: MARKETPLACE_ABI,
      functionName: 'listCredits',
      args: [creditId, amount, pricePerUnit],
    });

  return { listings, buyCredits, listCredits };
}
