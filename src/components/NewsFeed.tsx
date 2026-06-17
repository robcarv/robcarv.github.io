import { getNews, getSourceColor } from '@/lib/news'
import Link from 'next/link'

function timeAgo(dateStr: string): string {
  const now = Date.now()
  const then = new Date(dateStr).getTime()
  const diffMs = now - then
  const diffMins = Math.floor(diffMs / 60000)
  if (diffMins < 1) return 'just now'
  if (diffMins < 60) return `${diffMins}m ago`
  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `${diffHours}h ago`
  const diffDays = Math.floor(diffHours / 24)
  return `${diffDays}d ago`
}

export default async function NewsFeed({
  searchParams,
}: {
  searchParams?: Promise<{ source?: string }>
}) {
  const data = await getNews()
  const params = await searchParams
  const activeSource = params?.source || 'All'

  const sources = ['All', ...new Set(data.items.map((item) => item.source))]

  const filteredItems =
    activeSource === 'All'
      ? data.items
      : data.items.filter((item) => item.source === activeSource)

  return (
    <section className="py-16 px-4">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-2xl font-bold text-white mb-6">News Feed</h2>

        {/* Source filter buttons */}
        <div className="flex flex-wrap gap-2 mb-8">
          {sources.map((source) => {
            const isActive = source === activeSource
            return (
              <Link
                key={source}
                href={source === 'All' ? '/#news' : `/?source=${source}#news`}
                className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
                  isActive
                    ? 'bg-gray-700 text-white'
                    : 'bg-gray-900 text-gray-400 hover:bg-gray-800 hover:text-gray-200'
                }`}
              >
                {source}
              </Link>
            )
          })}
        </div>

        {/* Article grid */}
        {filteredItems.length === 0 ? (
          <p className="text-gray-500 text-sm">No articles found.</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredItems.map((item, idx) => (
              <div
                key={`${item.url}-${idx}`}
                className="rounded-xl border border-gray-800 bg-gray-900/50 p-5 flex flex-col hover:border-gray-700 transition-colors"
              >
                {/* Source badge */}
                <span
                  className={`inline-flex self-start px-2.5 py-0.5 rounded-full text-xs font-medium text-white bg-gradient-to-r ${getSourceColor(item.source)} mb-3`}
                >
                  {item.source}
                </span>

                {/* Title */}
                <h3 className="text-sm font-semibold text-gray-200 mb-3 line-clamp-2 leading-snug">
                  {item.title}
                </h3>

                {/* Published time */}
                <p className="text-xs text-gray-500 mt-auto mb-3">
                  {timeAgo(item.published)}
                </p>

                {/* Link */}
                <a
                  href={item.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-xs font-medium text-emerald-400 hover:text-emerald-300 transition-colors"
                >
                  Open article →
                </a>
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  )
}
