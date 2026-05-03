import { useState } from 'react'
import { 
  Shield, 
  Bot, 
  Settings, 
  AlertCircle,
  CheckCircle,
  Play,
  Pause,
  DollarSign,
  Clock
} from 'lucide-react'

interface AgentPolicy {
  weeklySpendLimit: number
  maxSinglePurchase: number
  autoRetire: boolean
  active: boolean
}

function AgentCard({ 
  policy, 
  onUpdate, 
  isActive 
}: { 
  policy: AgentPolicy
  onUpdate: (p: AgentPolicy) => void
  isActive: boolean 
}) {
  const [editing, setEditing] = useState(false)
  const [tempPolicy, setTempPolicy] = useState(policy)

  const handleSave = () => {
    onUpdate(tempPolicy)
    setEditing(false)
  }

  return (
    <div className="glass-card p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
            isActive ? 'bg-green-500/20' : 'bg-white/10'
          }`}>
            <Bot className={`w-6 h-6 ${isActive ? 'text-green-400' : 'text-white/50'}`} />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white">Green Compliance Agent</h3>
            <p className="text-white/50 text-sm">
              {isActive ? 'Active and monitoring' : 'Agent paused'}
            </p>
          </div>
        </div>
        <div className={`px-3 py-1 rounded-full text-sm ${
          isActive ? 'bg-green-500/20 text-green-400' : 'bg-white/10 text-white/50'
        }`}>
          {isActive ? 'Running' : 'Paused'}
        </div>
      </div>

      {editing ? (
        <div className="space-y-4">
          <div>
            <label className="block text-white/70 text-sm mb-2">Weekly Spend Limit (USDC)</label>
            <input
              type="number"
              value={tempPolicy.weeklySpendLimit}
              onChange={(e) => setTempPolicy({ ...tempPolicy, weeklySpendLimit: Number(e.target.value) })}
              className="input-field w-full"
            />
          </div>
          <div>
            <label className="block text-white/70 text-sm mb-2">Max Single Purchase (USDC)</label>
            <input
              type="number"
              value={tempPolicy.maxSinglePurchase}
              onChange={(e) => setTempPolicy({ ...tempPolicy, maxSinglePurchase: Number(e.target.value) })}
              className="input-field w-full"
            />
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={tempPolicy.autoRetire}
              onChange={(e) => setTempPolicy({ ...tempPolicy, autoRetire: e.target.checked })}
              className="w-4 h-4 rounded border-white/30"
            />
            <span className="text-white/70 text-sm">Auto-retire purchased credits</span>
          </div>
          <div className="flex gap-3">
            <button onClick={handleSave} className="btn-primary flex-1">Save Changes</button>
            <button onClick={() => setEditing(false)} className="btn-secondary">Cancel</button>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white/5 rounded-lg p-4">
              <div className="flex items-center gap-2 text-white/60 text-sm mb-1">
                <DollarSign size={14} />
                Weekly Limit
              </div>
              <div className="text-white font-semibold">{policy.weeklySpendLimit} USDC</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4">
              <div className="flex items-center gap-2 text-white/60 text-sm mb-1">
                <DollarSign size={14} />
                Max Single Buy
              </div>
              <div className="text-white font-semibold">{policy.maxSinglePurchase} USDC</div>
            </div>
          </div>
          
          <div className="flex items-center gap-3 p-3 bg-white/5 rounded-lg">
            {policy.autoRetire ? (
              <CheckCircle className="w-5 h-5 text-green-400" />
            ) : (
              <AlertCircle className="w-5 h-5 text-yellow-400" />
            )}
            <span className="text-white/80">
              {policy.autoRetire ? 'Auto-retirement enabled' : 'Auto-retirement disabled'}
            </span>
          </div>

          <div className="flex gap-3">
            <button onClick={() => setEditing(true)} className="btn-secondary flex-1 flex items-center justify-center gap-2">
              <Settings size={16} />
              Configure
            </button>
            <button className={`flex-1 flex items-center justify-center gap-2 py-3 px-6 rounded-lg font-semibold transition-all ${
              isActive 
                ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30' 
                : 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
            }`}>
              {isActive ? <Pause size={16} /> : <Play size={16} />}
              {isActive ? 'Pause' : 'Start'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function Compliance() {
  const [agentPolicy, setAgentPolicy] = useState<AgentPolicy>({
    weeklySpendLimit: 500,
    maxSinglePurchase: 100,
    autoRetire: true,
    active: true
  })

  const mockEmissionsData = [
    { date: '2024-03-15', source: 'Logistics Fleet A', co2: 450, offset: 450, status: 'offset' },
    { date: '2024-03-14', source: 'Office Energy', co2: 120, offset: 0, status: 'pending' },
    { date: '2024-03-13', source: 'Business Travel', co2: 280, offset: 300, status: 'offset' },
    { date: '2024-03-12', source: 'Manufacturing', co2: 890, offset: 0, status: 'pending' },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2 flex items-center gap-3">
          <Shield className="w-8 h-8 text-green-400" />
          Enterprise Compliance
        </h1>
        <p className="text-white/60">
          AI-powered automated carbon offsetting for ESG reporting
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <AgentCard 
            policy={agentPolicy} 
            onUpdate={setAgentPolicy}
            isActive={agentPolicy.active}
          />
        </div>

        <div className="glass-card p-6">
          <h3 className="text-lg font-semibold text-white mb-4">Agent Stats</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-white/60">Credits Purchased</span>
              <span className="text-white font-semibold">1,240 tonnes</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/60">Credits Retired</span>
              <span className="text-green-400 font-semibold">1,185 tonnes</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/60">Total Spent</span>
              <span className="text-white font-semibold">$4,250 USDC</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/60">Transactions</span>
              <span className="text-white font-semibold">89</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-white/60">Avg Gas Cost</span>
              <span className="text-white font-semibold">$0.001</span>
            </div>
          </div>
        </div>
      </div>

      <div className="glass-card p-6">
        <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          <Clock className="w-5 h-5 text-green-400" />
          Real-time Emissions Monitor
        </h3>
        
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="text-left text-white/60 text-sm border-b border-white/10">
                <th className="pb-3 font-medium">Date</th>
                <th className="pb-3 font-medium">Source</th>
                <th className="pb-3 font-medium text-right">CO2 Emitted</th>
                <th className="pb-3 font-medium text-right">CO2 Offset</th>
                <th className="pb-3 font-medium text-center">Status</th>
              </tr>
            </thead>
            <tbody>
              {mockEmissionsData.map((item, idx) => (
                <tr key={idx} className="border-b border-white/5 last:border-0">
                  <td className="py-4 text-white/80">{item.date}</td>
                  <td className="py-4 text-white">{item.source}</td>
                  <td className="py-4 text-right text-white">{item.co2} kg</td>
                  <td className="py-4 text-right text-green-400">{item.offset} kg</td>
                  <td className="py-4 text-center">
                    <span className={`px-3 py-1 rounded-full text-xs ${
                      item.status === 'offset' 
                        ? 'bg-green-500/20 text-green-400' 
                        : 'bg-yellow-500/20 text-yellow-400'
                    }`}>
                      {item.status === 'offset' ? 'Offset' : 'Pending'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="glass-card p-6">
        <h3 className="text-lg font-semibold text-white mb-4">ESG Report Generator</h3>
        <p className="text-white/70 mb-4">
          Generate regulatory-grade on-chain audit reports for EU CSRD, SEC climate disclosure, or India's ESG reporting.
        </p>
        <div className="flex flex-wrap gap-3">
          <button className="btn-secondary flex items-center gap-2">
            <Shield size={16} />
            Generate EU CSRD Report
          </button>
          <button className="btn-secondary flex items-center gap-2">
            <Shield size={16} />
            Generate SEC Report
          </button>
          <button className="btn-secondary flex items-center gap-2">
            <Shield size={16} />
            Generate BRSR Report
          </button>
        </div>
      </div>

      <div className="glass-card p-6 border-l-4 border-green-500">
        <h3 className="text-lg font-semibold text-white mb-3 flex items-center gap-2">
          <CheckCircle className="w-5 h-5 text-green-400" />
          Why Use TheBaseTree for Enterprise Compliance?
        </h3>
        <ul className="space-y-2 text-white/70">
          <li className="flex items-start gap-2">
            <span className="text-green-400 mt-1">•</span>
            <span><strong>Native Account Abstraction:</strong> Deploy "Green Agents" with session keys that auto-purchase and retire offsets based on real-time emissions data</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-green-400 mt-1">•</span>
            <span><strong>200ms Settlement:</strong> Your ESG dashboard updates in real-time with Flashblocks</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-green-400 mt-1">•</span>
            <span><strong>Cryptographic Audit Trail:</strong> Every offset has on-chain proof, permanently verifiable</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-green-400 mt-1">•</span>
            <span><strong>Sub-cent Costs:</strong> Even with thousands of micro-transactions, gas fees stay negligible</span>
          </li>
        </ul>
      </div>
    </div>
  )
}
