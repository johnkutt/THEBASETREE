import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Leaf, CheckCircle, FileText, Award, ExternalLink } from 'lucide-react'

export default function Retirement() {
  const { isConnected } = useAccount()
  const [creditId, setCreditId] = useState('')
  const [amount, setAmount] = useState('')
  const [message, setMessage] = useState('')
  const [retired, setRetired] = useState(false)

  const handleRetire = async () => {
    // Would call the contract here
    console.log('Retiring', amount, 'of credit', creditId)
    setRetired(true)
    setTimeout(() => setRetired(false), 5000)
  }

  const mockRetirementHistory = [
    {
      id: 1,
      creditId: 1,
      amount: '0.5',
      projectName: 'Kerala Reforestation Project',
      date: '2024-03-15',
      txHash: '0x1234...5678',
      message: 'Offsetting my flight to Mumbai',
      proofTokenId: 42
    },
    {
      id: 2,
      creditId: 2,
      amount: '2.1',
      projectName: 'US Methane Capture',
      date: '2024-03-10',
      txHash: '0x8765...4321',
      message: 'Uber rides this month',
      proofTokenId: 38
    }
  ]

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="text-center">
        <h1 className="text-3xl font-bold text-white mb-2">Retire Green Credits</h1>
        <p className="text-white/70">Permanently retire credits and receive verifiable proof</p>
      </div>

      <div className="glass-card p-8">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center">
            <Leaf className="w-6 h-6 text-green-400" />
          </div>
          <div>
            <h2 className="text-xl font-semibold text-white">New Retirement</h2>
            <p className="text-white/60 text-sm">Retirement is permanent and on-chain</p>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-white/80 text-sm mb-2">Credit ID</label>
            <input
              type="text"
              placeholder="Enter credit ID from marketplace"
              value={creditId}
              onChange={(e) => setCreditId(e.target.value)}
              className="input-field w-full"
            />
          </div>

          <div>
            <label className="block text-white/80 text-sm mb-2">Amount (tonnes CO2)</label>
            <input
              type="number"
              placeholder="0.001"
              min="0.001"
              step="0.001"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="input-field w-full"
            />
            <p className="text-white/50 text-xs mt-1">
              Minimum: 0.001 tonnes (1kg CO2). Gas fee: ~$0.001
            </p>
          </div>

          <div>
            <label className="block text-white/80 text-sm mb-2">Retirement Message (Optional)</label>
            <textarea
              placeholder="Why are you retiring these credits? e.g., 'Offsetting my March business travel'"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="input-field w-full h-24 resize-none"
            />
          </div>

          <button
            onClick={handleRetire}
            disabled={!isConnected || !creditId || !amount}
            className="btn-primary w-full flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <Leaf size={20} />
            {isConnected ? 'Retire Credits' : 'Connect Wallet First'}
          </button>

          {retired && (
            <div className="bg-green-500/20 border border-green-500/30 rounded-lg p-4 animate-pulse">
              <div className="flex items-center gap-2 text-green-400">
                <CheckCircle size={20} />
                <span className="font-semibold">Credits Retired Successfully!</span>
              </div>
              <p className="text-white/70 text-sm mt-2">
                Your retirement proof NFT has been minted. View it in your dashboard.
              </p>
            </div>
          )}
        </div>
      </div>

      <div className="glass-card p-6">
        <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Award className="w-5 h-5 text-green-400" />
          Your Retirement History
        </h3>

        {mockRetirementHistory.length > 0 ? (
          <div className="space-y-3">
            {mockRetirementHistory.map((retirement) => (
              <div
                key={retirement.id}
                className="bg-white/5 rounded-lg p-4 flex flex-col md:flex-row md:items-center justify-between gap-4"
              >
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-white">{retirement.amount} tonnes</span>
                    <span className="text-white/50">•</span>
                    <span className="text-white/70">{retirement.projectName}</span>
                  </div>
                  <div className="text-white/50 text-sm mt-1">
                    {retirement.message}
                  </div>
                  <div className="text-white/40 text-xs mt-1">
                    {retirement.date} • Proof Token #{retirement.proofTokenId}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <a
                    href={`https://basescan.org/tx/${retirement.txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn-secondary text-sm py-2 px-3 flex items-center gap-1"
                  >
                    <FileText size={14} />
                    View Tx
                    <ExternalLink size={12} />
                  </a>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8">
            <Leaf className="w-12 h-12 text-white/20 mx-auto mb-3" />
            <p className="text-white/50">No retirements yet. Start by retiring your first credits!</p>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="glass-card p-4 text-center">
          <div className="text-2xl font-bold text-green-400">2.6</div>
          <div className="text-white/60 text-sm">Total Retired (tonnes)</div>
        </div>
        <div className="glass-card p-4 text-center">
          <div className="text-2xl font-bold text-green-400">2</div>
          <div className="text-white/60 text-sm">Retirement Events</div>
        </div>
        <div className="glass-card p-4 text-center">
          <div className="text-2xl font-bold text-green-400">$0.002</div>
          <div className="text-white/60 text-sm">Total Gas Spent</div>
        </div>
      </div>
    </div>
  )
}
