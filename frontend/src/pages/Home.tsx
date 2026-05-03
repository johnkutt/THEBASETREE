import { useEffect, useState } from 'react'
import { Zap, Clock, Leaf, Shield, Globe, TrendingUp } from 'lucide-react'

function StatCard({ icon: Icon, value, label, suffix = '' }: { icon: any, value: number, label: string, suffix?: string }) {
  const [count, setCount] = useState(0)
  
  useEffect(() => {
    const duration = 2000
    const steps = 60
    const increment = value / steps
    let current = 0
    
    const timer = setInterval(() => {
      current += increment
      if (current >= value) {
        setCount(value)
        clearInterval(timer)
      } else {
        setCount(Math.floor(current))
      }
    }, duration / steps)
    
    return () => clearInterval(timer)
  }, [value])
  
  return (
    <div className="glass-card p-6 text-center">
      <Icon className="w-8 h-8 text-green-400 mx-auto mb-3" />
      <div className="text-3xl font-bold text-white mb-1">
        {count.toLocaleString()}{suffix}
      </div>
      <div className="text-white/60 text-sm">{label}</div>
    </div>
  )
}

function FeatureCard({ icon: Icon, title, description }: { icon: any, title: string, description: string }) {
  return (
    <div className="glass-card p-6 hover:bg-white/15 transition-all">
      <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center mb-4">
        <Icon className="w-6 h-6 text-green-400" />
      </div>
      <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
      <p className="text-white/70 text-sm leading-relaxed">{description}</p>
    </div>
  )
}

export default function Home() {
  return (
    <div className="space-y-16">
      <section className="text-center py-12">
        <div className="animate-float mb-8">
          <div className="w-32 h-32 bg-gradient-to-br from-green-400 to-emerald-600 rounded-full mx-auto flex items-center justify-center shadow-2xl">
            <Leaf className="w-16 h-16 text-white" />
          </div>
        </div>
        
        <h1 className="text-5xl md:text-6xl font-bold mb-6">
          <span className="text-gradient">TheBaseTree</span>
        </h1>
        
        <p className="text-xl text-white/80 max-w-2xl mx-auto mb-8">
          The green credit marketplace and sustainability layer built natively on Base Chain.
          Sub-cent micro-offsets. 200ms settlements. AI agent compliance.
        </p>
        
        <div className="flex flex-wrap justify-center gap-4">
          <a href="/marketplace" className="btn-primary">
            Browse Marketplace
          </a>
          <a href="/retirement" className="btn-secondary">
            Retire Credits
          </a>
        </div>
      </section>

      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Leaf} value={1450000} label="Tonnes Offset" suffix="+" />
        <StatCard icon={Globe} value={89} label="Countries Active" />
        <StatCard icon={Zap} value={200} label="Settlement Time" suffix="ms" />
        <StatCard icon={TrendingUp} value={3400} label="Active Projects" />
      </section>

      <section>
        <h2 className="text-3xl font-bold text-white text-center mb-10">
          Why TheBaseTree on <span className="text-gradient">Base Chain</span>?
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <FeatureCard
            icon={Zap}
            title="Flashblocks = 200ms Settlement"
            description="Carbon credit retirements settle before you look up from your screen. Real-time ESG dashboard updates for corporate compliance."
          />
          <FeatureCard
            icon={Leaf}
            title="Sub-cent Micro-Offsets"
            description="Offset your single Uber ride (2.1kg CO2, ~$0.003) for gas fees of $0.001. The micro-offset economy, finally viable."
          />
          <FeatureCard
            icon={Shield}
            title="Native AA = AI Compliance Agents"
            description="Deploy 'Green Agents' that automatically purchase and retire offsets based on real-time emissions data. Zero human approval per transaction."
          />
          <FeatureCard
            icon={Clock}
            title="Instant Audit Trails"
            description="On-chain retirement proofs with cryptographic verification. Every offset is permanently recorded and verifiable."
          />
          <FeatureCard
            icon={Globe}
            title="Base ↔ Solana Bridge"
            description="Green credits accessible to Solana's massive DeFi ecosystem. Global reach with Base's security model."
          />
          <FeatureCard
            icon={TrendingUp}
            title="Transparent Pricing"
            description="No brokers. No minimums. Direct peer-to-peer trading with transparent on-chain price discovery."
          />
        </div>
      </section>

      <section className="glass-card p-8">
        <div className="flex flex-col md:flex-row items-center gap-8">
          <div className="flex-1">
            <h2 className="text-2xl font-bold text-white mb-4">
              Built for Enterprises & Individuals Alike
            </h2>
            <p className="text-white/70 mb-6">
              Whether you're a Fortune 500 company automating supply chain offsets or 
              an individual offsetting your daily commute, TheBaseTree provides the 
              infrastructure for sustainable finance at any scale.
            </p>
            <div className="flex gap-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">$0.001</div>
                <div className="text-sm text-white/60">Gas per transaction</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">0.001</div>
                <div className="text-sm text-white/60">Minimum credit unit</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">12+ hrs</div>
                <div className="text-sm text-white/60">Time saved vs trad markets</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="text-center">
        <h2 className="text-3xl font-bold text-white mb-6">Ready to Go Green?</h2>
        <p className="text-white/70 mb-8 max-w-xl mx-auto">
          Join the sustainable finance revolution. Start offsetting your carbon footprint 
          with sub-cent fees and 200ms settlements.
        </p>
        <a href="/marketplace" className="btn-primary inline-block">
          Enter TheBaseTree
        </a>
      </section>
    </div>
  )
}
