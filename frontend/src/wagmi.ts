import { createConfig, http } from 'wagmi'
import { base, baseSepolia, hardhat } from 'wagmi/chains'
import { injected, walletConnect } from 'wagmi/connectors'

export const config = createConfig({
  chains: [base, baseSepolia, hardhat],
  connectors: [
    injected(),
    walletConnect({
      projectId: 'YOUR_WC_PROJECT_ID',
    }),
  ],
  transports: {
    [base.id]: http(),
    [baseSepolia.id]: http(),
    [hardhat.id]: http('http://127.0.0.1:8545'),
  },
})
