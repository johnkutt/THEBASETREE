import { useState, useEffect } from 'react'
import { useAccount, useReadContract } from 'wagmi'
import { Search, Filter, ShoppingCart, Leaf, MapPin, Calendar, Tag } from 'lucide-react'
import { CONTRACT_ADDRESSES, MARKETPLACE_ABI } from '../contracts'

interface Listing {
  id: number
  seller: string
  creditId: number
  amount: bigint
  pricePerUnit: bigint
  active: boolean
}

interface CreditMetadata {
  projectId: string
  projectName: string
  location: string
  methodology: string
  vintage: bigint
  registry: string
}

function ListingCard({ listing, metadata, onBuy }: { 
  listing: Listing
  metadata?: CreditMetadata
  onBuy: (id: number, amount: string) => void 
}) {
  const [buyAmount, setBuyAmount] = useState('')
  
  const totalPrice = listing.pricePerUnit * BigInt(buyAmount || 0) / BigInt(10 ** 18)
  
  return (
    <div className="glass-card p-5 hover:bg-white/15 transition-all">
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="text-lg font-semibold text-white">
            {metadata?.projectName || `Credit #${listing.creditId}`}
          </h3>
          <div className="flex items-center gap-2 text-white/60 text-sm mt-1">
            <MapPin size={14} />
            <span>{metadata?.location || 'Unknown'}</span>
          </div>
        </div>
        <div className="text-right">
          <div className="text-green-400 font-bold">
            ${(Number(listing.pricePerUnit) / 1e18).toFixed(2)}
          </div>
          <div className="text-white/50 text-sm">per tonne</div>
        </div>
      </div>
      
      <div className="grid grid-cols-2 gap-3 mb-4 text-sm">
        <div className="flex items-center gap-2 text-white/70">
          <Leaf size={14} />
          <span>{metadata?.methodology || 'Standard'}</span>
        </div>
        <div className="flex items-center gap-2 text-white/70">
          <Calendar size={14} />
          <span>Vintage {metadata?.vintage?.toString() || '2024'}</span>
        </div>
        <div className="flex items-center gap-2 text-white/70">
          <Tag size={14} />
          <span>{Number(listing.amount).toLocaleString()} tonnes available</span>
        </div>
        <div className="flex items-center gap-2 text-white/70">
          <span className="text-xs bg-green-500/20 px-2 py-1 rounded">
            {metadata?.registry || 'Verra'}
          </span>
        </div>
      </div>
      
      <div className="flex gap-3">
        <input
          type="number"
          placeholder="Amount (tonnes)"
          value={buyAmount}
          onChange={(e) => setBuyAmount(e.target.value)}
          className="input-field flex-1 text-sm"
          min="0.001"
          max={Number(listing.amount)}
          step="0.001"
        />
        <button
          onClick={() => onBuy(listing.id, buyAmount)}
          disabled={!buyAmount || parseFloat(buyAmount) <= 0}
          className="btn-primary flex items-center gap-2 disabled:opacity-50"
        >
          <ShoppingCart size={16} />
          Buy
        </button>
      </div>
      
      {buyAmount && (
        <div className="mt-3 text-sm text-white/60 text-right">
          Total: <span className="text-white font-medium">${Number(totalPrice).toFixed(4)}</span>
        </div>
      )}
    </div>
  )
}

export default function Marketplace() {
  const { isConnected } = useAccount()
  const [searchQuery, setSearchQuery] = useState('')
  const [filterRegistry, setFilterRegistry] = useState('all')

  const { data: allListingsData } = useReadContract({
    address: CONTRACT_ADDRESSES.hardhat.marketplace as `0x${string}`,
    abi: MARKETPLACE_ABI,
    functionName: 'getAllActiveListings',
  })

  useEffect(() => {
    // allListingsData available for future contract integration
    void allListingsData
  }, [allListingsData])

  const handleBuy = async (listingId: number, amount: string) => {
    // Buy logic would go here
    console.log('Buying', amount, 'from listing', listingId)
  }

  const mockListings = [
    {
      id: 1,
      seller: '0x1234...',
      creditId: 1,
      amount: BigInt(50000),
      pricePerUnit: BigInt(3 * 10 ** 18),
      active: true,
      metadata: {
        projectId: 'VCS-VCU-1234',
        projectName: 'Kerala Reforestation Project',
        location: 'Kerala, India',
        methodology: 'ARR (Afforestation)',
        vintage: BigInt(2023),
        registry: 'Verra'
      }
    },
    {
      id: 2,
      seller: '0x5678...',
      creditId: 2,
      amount: BigInt(25000),
      pricePerUnit: BigInt(5 * 10 ** 18),
      active: true,
      metadata: {
        projectId: 'GS-4567',
        projectName: 'US Methane Capture',
        location: 'Texas, USA',
        methodology: 'Methane Destruction',
        vintage: BigInt(2024),
        registry: 'Gold Standard'
      }
    },
    {
      id: 3,
      seller: '0x9abc...',
      creditId: 3,
      amount: BigInt(10000),
      pricePerUnit: BigInt(2 * 10 ** 18),
      active: true,
      metadata: {
        projectId: 'VCS-VCU-7890',
        projectName: 'Amazon REDD+',
        location: 'Brazil',
        methodology: 'REDD+',
        vintage: BigInt(2023),
        registry: 'Verra'
      }
    },
  ]

  const filteredListings = mockListings.filter(l => 
    (filterRegistry === 'all' || l.metadata?.registry === filterRegistry) &&
    (l.metadata?.projectName.toLowerCase().includes(searchQuery.toLowerCase()) ||
     l.metadata?.location.toLowerCase().includes(searchQuery.toLowerCase()))
  )

  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Green Credit Marketplace</h1>
        <p className="text-white/70">Buy verified carbon credits directly from projects worldwide</p>
      </div>

      <div className="flex flex-col md:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-white/50" />
          <input
            type="text"
            placeholder="Search projects, locations..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="input-field w-full pl-10"
          />
        </div>
        <div className="flex items-center gap-2">
          <Filter className="w-5 h-5 text-white/50" />
          <select
            value={filterRegistry}
            onChange={(e) => setFilterRegistry(e.target.value)}
            className="input-field"
          >
            <option value="all">All Registries</option>
            <option value="Verra">Verra (VCS)</option>
            <option value="Gold Standard">Gold Standard</option>
            <option value="American Carbon Registry">ACR</option>
          </select>
        </div>
      </div>

      {!isConnected && (
        <div className="glass-card p-8 text-center">
          <p className="text-white/70 mb-4">Connect your wallet to start trading green credits</p>
          <div className="inline-block animate-pulse bg-green-500/20 px-4 py-2 rounded-lg text-green-400">
            Connect wallet above ↑
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredListings.map((listing) => (
          <ListingCard
            key={listing.id}
            listing={listing}
            metadata={listing.metadata}
            onBuy={handleBuy}
          />
        ))}
      </div>

      {filteredListings.length === 0 && (
        <div className="text-center py-12">
          <Leaf className="w-12 h-12 text-white/30 mx-auto mb-4" />
          <p className="text-white/50">No listings match your criteria</p>
        </div>
      )}

      <div className="glass-card p-6">
        <h3 className="text-lg font-semibold text-white mb-3">How It Works</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm">
          <div className="text-center">
            <div className="w-10 h-10 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-2">
              <span className="text-green-400 font-bold">1</span>
            </div>
            <p className="text-white/70">Browse verified green projects</p>
          </div>
          <div className="text-center">
            <div className="w-10 h-10 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-2">
              <span className="text-green-400 font-bold">2</span>
            </div>
            <p className="text-white/70">Select amount (as low as 0.001 tonnes)</p>
          </div>
          <div className="text-center">
            <div className="w-10 h-10 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-2">
              <span className="text-green-400 font-bold">3</span>
            </div>
            <p className="text-white/70">Buy with sub-cent gas fees</p>
          </div>
          <div className="text-center">
            <div className="w-10 h-10 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-2">
              <span className="text-green-400 font-bold">4</span>
            </div>
            <p className="text-white/70">Receive on-chain proof of retirement</p>
          </div>
        </div>
      </div>
    </div>
  )
}
