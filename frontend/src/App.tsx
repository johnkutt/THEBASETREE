import { Routes, Route, NavLink } from 'react-router-dom'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { BrowserRouter } from 'react-router-dom'
import { TreePine, Store, Leaf, BarChart3, Shield } from 'lucide-react'
import Home from './pages/Home'
import Marketplace from './pages/Marketplace'
import Retirement from './pages/Retirement'
import Dashboard from './pages/Dashboard'
import Compliance from './pages/Compliance'

function Navigation() {
  const navClass = ({ isActive }: { isActive: boolean }) =>
    `flex items-center gap-2 px-4 py-2 rounded-xl transition-all duration-300 ${
      isActive
        ? 'bg-base-blue/20 text-base-blue shadow-[0_0_10px_rgba(0,82,255,0.2)]'
        : 'text-white/60 hover:text-white hover:bg-white/5'
    }`

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-base-dark/80 backdrop-blur-xl border-b border-base-border shadow-lg shadow-black/20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-2 group cursor-pointer">
            <TreePine className="w-8 h-8 text-base-blue group-hover:text-neon-green transition-colors duration-300" />
            <span className="text-xl font-bold tracking-tight text-white group-hover:text-transparent group-hover:bg-clip-text group-hover:bg-gradient-to-r group-hover:from-base-blue group-hover:to-neon-green transition-all duration-300">TheBase<span className="text-base-blue">Tree</span></span>
          </div>
          
          <div className="hidden md:flex items-center gap-1">
            <NavLink to="/" className={navClass}>
              <TreePine size={18} />
              <span>Home</span>
            </NavLink>
            <NavLink to="/marketplace" className={navClass}>
              <Store size={18} />
              <span>Marketplace</span>
            </NavLink>
            <NavLink to="/retirement" className={navClass}>
              <Leaf size={18} />
              <span>Retire</span>
            </NavLink>
            <NavLink to="/compliance" className={navClass}>
              <Shield size={18} />
              <span>Compliance</span>
            </NavLink>
            <NavLink to="/dashboard" className={navClass}>
              <BarChart3 size={18} />
              <span>Dashboard</span>
            </NavLink>
          </div>

          <div className="flex items-center gap-4">
            <ConnectButton />
          </div>
        </div>
      </div>
    </nav>
  )
}

function AppContent() {
  return (
    <div className="min-h-screen">
      <Navigation />
      <main className="pt-20 pb-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/marketplace" element={<Marketplace />} />
          <Route path="/retirement" element={<Retirement />} />
          <Route path="/compliance" element={<Compliance />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
      </main>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AppContent />
    </BrowserRouter>
  )
}
