import { useState } from 'react'
import { useAccount } from 'wagmi'
import { 
  Leaf, 
  TrendingUp, 
  Award, 
  Clock, 
  Download, 
  FileText,
  ExternalLink,
  Filter
} from 'lucide-react'

interface RetirementRecord {
  id: number
  date: string
  amount: number
  project: string
  location: string
  txHash: string
  proofTokenId: number
  co2Offset: number
}

function StatCard({ 
  icon: Icon, 
  title, 
  value, 
  trend,
  suffix = '' 
}: { 
  icon: any
  title: string
  value: string
  trend?: string
  suffix?: string 
}) {
  return (
    <div className="glass-card p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-white/60 text-sm mb-1">{title}</p>
          <p className="text-2xl font-bold text-white">{value}{suffix}</p>
          {trend && (
            <p className="text-green-400 text-sm flex items-center gap-1 mt-1">
              <TrendingUp size={14} />
              {trend}
            </p>
          )}
        </div>
        <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center">
          <Icon className="w-5 h-5 text-green-400" />
        </div>
      </div>
    </div>
  )
}

export default function Dashboard() {
  const { address, isConnected } = useAccount()
  const [timeRange, setTimeRange] = useState('all')
  
  const mockRetirements: RetirementRecord[] = [
    {
      id: 1,
      date: '2024-03-15',
      amount: 0.5,
      project: 'Kerala Reforestation Project',
      location: 'India',
      txHash: '0xabc123...',
      proofTokenId: 42,
      co2Offset: 500
    },
    {
      id: 2,
      date: '2024-03-10',
      amount: 2.1,
      project: 'US Methane Capture',
      location: 'USA',
      txHash: '0xdef456...',
      proofTokenId: 38,
      co2Offset: 2100
    },
    {
      id: 3,
      date: '2024-02-28',
      amount: 1.0,
      project: 'Amazon REDD+',
      location: 'Brazil',
      txHash: '0xghi789...',
      proofTokenId: 25,
      co2Offset: 1000
    },
    {
      id: 4,
      date: '2024-02-15',
      amount: 0.25,
      project: 'Kenya Clean Cookstoves',
      location: 'Kenya',
      txHash: '0xjkl012...',
      proofTokenId: 18,
      co2Offset: 250
    }
  ]

  const totalOffset = mockRetirements.reduce((acc, r) => acc + r.co2Offset, 0)
  const totalRetirements = mockRetirements.length
  const avgPerRetirement = totalOffset / totalRetirements

  const generateReport = () => {
    const reportData = {
      address,
      generatedAt: new Date().toISOString(),
      summary: {
        totalRetirements,
        totalOffset,
        avgPerRetirement
      },
      retirements: mockRetirements
    }
    
    const blob = new Blob([JSON.stringify(reportData, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `thebasetree-report-${address?.slice(0, 6)}-${Date.now()}.json`
    a.click()
  }

  if (!isConnected) {
    return (
      <div className="text-center py-20">
        <div className="w-20 h-20 bg-white/10 rounded-full flex items-center justify-center mx-auto mb-6">
          <Leaf className="w-10 h-10 text-white/50" />
        </div>
        <h2 className="text-2xl font-bold text-white mb-2">Connect Your Wallet</h2>
        <p className="text-white/60">Connect your wallet to view your sustainability dashboard</p>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white mb-1">Sustainability Dashboard</h1>
          <p className="text-white/60">Track your carbon offset journey</p>
        </div>
        <div className="flex gap-3">
          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value)}
            className="input-field"
          >
            <option value="all">All Time</option>
            <option value="year">This Year</option>
            <option value="month">This Month</option>
            <option value="week">This Week</option>
          </select>
          <button 
            onClick={generateReport}
            className="btn-secondary flex items-center gap-2"
          >
            <Download size={18} />
            Export
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          icon={Leaf}
          title="Total CO2 Offset"
          value={(totalOffset / 1000).toFixed(2)}
          suffix=" tonnes"
          trend="+12% from last month"
        />
        <StatCard
          icon={Award}
          title="Retirements Made"
          value={totalRetirements.toString()}
          trend="3 this month"
        />
        <StatCard
          icon={TrendingUp}
          title="Avg per Retirement"
          value={(avgPerRetirement / 1000).toFixed(2)}
          suffix=" tonnes"
        />
        <StatCard
          icon={Clock}
          title="Transactions"
          value={totalRetirements.toString()}
          suffix=" total"
        />
      </div>

      <div className="glass-card p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-white flex items-center gap-2">
            <FileText className="w-5 h-5 text-green-400" />
            Retirement History
          </h3>
          <div className="flex items-center gap-2 text-sm text-white/60">
            <Filter size={16} />
            <span>Last 4 retirements</span>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="text-left text-white/60 text-sm border-b border-white/10">
                <th className="pb-3 font-medium">Date</th>
                <th className="pb-3 font-medium">Project</th>
                <th className="pb-3 font-medium">Location</th>
                <th className="pb-3 font-medium text-right">Amount</th>
                <th className="pb-3 font-medium text-right">CO2 Offset</th>
                <th className="pb-3 font-medium text-center">Proof</th>
              </tr>
            </thead>
            <tbody>
              {mockRetirements.map((r) => (
                <tr key={r.id} className="border-b border-white/5 last:border-0">
                  <td className="py-4 text-white/80">{r.date}</td>
                  <td className="py-4 text-white font-medium">{r.project}</td>
                  <td className="py-4 text-white/60">{r.location}</td>
                  <td className="py-4 text-right text-white">{r.amount} tonnes</td>
                  <td className="py-4 text-right text-green-400">{r.co2Offset.toLocaleString()} kg</td>
                  <td className="py-4 text-center">
                    <a
                      href={`https://basescan.org/tx/${r.txHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-green-400 hover:text-green-300 text-sm"
                    >
                      #{r.proofTokenId}
                      <ExternalLink size={12} />
                    </a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="glass-card p-6">
          <h3 className="text-lg font-semibold text-white mb-4">Impact Summary</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-white/70">Equivalent to planting</span>
              <span className="text-white font-semibold">{(totalOffset / 20).toFixed(0)} trees</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/70">Equivalent car miles offset</span>
              <span className="text-white font-semibold">{(totalOffset * 2.5).toFixed(0)} miles</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/70">Average retirement size</span>
              <span className="text-white font-semibold">{(avgPerRetirement / 1000).toFixed(2)} tonnes</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/70">Total gas fees paid</span>
              <span className="text-white font-semibold">$0.004</span>
            </div>
          </div>
        </div>

        <div className="glass-card p-6">
          <h3 className="text-lg font-semibold text-white mb-4">Certifications</h3>
          <div className="space-y-3">
            <div className="flex items-center gap-3 p-3 bg-white/5 rounded-lg">
              <div className="w-10 h-10 bg-green-500/20 rounded-full flex items-center justify-center">
                <Award className="w-5 h-5 text-green-400" />
              </div>
              <div>
                <p className="text-white font-medium">Carbon Neutral Pioneer</p>
                <p className="text-white/50 text-sm">Offset 3+ tonnes this year</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-3 bg-white/5 rounded-lg">
              <div className="w-10 h-10 bg-blue-500/20 rounded-full flex items-center justify-center">
                <Leaf className="w-5 h-5 text-blue-400" />
              </div>
              <div>
                <p className="text-white font-medium">Base Tree Steward</p>
                <p className="text-white/50 text-sm">5+ retirements completed</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
