import { Leaf } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-green-900 text-white py-8 mt-auto">
      <div className="container mx-auto px-4 text-center">
        <div className="flex items-center justify-center gap-2 mb-4">
          <Leaf className="w-5 h-5" />
          <span className="font-semibold">TheBaseTree</span>
        </div>
        <p className="text-green-200 text-sm">
          Building a sustainable future on Base Chain
        </p>
        <p className="text-green-300 text-xs mt-4">
          © 2024 TheBaseTree. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
