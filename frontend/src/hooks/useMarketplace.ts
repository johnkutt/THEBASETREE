import { useContractRead, useContractWrite } from 'wagmi';
import { MARKETPLACE_ABI, MARKETPLACE_ADDRESS } from '../contracts';

export function useMarketplace() {
  const { data: listings } = useContractRead({
    address: MARKETPLACE_ADDRESS,
    abi: MARKETPLACE_ABI,
    functionName: 'getAllListings',
  });

  const { write: buyCredits } = useContractWrite({
    address: MARKETPLACE_ADDRESS,
    abi: MARKETPLACE_ABI,
    functionName: 'buyCredits',
  });

  const { write: listCredits } = useContractWrite({
    address: MARKETPLACE_ADDRESS,
    abi: MARKETPLACE_ABI,
    functionName: 'listCredits',
  });

  return { listings, buyCredits, listCredits };
}
