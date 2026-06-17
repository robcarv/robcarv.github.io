import { getHealth, type NodeStatus } from '@/lib/health'

function StatusDot({ status }: { status: 'ok' | 'warn' | 'fail' }) {
  const colors = {
    ok: 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]',
    warn: 'bg-yellow-500 shadow-[0_0_8px_rgba(234,179,8,0.5)]',
    fail: 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.5)]',
  }
  return <span className={`inline-block w-3 h-3 rounded-full ${colors[status]}`} />
}

function OverallBadge({ status }: { status: 'ok' | 'warn' | 'fail' }) {
  const styles = {
    ok: 'bg-green-900/50 text-green-300 border-green-700',
    warn: 'bg-yellow-900/50 text-yellow-300 border-yellow-700',
    fail: 'bg-red-900/50 text-red-300 border-red-700',
  }
  const labels = { ok: 'OK', warn: 'Fair', fail: 'Poor' }
  return (
    <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border ${styles[status]}`}>
      <StatusDot status={status} />
      {labels[status]}
    </span>
  )
}

function MetricBar({ label, value, pct }: { label: string; value: string; pct?: number }) {
  return (
    <div>
      <div className="flex justify-between text-xs mb-0.5">
        <span className="text-gray-500">{label}</span>
        <span className="text-gray-300 font-mono text-[11px]">{value}</span>
      </div>
      {pct !== undefined && (
        <div className="w-full h-1 bg-gray-800 rounded-full overflow-hidden">
          <div
            className={`h-full rounded-full transition-all ${
              pct > 90 ? 'bg-red-500' : pct > 75 ? 'bg-yellow-500' : 'bg-blue-500'
            }`}
            style={{ width: `${Math.min(pct, 100)}%` }}
          />
        </div>
      )}
    </div>
  )
}

export default async function HomeLabStatus() {
  const health = await getHealth()
  const nodes = health.nodes

  return (
    <section className="py-16 px-4" id="homelab">
      <div className="max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-white">Homelab Status</h2>
            <p className="text-xs text-gray-500 mt-1">
              Updated: {health.updated} &middot; Data via Glances API
            </p>
          </div>
          <OverallBadge status={health.status} />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {['Pi501', 'Pi5', 'Pi4'].map((nodeName) => {
            const node: NodeStatus | undefined = nodes[nodeName]
            if (!node) {
              return (
                <div key={nodeName} className="rounded-xl border border-gray-800 bg-gray-900/50 p-5">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-sm font-semibold text-gray-400">{nodeName}</span>
                    <StatusDot status="fail" />
                  </div>
                  <p className="text-xs text-gray-600">Offline</p>
                </div>
              )
            }

            const cpuPct = parseFloat(node.cpu)
            const ramPct = parseFloat(node.ram)

            return (
              <div
                key={nodeName}
                className="rounded-xl border border-gray-800 bg-gray-900/50 p-5 hover:border-gray-700 transition-colors"
              >
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <span className="text-sm font-semibold text-white">{nodeName}</span>
                    <p className="text-[10px] text-gray-600 mt-0.5">{node.services}</p>
                  </div>
                  <StatusDot status={node.status} />
                </div>

                <div className="space-y-3">
                  <MetricBar label="CPU" value={node.cpu} pct={cpuPct} />
                  <MetricBar label="RAM" value={`${node.ram} (${node.ram_gb}/${node.ram_total})`} pct={ramPct} />
                  
                  <div className="flex justify-between text-xs">
                    <span className="text-gray-500">Uptime</span>
                    <span className="text-gray-300 font-mono text-[11px]">{node.uptime}</span>
                  </div>
                  <div className="flex justify-between text-xs">
                    <span className="text-gray-500">Load</span>
                    <span className="text-gray-300 font-mono text-[11px]">{node.load}</span>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
