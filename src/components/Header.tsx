'use client'

import Link from 'next/link'
import { useState } from 'react'

export default function Header() {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-gray-950/90 backdrop-blur border-b border-gray-800">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="text-xl font-bold text-white tracking-tight">
            Robert Carvalho
          </Link>

          {/* Desktop nav */}
          <nav className="hidden md:flex items-center gap-6">
            <Link href="/" className="text-sm text-gray-300 hover:text-white transition-colors">
              Home
            </Link>
            <Link href="/homelab" className="text-sm text-gray-300 hover:text-white transition-colors">
              Homelab
            </Link>

            {/* Language toggle */}
            <div className="flex items-center gap-1 ml-4 border-l border-gray-700 pl-4">
              <Link
                href="/"
                className="text-xs font-medium px-2 py-1 rounded text-white bg-gray-700 transition-colors"
              >
                EN
              </Link>
              <span className="text-gray-600 text-xs">|</span>
              <Link
                href="/pt"
                className="text-xs font-medium px-2 py-1 rounded text-gray-400 hover:text-white hover:bg-gray-700 transition-colors"
              >
                PT
              </Link>
            </div>
          </nav>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileOpen(!mobileOpen)}
            className="md:hidden p-2 text-gray-300 hover:text-white transition-colors"
            aria-label="Toggle menu"
          >
            {mobileOpen ? (
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            ) : (
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <div className="md:hidden border-t border-gray-800 bg-gray-950/95 backdrop-blur">
          <div className="px-4 py-4 space-y-3">
            <Link
              href="/"
              className="block text-sm text-gray-300 hover:text-white transition-colors"
              onClick={() => setMobileOpen(false)}
            >
              Home
            </Link>
            <Link
              href="/homelab"
              className="block text-sm text-gray-300 hover:text-white transition-colors"
              onClick={() => setMobileOpen(false)}
            >
              Homelab
            </Link>
            <div className="flex items-center gap-2 pt-2 border-t border-gray-800">
              <Link
                href="/"
                className="text-xs font-medium px-2 py-1 rounded text-white bg-gray-700"
                onClick={() => setMobileOpen(false)}
              >
                EN
              </Link>
              <span className="text-gray-600 text-xs">|</span>
              <Link
                href="/pt"
                className="text-xs font-medium px-2 py-1 rounded text-gray-400 hover:text-white hover:bg-gray-700 transition-colors"
                onClick={() => setMobileOpen(false)}
              >
                PT
              </Link>
            </div>
          </div>
        </div>
      )}
    </header>
  )
}
