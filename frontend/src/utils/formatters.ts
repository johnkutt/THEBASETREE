export function formatAmount(amount: bigint | number, decimals = 2): string {
  const num = typeof amount === 'bigint' ? Number(amount) / 1e18 : amount;
  return num.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

export function formatAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

export function formatTimestamp(timestamp: number): string {
  return new Date(timestamp * 1000).toLocaleDateString();
}
