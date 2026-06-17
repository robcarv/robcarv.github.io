import HomeLabStatus from "@/components/HomeLabStatus";
import Link from "next/link";

const piServices: Record<string, string[]> = {
  "Pi 1 — Primary (8GB)": [
    "Pi-hole (DNS ad-blocker)",
    "Unbound (recursive DNS resolver)",
    "Nginx Proxy Manager (reverse proxy)",
    "Homepage (dashboard)",
    "Uptime Kuma (monitoring)",
    "Watchtower (auto-updates)",
    "Dozzle (container logs)",
  ],
  "Pi 2 — Media & Automation (4GB)": [
    "Jellyfin (media server)",
    "Sonarr (TV series manager)",
    "Radarr (movie manager)",
    "Prowlarr (indexer manager)",
    "qBittorrent (torrent client)",
    "Home Assistant (smart home)",
    "Zigbee2MQTT (IoT bridge)",
  ],
  "Pi 3 — Developer Tools (4GB)": [
    "Gitea (Git server)",
    "Jenkins (CI/CD)",
    "Portainer (container management)",
    "MinIO (S3-compatible object storage)",
    "N8n (workflow automation)",
    "Vaultwarden (password manager)",
    "Syncthing (file sync)",
  ],
};

const storageVolumes = [
  { name: "TrueNAS Scale", role: "Primary NAS — Media, Backups, Documents", capacity: "16 TB usable (RAIDZ2)" },
  { name: "External USB HDD", role: "Cold backup — weekly rsync of critical data", capacity: "4 TB" },
  { name: "Pi SD Cards", role: "Boot + OS for each Pi", capacity: "32 GB each (Pi 1: 128 GB SSD)" },
];

const networkLayout = [
  "┌─────────────────────────────────────────────────────────┐",
  "│                    Internet (300 Mbps)                    │",
  "│                          │                               │",
  "│                    ISP Router (192.168.1.1)              │",
  "│                          │                               │",
  "│                ┌─────────┴──────────┐                   │",
  "│                │  Managed Switch     │                   │",
  "│                │  (TP-Link TL-SG108E)│                   │",
  "│                └─────────┬──────────┘                   │",
  "│           ┌──────────────┼──────────────┐               │",
  "│     ┌─────┴─────┐ ┌─────┴─────┐ ┌─────┴─────┐         │",
  "│     │  Pi 1     │ │  Pi 2     │ │  Pi 3     │          │",
  "│     │  8GB      │ │  4GB      │ │  4GB      │          │",
  "│     │  Services │ │  Media    │ │  Dev      │          │",
  "│     └───────────┘ └───────────┘ └───────────┘          │",
  "│                          │                               │",
  "│                ┌─────────┴──────────┐                   │",
  "│                │  TrueNAS Scale     │                   │",
  "│                │  16 TB RAIDZ2      │                   │",
  "│                │  192.168.1.100     │                   │",
  "│                └────────────────────┘                   │",
  "└─────────────────────────────────────────────────────────┘",
];

export default function HomelabPage() {
  return (
    <div className="max-w-6xl mx-auto px-4 py-8 space-y-16">
      {/* Header */}
      <section>
        <h1 className="text-4xl font-bold text-white mb-4">Homelab Architecture</h1>
        <p className="text-lg text-gray-400 max-w-3xl">
          My homelab runs on a cluster of 3 Raspberry Pis connected to a TrueNAS Scale storage server.
          Together they provide over 55 Docker services spanning DNS, media, automation, development,
          monitoring, and backups — all accessible via a single dashboard through Nginx Proxy Manager.
        </p>
      </section>

      {/* HomeLab Status */}
      <section>
        <h2 className="text-2xl font-semibold text-white mb-6">Live Status</h2>
        <HomeLabStatus />
      </section>

      {/* Architecture Diagram */}
      <section>
        <h2 className="text-2xl font-semibold text-white mb-6">Architecture Diagram</h2>
        <p className="text-gray-400 mb-4">
          View the full interactive architecture diagram&nbsp;
          <Link href="/homelab-architecture" className="text-blue-400 hover:text-blue-300 underline">
            here
          </Link>.
        </p>
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-6 overflow-x-auto">
          <pre className="text-sm text-gray-300 font-mono whitespace-pre">
            {networkLayout.join("\n")}
          </pre>
        </div>
      </section>

      {/* Docker Services */}
      <section>
        <h2 className="text-2xl font-semibold text-white mb-6">Docker Services</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {Object.entries(piServices).map(([pi, services]) => (
            <div
              key={pi}
              className="bg-gray-900 border border-gray-800 rounded-lg p-6"
            >
              <h3 className="text-lg font-medium text-white mb-4">{pi}</h3>
              <ul className="space-y-2">
                {services.map((service) => (
                  <li key={service} className="flex items-start gap-2 text-gray-400">
                    <span className="text-blue-400 mt-1">•</span>
                    <span>{service}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>

      {/* Storage */}
      <section>
        <h2 className="text-2xl font-semibold text-white mb-6">Storage</h2>
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-6">
          <div className="space-y-4">
            {storageVolumes.map((vol) => (
              <div
                key={vol.name}
                className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 last:pb-0 border-b border-gray-800 last:border-0"
              >
                <div>
                  <h3 className="text-white font-medium">{vol.name}</h3>
                  <p className="text-sm text-gray-400">{vol.role}</p>
                </div>
                <span className="text-blue-400 text-sm font-mono whitespace-nowrap">
                  {vol.capacity}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Network Diagram (raw text) */}
      <section>
        <h2 className="text-2xl font-semibold text-white mb-6">Network Topology</h2>
        <div className="bg-gray-900 border border-gray-800 rounded-lg p-6 overflow-x-auto">
          <pre className="text-sm text-gray-300 font-mono whitespace-pre leading-relaxed">
            {networkLayout.join("\n")}
          </pre>
        </div>
        <p className="text-gray-500 text-sm mt-4">
          All Pis are wired via Gigabit Ethernet through a managed switch. TrueNAS is connected
          via a dedicated 1 GbE link. WiFi is reserved for IoT devices and guest access only.
        </p>
      </section>
    </div>
  );
}
