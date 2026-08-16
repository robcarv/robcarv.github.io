# Robert Carvalho · Portfolio

> **URL:** https://robcarv.github.io
> **Stack:** HTML5 + CSS3 + Vanilla JS — zero dependencies, zero build step
> **Data sources:** `health.json` (Hermes cron via Netdata) · `news.json` (NewsBot, com audio per-article) · `experience.json` (static, editable)

---

## Repository Files

```
robcarv.github.io/
  index.html           # Página principal (EN) — hero, homelab cards, news c/ audio, radio
  index-pt.html        # Página principal (PT-BR)
  homelab.html         # Dashboard: Architecture overview + gauges por node (Netdata)
  homelab-pt.html      # Dashboard (PT-BR)
  health.json          # 5 nodes (TrueNAS/Proxmox/VM100/VM200/VM400) + arch + radio
  news.json            # Feed de notícias c/ campo audio por artigo
  audio/               # MP3s per-article (~15 por run) — servidos pelo GitHub Pages
  experience.json      # Experiência profissional (editável manualmente)
  skills.json          # 27 skills (categorias + devicon)
  projects.json        # 6 projetos
  about.json           # Hero fields + bio
  expertises.json      # Cards de especialização
  avatar.svg           # Avatar
  photo.webp           # Foto de perfil
  .gitignore           # Bloqueia *.json exceto whitelist explícita
  README.md
```

---

## Data Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│            Hermes Cron (VM100 services-vm)                   │
│                                                              │
│  portfolio-health-update (12 * * * *, 60min)                 │
│  └── portfolio_health_push.sh                                │
│      ├── Netdata API (porta 19999) → 5 nodes:                │
│      │   TrueNAS .124 · Proxmox .116 · VM100 .127 ·          │
│      │   VM200 .130 · VM400 .132                             │
│      │   CPU, RAM, swap, load, disks, disk I/O, network,     │
│      │   processes, uptime, temperature                      │
│      ├── SSH docker ps (VMs) / qm list (Proxmox) →           │
│      │   containers (filtro sensível)                        │
│      ├── AzuraCast API → now playing, listeners, history     │
│      ├── Injeta audio URLs em news.json (match título → MP3) │
│      └── git push → GitHub Pages (merge, sem force)          │
│                                                              │
│  news-sync-push (3,33 * * * *, 30min) — safety net           │
│  └── news_sync_push.sh → git add news.json health.json audio/│
│                                                              │
│  homelab-newsbot (15 0,6,12,18 * * *)                        │
│  └── newsbot_trigger.sh → run_newsbot.sh                     │
│      ├── main.py: 42 RSS feeds → dedup → resumo →            │
│      │   TTS per-article (edge-tts) → data/audio/*.mp3       │
│      ├── export_run_json() → news_run.json (pt/en + audio)   │
│      ├── run_newsbot.sh: converte p/ news.json {items[]}     │
│      │   + copia MP3s p/ portfolio-html/audio/               │
│      └── sync_git.sh → sync_portfolio.sh (push)              │
└──────────────────────────────────────────────────────────────┘
```

**CRITICAL (2026-08-16):** o run_newsbot.sh ANTIGO sobrescrevia o news.json do portfolio
a partir do history.json SEM audio — o áudio nunca aparecia (0/15). Corrigido: o export
agora usa o news_run.json (que já tem audio do main.py) e copia os MP3s para
`portfolio-html/audio/` antes do push. Todos os scripts de push fazem `git add audio/`.

---

## JSON Schemas

### health.json (v2 — Netdata, 2026-08-16)

```json
{
  "updated": "2026-08-16 08:51",
  "status": "ok",
  "nodes": {
    "TrueNAS": {
      "role": "storage",
      "status": "ok",
      "cpu": {"total": 11.9, "user": 6.2, "system": 4.3, "iowait": 0.7, "idle": 88.1},
      "ram": {"used_gb": 7.1, "total_gb": 15.4, "percent": 46.1, "available_gb": 8.3},
      "swap": {"used_mb": 0, "total_mb": 0, "percent": 0},
      "load": {"1min": 1.1, "5min": 0.9, "15min": 0.8, "cores": 8},
      "disks": [{"mount": "/", "device": "/", "size_gb": 3903.8, "used_gb": 11.3, "free_gb": 3892.5, "percent": 0.3}],
      "disk_io": {"read_kib": 12.3, "write_kib": 45.6},
      "temperature_c": 27.8,
      "network": {"enp1s0": {"recv_kbps": 812.5, "sent_kbps": 161.3}},
      "processes": {"total": 243, "running": 1, "sleeping": 242, "threads": 0},
      "uptime": "23:45",
      "containers": [],
      "container_count": 0,
      "services": "TrueNAS SCALE — Storage (NVMe pool)"
    },
    "Proxmox": {"role": "hypervisor", "...": "..."},
    "VM100": {"role": "vm", "...": "..."},
    "VM200": {"role": "vm", "...": "..."},
    "VM400": {"role": "vm", "...": "..."}
  },
  "arch": {
    "storage": "TrueNAS SCALE",
    "hypervisor": "Proxmox VE",
    "vms": ["services", "security-utils", "azuracast-radio"],
    "monitoring": "Netdata (all nodes)"
  },
  "radio": {
    "station": "dublincalling",
    "is_online": true,
    "now_playing": {"artist": "...", "title": "...", "art": "https://..."},
    "playing_next": {"artist": "...", "title": "..."},
    "listeners": 0,
    "listen_url": "https://dublincalling.duckdns.org/listen/dublincalling/radio.mp3",
    "history": [...]
  }
}
```

Notas de formato:
- `network` usa `recv_kbps`/`sent_kbps` (taxa ao vivo do Netdata, não MB acumulado)
- `disk_io` usa `read_kib`/`write_kib` (KiB/s)
- Root LVM não gera chart disk_space no Netdata Ubuntu → fallback `df -k /` via SSH
- TrueNAS reporta o mesmo ZFS pool em vários mounts → dedupe por `size_gb`

### news.json (com audio)

```json
{
  "updated": "2026-08-16T06:16:52Z",
  "items": [
    {
      "title": "Alstom investe R$ 130 mi em 5 anos...",
      "source": "Folha de S.Paulo",
      "link": "https://...",
      "summary": "...",
      "date": "2026-08-16T06:00:00",
      "image": "",
      "audio": "audio/Alstom investe R_ 130 mi em 5 anos para ampliar pr.mp3"
    }
  ]
}
```

O campo `audio` é injetado por match de título → MP3 (`data/audio/{safe}.mp3` do NewsBot).
O index.html renderiza botão 🔊 Listen + `<audio>` por item com `toggleNewsAudio()`.

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

---

## Arquitetura JavaScript

### index.html

```
INIT
  ├── loadHealth()       → fetch health.json → renderHomelab() (5 nodes) + renderRadio() + updateNavRadio()
  ├── loadNews()         → fetch news.json → renderNewsFilters() + renderNews() (botões de áudio)
  ├── loadExperience()   → fetch experience.json → renderExperience()
  ├── updateTicker()     → bottom scroll bar (radio + news links)
  └── updateFooterStatus() → status line no footer

LIVE POLL (every 30s)
  └── pollRadioLive()    → fetch AzuraCast API → renderRadio() + updateNavRadio()

REFRESH (every 60s, user toggle)
  └── refreshAll()       → reload health + news + experience + ticker + footer

PLAYER
  ├── toggleRadio()      → play/pause HTML5 <audio> (rádio)
  └── toggleNewsAudio()  → play/pause MP3 da notícia (1 por vez)

ACCORDION
  └── renderExperience() → dynamic accordion from experience.json
```

### homelab.html

```
INIT
  ├── loadData()         → fetch health.json
  ├── render()           → Architecture overview (4 cards) + gauges/tabelas por node
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

## Security (repo PÚBLICO)

| Verificação | Status |
|-------------|--------|
| Senhas / tokens no repo | ✅ Nenhum |
| IPs privados | ✅ Nenhum nos HTML/JSON |
| Conteúdo sensível | ✅ Filtro SENSITIVE_TERMS no script de coleta |
| Container names filtrados | ✅ nomes sensíveis excluídos no script de coleta |
| `.gitignore` bloqueia `*.json` | ✅ Whitelist: health/news/experience/skills/projects/about/expertises/package |

Scan antes de cada push (rodar na raiz do repo; patterns genéricos — nunca
colocar senhas/emails reais nos comandos, senão o próprio comando vaza):

```bash
grep -rniE '(password|passwd|secret|api.?key|token|BEGIN .*PRIVATE KEY)' *.html *.json
grep -rE '(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)' *.html *.json
```

> **Nota:** nunca colocar senhas/emails reais dentro dos comandos de scan do README —
> o próprio comando vira vazamento. Usar patterns genéricos (como acima).

---

## Deploy

```bash
# Editar qualquer arquivo
vim index.html

# Deploy
git add -A && git commit -m "descrição" && git push origin main

# GitHub Pages auto-deploy em ~60 segundos (CDN max-age=600 — dados podem demorar até 10min)
```

**Sem build, sem CI/CD, sem dependências.**
