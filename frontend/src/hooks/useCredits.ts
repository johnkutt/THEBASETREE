import { useReadContract, useWriteContract } from 'wagmi';
import { GREEN_TOKEN_ABI, CONTRACT_ADDRESSES } from '../contracts';

const GREEN_TOKEN_ADDRESS = CONTRACT_ADDRESSES.hardhat.greenToken as `0x${string}`;

export function useCredits(account: string | undefined) {
  const { data: balance } = useReadContract({
    address: GREEN_TOKEN_ADDRESS,
    abi: GREEN_TOKEN_ABI,
    functionName: 'balanceOf',
    args: account ? [account as `0x${string}`] : undefined,
    query: { enabled: !!account },
  });

  const { writeContract: retire } = useWriteContract();

  const retireCredits = (creditId: bigint, amount: bigint, proofURI: string) =>
    retire({
      address: GREEN_TOKEN_ADDRESS,
      abi: GREEN_TOKEN_ABI,
      functionName: 'retire',
      args: [creditId, amount, proofURI],
    });

  return { balance, retire: retireCredits };
}
