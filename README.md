# Robert Carvalho · Portfolio

> **URL:** https://robcarv.github.io
> **Stack:** HTML5 + CSS3 + Vanilla JS — zero dependencies, zero build step
> **Data sources:** `health.json` (Hermes cron) · `news.json` (NewsBot) · `experience.json` (static, editable)

---

## Repository Files

```
robcarv.github.io/
  index.html           # Página principal (EN)
  index-pt.html        # Página principal (PT-BR)
  homelab.html         # Dashboard completo de métricas
  homelab-pt.html      # Dashboard (PT-BR)
  health.json          # Dados dos Pis + rádio (atualizado a cada 60min)
  news.json            # Feed de notícias (atualizado pelo NewsBot)
  experience.json      # Experiência profissional (editável manualmente)
  avatar.svg           # Avatar
  .gitignore           # Bloqueia *.json exceto os 3 acima
  README.md
```

---

## Data Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│                     Hermes Cron (Pi501)                      │
│                                                              │
│  portfolio-health-update (every 60m)                         │
│  └── portfolio_health_push.sh                                │
│      ├── Glances API (porta 61208) → CPU, RAM, swap, load,  │
│      │   disks, network, processes, temp (13 endpoints/Pi)   │
│      ├── SSH docker ps → container names (filtro NSFW)       │
│      ├── AzuraCast API → now playing, listeners, history     │
│      ├── Copia news.json + avatar.svg                        │
│      └── git push → GitHub Pages                             │
│                                                              │
│  homelab-backup-all (every 24h)                              │
│  └── backup_pipeline.sh                                      │
│      ├── Git push: news_colletector, portfolio-v2            │
│      ├── Rsync: Pi5 scripts, Pi4 home                        │
│      └── Cleanup: backups >14d                               │
│                                                              │
│  homelab-cleanup (every 24h)                                 │
│  └── cleanup_all_nodes.sh                                    │
│      └── Docker system prune + logs >7d (3 Pis)              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                     NewsBot (Pi501, every 6h)                 │
│                                                              │
│  run_newsbot.sh                                               │
│  └── RSS feeds → AI summarizer → news.json                   │
│      └── sync_portfolio.sh → git push                        │
└──────────────────────────────────────────────────────────────┘
```

---

## JSON Schemas

### health.json

```json
{
  "updated": "2026-06-19 12:40",
  "status": "ok",
  "nodes": {
    "Pi501": {
      "status": "ok",
      "cpu": {"total": 5.6, "user": 4.6, "system": 1.0, "idle": 93.5, "iowait": 0.0},
      "ram": {"used_gb": 3.2, "total_gb": 7.9, "percent": 40.9, "available_gb": 4.7},
      "swap": {"used_mb": 199.9, "total_mb": 200.0, "percent": 100.0},
      "load": {"1min": 4.2, "5min": 3.8, "15min": 5.1, "cores": 4},
      "disks": [{"mount": "/", "device": "mmcblk0p2", "size_gb": 116.7, "used_gb": 42.8, "free_gb": 67.9, "percent": 36.7}],
      "disk_io": {"read_mb": 0.8, "write_mb": 22.6},
      "temperature_c": 51,
      "network": {"eth0": {"sent_mb": 0.0, "recv_mb": 0.0, "speed_kbps": 10240.0}},
      "processes": {"total": 228, "running": 0, "sleeping": 144, "threads": 882},
      "containers": [{"name": "gallery backend", "status": "Up 3 hours"}, ...],
      "container_count": 17,
      "uptime": "8 days, 15:02:09",
      "services": "Gallery, Dashy, Hermes, NewsBot"
    }
  },
  "radio": {
    "station": "dublincalling",
    "is_online": true,
    "is_live": false,
    "now_playing": {"artist": "...", "title": "...", "album": "...", "genre": "..."},
    "playing_next": {"artist": "...", "title": "..."},
    "listeners": 1,
    "listen_url": "https://dublincalling.duckdns.org/listen/dublincalling/radio.mp3",
    "history": [...]
  }
}
```

### experience.json

```json
[
  {
    "role": "QA Automation Engineer",
    "company": "IBM",
    "period": "Oct 2021 — Present",
    "items": ["item 1", "item 2", "item 3"]
  }
]
```

Editável manualmente — adicionar/remover experiências é só editar o array.

### news.json (NewsBot)

```json
{
  "updated": "2026-06-19T12:00:00Z",
  "items": [
    {
      "title": "...",
      "source": "The Guardian US",
      "link": "https://...",
      "summary": "...",
      "date": "2026-06-19T10:00:00Z"
    }
  ]
}
```

---

## Arquitetura JavaScript

### index.html

```
INIT
  ├── loadHealth()       → fetch health.json → renderHomelab() + renderRadio() + updateNavRadio()
  ├── loadNews()         → fetch news.json → renderNewsFilters() + renderNews()
  ├── loadExperience()   → fetch experience.json → renderExperience()
  ├── updateTicker()     → bottom scroll bar (radio + news links)
  └── updateFooterStatus() → status line no footer

LIVE POLL (every 30s)
  └── pollRadioLive()    → fetch AzuraCast API → renderRadio() + updateNavRadio()

REFRESH (every 60s, user toggle)
  └── refreshAll()       → reload health + news + experience + ticker + footer

PLAYER
  ├── toggleRadio()      → play/pause HTML5 <audio>
  └── stopRadio()        → hard stop

ACCORDION
  └── renderExperience() → dynamic accordion from experience.json
```

### homelab.html

```
INIT
  ├── loadData()         → fetch health.json
  ├── render()           → dashboard completo (gauges, tabelas)
  └── renderNavRadio()   → radio bar na navbar

LIVE POLL (every 30s)
  └── pollRadio()        → fetch AzuraCast API → renderNavRadio()

REFRESH (every 60s)
  └── refreshAll()       → reload + render + renderNavRadio
```

---

## CSS Design Tokens

```css
--bg: #0a0a0f        /* Fundo principal */
--bg-card: #111118    /* Cards */
--border: #1e1e2a     /* Bordas */
--text: #e4e4eb       /* Texto principal */
--muted: #8888a0      /* Texto secundário */
--accent: #6366f1     /* Indigo — links, botões */
--accent2: #a855f7    /* Roxo — gradientes */
--green: #22c55e      /* OK */
--yellow: #eab308     /* Warning */
--red: #ef4444        /* Error / playing radio */
```

---

## Security

| Verificação | Status |
|-------------|--------|
| Senhas / tokens no repo | ✅ Nenhum |
| IPs privados | ✅ 131 artefatos Next.js removidos |
| Conteúdo adulto/NSFW | ✅ Filtro no script de coleta |
| Emails expostos | ✅ Nenhum |
| `.gitignore` bloqueia `*.json` | ✅ Exceto health/news/experience |
| Container names filtrados | ✅ nhentai, hentai, whisparr, etc. |

---

## Deploy

```bash
# Editar qualquer arquivo
vim index.html

# Deploy
git add -A && git commit -m "descrição" && git push origin main

# GitHub Pages auto-deploy em ~60 segundos
```

**Sem build, sem CI/CD, sem dependências.**
