#!/bin/bash
# Pi Health Report - Coleta metricas leves para relatorio
# Roda junto com o backup (nao faz stress, apenas mede)
# Gera /home/robert/Documents/portfolio-html/health.json

set -e
LOG="/home/robert/scripts/health_report.log"
DATE=$(date -Iseconds)
PORTFOLIO_DIR="/home/robert/Documents/portfolio-html"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Coletando metricas..." > "$LOG"

# ─── DADOS DO SISTEMA ─────────────────────────────
HOSTNAME=$(hostname)
UPTIME=$(uptime -p | sed 's/^up //')
LOAD=$(cat /proc/loadavg | awk '{print $1","$2","$3}')
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.1f", $1/1000}' || echo "0")
MEM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
MEM_USED=$(free -m | awk '/Mem:/{print $3}')
MEM_AVAIL=$(free -m | awk '/Mem:/{print $7}')
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))
SWAP_TOTAL=$(free -m | awk '/Swap:/{print $2}')
SWAP_USED=$(free -m | awk '/Swap:/{print $3}')
SWAP_PCT=0
[ "$SWAP_TOTAL" -gt 0 ] && SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
DISK_TOTAL=$(df / | tail -1 | awk '{print $2}')
DISK_USED=$(df / | tail -1 | awk '{print $3}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
PROCESSES=$(ps aux | wc -l)

# ─── DOCKER ───────────────────────────────────────
CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
IMAGES=$(docker images -q 2>/dev/null | wc -l)

# ─── AZURACAST ────────────────────────────────────
AZURACAST_MEM=$(docker stats azuracast --no-stream --format '{{.MemPerc}}' 2>/dev/null | sed 's/%//' || echo "0")
AZURACAST_CPU=$(docker stats azuracast --no-stream --format '{{.CPUPerc}}' 2>/dev/null | sed 's/%//' || echo "0")

# ─── QBITTORRENT ──────────────────────────────────
QBT_TORRENTS=$(curl -s -X POST "http://localhost:8080/api/v2/auth/login" -d "username=admin&password=whisparr2026" -c /tmp/hlth_cookies 2>/dev/null)
QBT_ACTIVE=$(curl -s -b /tmp/hlth_cookies "http://localhost:8080/api/v2/torrents/info?filter=active" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
QBT_DOWNLOADING=$(curl -s -b /tmp/hlth_cookies "http://localhost:8080/api/v2/torrents/info?filter=downloading" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
QBT_SPEED=$(curl -s -b /tmp/hlth_cookies "http://localhost:8080/api/v2/transfer/info" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('dl_info_speed',0)//1024)" 2>/dev/null || echo "0")

# ─── RADIO ────────────────────────────────────────
RADIO_DATA=$(curl -s "https://dublincalling.duckdns.org/api/nowplaying/dublincalling" 2>/dev/null)
LISTENERS=$(echo "$RADIO_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    print(d.get('listeners',{}).get('current',0))
except: print(0)
" 2>/dev/null || echo "0")

# ─── SCORE DE SAUDE ───────────────────────────────
SCORE=100
[ "$(echo "$LOAD" | cut -d, -f1 | awk '{print ($1 > 2)}')" -eq 1 ] && SCORE=$((SCORE - 15))
[ "$(echo "$LOAD" | cut -d, -f1 | awk '{print ($1 > 4)}')" -eq 1 ] && SCORE=$((SCORE - 15))
[ "$MEM_PCT" -gt 50 ] && SCORE=$((SCORE - 15))
[ "$MEM_PCT" -gt 75 ] && SCORE=$((SCORE - 20))
[ "$SWAP_PCT" -gt 10 ] && SCORE=$((SCORE - 10))
[ "$SWAP_PCT" -gt 50 ] && SCORE=$((SCORE - 15))
[ "$(echo "$TEMP > 60" | bc -l)" -eq 1 ] && SCORE=$((SCORE - 10))
[ "$(echo "$TEMP > 70" | bc -l)" -eq 1 ] && SCORE=$((SCORE - 15))
[ "$DISK_PCT" -gt 85 ] && SCORE=$((SCORE - 15))
[ "$DISK_PCT" -gt 95 ] && SCORE=$((SCORE - 20))
[ "$SCORE" -lt 0 ] && SCORE=0

if [ "$SCORE" -ge 80 ]; then GRADE="excellent"
elif [ "$SCORE" -ge 60 ]; then GRADE="good"
elif [ "$SCORE" -ge 40 ]; then GRADE="fair"
else GRADE="critical"; fi

# ─── ESTIMATIVA OUVINTES ──────────────────────────
AZU_MEM_MB=$(echo "$AZURACAST_MEM * 80" | bc 2>/dev/null || echo "700")
MAX_LISTENERS=$(( (2000 - $(echo "$AZU_MEM_MB" | cut -d. -f1)) / 5 ))
[ "$MAX_LISTENERS" -lt 0 ] && MAX_LISTENERS=0

# ─── GERAR JSON ───────────────────────────────────
mkdir -p "$PORTFOLIO_DIR"
cat > "$PORTFOLIO_DIR/health.json" << JSONEOF
{
  "updated": "$DATE",
  "hostname": "$HOSTNAME",
  "uptime": "$UPTIME",
  "score": $SCORE,
  "grade": "$GRADE",
  "cpu": {
    "cores": 4,
    "model": "ARM Cortex-A76 @ 2.4GHz",
    "load_1m": $(echo "$LOAD" | cut -d, -f1),
    "load_5m": $(echo "$LOAD" | cut -d, -f2),
    "load_15m": $(echo "$LOAD" | cut -d, -f3),
    "temperature": $TEMP
  },
  "memory": {
    "total_mb": $MEM_TOTAL,
    "used_mb": $MEM_USED,
    "available_mb": $MEM_AVAIL,
    "percent": $MEM_PCT,
    "swap_used_mb": $SWAP_USED,
    "swap_total_mb": $SWAP_TOTAL,
    "swap_percent": $SWAP_PCT
  },
  "disk": {
    "total_mb": $DISK_TOTAL,
    "used_mb": $DISK_USED,
    "percent": $DISK_PCT
  },
  "docker": {
    "containers_running": $CONTAINERS,
    "images_total": $IMAGES
  },
  "services": {
    "azuracast_mem_percent": $AZURACAST_MEM,
    "azuracast_cpu_percent": $AZURACAST_CPU,
    "qbt_torrents_active": $QBT_ACTIVE,
    "qbt_torrents_downloading": $QBT_DOWNLOADING,
    "qbt_download_speed_kbps": $QBT_SPEED,
    "radio_listeners": $LISTENERS
  },
  "capacity": {
    "estimated_max_listeners": $MAX_LISTENERS,
    "note": "Based on 2GB RAM limit for AzuraCast"
  },
  "processes": $PROCESSES
}
JSONEOF

echo "✅ Health report saved: $PORTFOLIO_DIR/health.json" >> "$LOG"
echo "Score: $SCORE/100 - $GRADE" >> "$LOG"
