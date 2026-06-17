'use client'

import { useEffect, useState } from 'react'
import type { RadioData } from '@/lib/health'

export default function RadioPlayer() {
  const [radio, setRadio] = useState<RadioData | null>(null)
  const [elapsed, setElapsed] = useState(0)

  useEffect(() => {
    async function fetchRadio() {
      try {
        const res = await fetch('/health.json')
        const data = await res.json()
        if (data.radio) {
          setRadio(data.radio)
          setElapsed(data.radio.now_playing?.elapsed || 0)
        }
      } catch {}
    }
    fetchRadio()
    const interval = setInterval(fetchRadio, 30000)
    const tick = setInterval(() => setElapsed((e) => e + 1), 1000)
    return () => { clearInterval(interval); clearInterval(tick) }
  }, [])

  if (!radio) {
    return (
      <section className="py-16 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="rounded-xl border border-gray-800 bg-gray-900/50 p-8 text-center">
            <p className="text-gray-500">Loading radio data...</p>
          </div>
        </div>
      </section>
    )
  }

  const np = radio.now_playing
  const progress = np.duration > 0 ? (elapsed / np.duration) * 100 : 0
  const remaining = np.duration - elapsed

  return (
    <section className="py-16 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-white">Dublin Calling</h2>
            <p className="text-xs text-gray-500 mt-1">
              {radio.listeners} listener{radio.listeners !== 1 ? 's' : ''} &middot;
              {radio.is_live ? ' LIVE' : ' Auto'} &middot;
              <span className={`ml-1 ${radio.is_online ? 'text-green-400' : 'text-red-400'}`}>
                {radio.is_online ? 'Online' : 'Offline'}
              </span>
            </p>
          </div>
        </div>

        <div className="rounded-xl border border-gray-700/50 bg-gray-900/50 backdrop-blur-xl p-6">
          <div className="flex items-center gap-6">
            {/* Album art */}
            {np.art ? (
              <img
                src={np.art}
                alt="Album Art"
                className="w-20 h-20 rounded-lg object-cover shadow-lg flex-shrink-0"
              />
            ) : (
              <div className="w-20 h-20 rounded-lg bg-gray-800 flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">🎵</span>
              </div>
            )}

            {/* Now playing info */}
            <div className="flex-1 min-w-0">
              <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Now Playing</p>
              <h3 className="text-lg font-semibold text-white truncate">{np.title}</h3>
              <p className="text-sm text-gray-400 truncate">{np.artist}</p>
              {np.album && <p className="text-xs text-gray-600 truncate">{np.album}</p>}

              {/* Progress bar */}
              <div className="mt-3">
                <div className="w-full h-1 bg-gray-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-blue-500 to-purple-500 rounded-full transition-all duration-1000"
                    style={{ width: `${Math.min(progress, 100)}%` }}
                  />
                </div>
                <div className="flex justify-between mt-1 text-[10px] text-gray-600">
                  <span>-{remaining > 0 ? `${Math.floor(remaining / 60)}:${String(remaining % 60).padStart(2, '0')}` : '0:00'}</span>
                  <span>{np.duration > 0 ? `${Math.floor(np.duration / 60)}:${String(np.duration % 60).padStart(2, '0')}` : ''}</span>
                </div>
              </div>
            </div>

            {/* Play button */}
            <a
              href={radio.listen_url || 'https://dublincalling.duckdns.org/public/dublincalling'}
              target="_blank"
              rel="noopener noreferrer"
              className="flex-shrink-0 bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-xl text-sm font-medium transition-colors"
            >
              ▶ Play
            </a>
          </div>

          {/* Playing next */}
          {radio.playing_next?.title && (
            <div className="mt-4 pt-4 border-t border-gray-800">
              <p className="text-[10px] text-gray-600 uppercase tracking-wider mb-1">Coming Up</p>
              <p className="text-sm text-gray-400">{radio.playing_next.artist} - {radio.playing_next.title}</p>
            </div>
          )}

          {/* Recently played */}
          {radio.history?.length > 0 && (
            <div className="mt-4 pt-4 border-t border-gray-800">
              <p className="text-[10px] text-gray-600 uppercase tracking-wider mb-2">Recently Played</p>
              <div className="space-y-1.5">
                {radio.history.slice(0, 3).map((h, i) => (
                  <div key={i} className="flex items-center gap-2 text-xs">
                    <span className="text-gray-600 w-16 flex-shrink-0">
                      {new Date(h.played_at * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                    <span className="text-gray-400 truncate">{h.artist} - {h.title}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  )
}
