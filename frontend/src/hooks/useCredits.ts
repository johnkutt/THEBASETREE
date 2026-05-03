import { useContractRead, useContractWrite } from 'wagmi';
import { GREEN_TOKEN_ABI, GREEN_TOKEN_ADDRESS } from '../contracts';

export function useCredits(account: string | undefined) {
  const { data: balance } = useContractRead({
    address: GREEN_TOKEN_ADDRESS,
    abi: GREEN_TOKEN_ABI,
    functionName: 'balanceOf',
    args: account ? [account] : undefined,
    enabled: !!account,
  });

  const { write: retire } = useContractWrite({
    address: GREEN_TOKEN_ADDRESS,
    abi: GREEN_TOKEN_ABI,
    functionName: 'retire',
  });

  return { balance, retire };
}
