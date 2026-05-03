import { Link } from 'react-router-dom';
import { Leaf } from 'lucide-react';
import { WalletButton } from './WalletButton';

export function Header() {
  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2">
          <Leaf className="w-6 h-6 text-green-500" />
          <span className="font-bold text-xl text-gray-900">TheBaseTree</span>
        </Link>
        
        <nav className="hidden md:flex items-center gap-6">
          <Link to="/marketplace" className="text-gray-600 hover:text-green-600">Market</Link>
          <Link to="/retirement" className="text-gray-600 hover:text-green-600">Retire</Link>
          <Link to="/dashboard" className="text-gray-600 hover:text-green-600">Dashboard</Link>
        </nav>
        
        <WalletButton />
      </div>
    </header>
  );
}
