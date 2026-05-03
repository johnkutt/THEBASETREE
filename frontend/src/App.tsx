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
    `flex items-center gap-2 px-4 py-2 rounded-lg transition-all ${
      isActive
        ? 'bg-white/20 text-white'
        : 'text-white/70 hover:text-white hover:bg-white/10'
    }`

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-forest/80 backdrop-blur-lg border-b border-white/10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-2">
            <TreePine className="w-8 h-8 text-green-400" />
            <span className="text-xl font-bold text-gradient">TheBaseTree</span>
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
