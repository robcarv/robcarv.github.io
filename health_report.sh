#!/bin/bash
# Pi Health Report - Coleta metricas de TODOS os Pis
# Gera /home/robert/Documents/portfolio-html/health.json com dados dos 3

set -e
DATE=$(date -Iseconds)
LOG="/tmp/health_all.log"
PORTFOLIO_DIR="/home/robert/Documents/portfolio-html"
mkdir -p "$PORTFOLIO_DIR"

echo "[$(date)] Coletando metricas de todos os Pis..." > "$LOG"

# ─── FUNCAO: coletar dados de um Pi ──────────────
collect_pi() {
    local host="$1"
    local label="$2"
    local ssh_cmd=""
    local OFFLINE=0
    
    if [ "$host" = "localhost" ]; then
        # Local (Pi501)
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
        SWAP_PCT=0; [ "$SWAP_TOTAL" -gt 0 ] && SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
        DISK_TOTAL=$(df / | tail -1 | awk '{print $2}')
        DISK_USED=$(df / | tail -1 | awk '{print $3}')
        DISK_PCT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        PROCESSES=$(ps aux | wc -l)
        CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
        IMAGES=$(docker images -q 2>/dev/null | wc -l)
    else
        # Remoto (Pi4 ou Pi5-108)
        local result
        result=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "robert@$host" bash -c "'cat /proc/loadavg | awk \"{print \\\$1\\\",\\\"\\\$2\\\",\\\"\\\$3}\"; cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk \"{printf %.1f,\\\$1/1000}\" || echo 0; free -m | awk \"/Mem:/{print \\\$2, \\\$3, \\\$7}\"; free -m | awk \"/Swap:/{print \\\$2, \\\$3}\"; df / | tail -1 | awk \"{print \\\$2, \\\$3, \\\$5}\"; ps aux | wc -l; hostname; uptime -p | sed \"s/^up //\"; docker ps -q 2>/dev/null | wc -l; docker images -q 2>/dev/null | wc -l' 2>/dev/null" 2>/dev/null)
        
        if [ -z "$result" ]; then
            echo "{\"label\":\"$label\",\"hostname\":\"$label\",\"ip\":\"$host\",\"uptime\":\"offline\",\"score\":0,\"grade\":\"offline\",\"cpu\":{\"load_1m\":0,\"temperature\":0},\"memory\":{\"total_mb\":0,\"used_mb\":0,\"available_mb\":0,\"percent\":0,\"swap_percent\":0},\"disk\":{\"percent\":0},\"docker\":{\"containers\":0,\"images\":0},\"processes\":0}"
            return
        fi
        
        HOSTNAME=$(echo "$result" | sed -n '8p')
        UPTIME=$(echo "$result" | sed -n '9p')
        LOAD=$(echo "$result" | sed -n '1p')
        TEMP=$(echo "$result" | sed -n '2p')
        MEM=$(echo "$result" | sed -n '3p')
        SWAP=$(echo "$result" | sed -n '4p')
        DISK=$(echo "$result" | sed -n '5p')
        PROCESSES=$(echo "$result" | sed -n '6p' | tr -d ' ' || echo "0")
        CONTAINERS=$(echo "$result" | sed -n '10p' | tr -d ' ' || echo "0")
        IMAGES=$(echo "$result" | sed -n '11p' | tr -d ' ' || echo "0")
        
        MEM_TOTAL=$(echo "$MEM" | awk '{print $1}' || echo "0")
        MEM_USED=$(echo "$MEM" | awk '{print $2}' || echo "0")
        MEM_AVAIL=$(echo "$MEM" | awk '{print $3}' || echo "0")
        [ "$MEM_TOTAL" -gt 0 ] 2>/dev/null && MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL )) || MEM_PCT=0
        SWAP_TOTAL=$(echo "$SWAP" | awk '{print $1}' || echo "0")
        SWAP_USED=$(echo "$SWAP" | awk '{print $2}' || echo "0")
        SWAP_PCT=0; [ "$SWAP_TOTAL" -gt 0 ] 2>/dev/null && SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
        DISK_TOTAL=$(echo "$DISK" | awk '{print $1}' || echo "0")
        DISK_USED=$(echo "$DISK" | awk '{print $2}' || echo "0")
        DISK_PCT=$(echo "$DISK" | awk '{print $3}' | sed 's/%//' || echo "0")
    fi

    # Score
    local SCORE=100
    local L1=$(echo "$LOAD" | cut -d, -f1)
    [ "$(echo "$L1 > 2" | bc -l 2>/dev/null)" -eq 1 ] && SCORE=$((SCORE - 15))
    [ "$(echo "$L1 > 4" | bc -l 2>/dev/null)" -eq 1 ] && SCORE=$((SCORE - 15))
    [ "$MEM_PCT" -gt 50 ] && SCORE=$((SCORE - 15))
    [ "$MEM_PCT" -gt 75 ] && SCORE=$((SCORE - 20))
    [ "$SWAP_PCT" -gt 10 ] && SCORE=$((SCORE - 10))
    [ "$SWAP_PCT" -gt 50 ] && SCORE=$((SCORE - 15))
    [ "$(echo "$TEMP > 60" | bc -l 2>/dev/null)" -eq 1 ] && SCORE=$((SCORE - 10))
    [ "$(echo "$TEMP > 70" | bc -l 2>/dev/null)" -eq 1 ] && SCORE=$((SCORE - 15))
    [ "$DISK_PCT" -gt 85 ] && SCORE=$((SCORE - 15))
    [ "$DISK_PCT" -gt 95 ] && SCORE=$((SCORE - 20))
    [ "$SCORE" -lt 0 ] && SCORE=0

    if [ "$SCORE" -ge 80 ]; then GRADE="excellent"
    elif [ "$SCORE" -ge 60 ]; then GRADE="good"
    elif [ "$SCORE" -ge 40 ]; then GRADE="fair"
    else GRADE="critical"; fi

    # Saida como JSON
    echo "{
      \"label\": \"$label\",
      \"hostname\": \"$HOSTNAME\",
      \"uptime\": \"$UPTIME\",
      \"ip\": \"$host\",
      \"score\": $SCORE,
      \"grade\": \"$GRADE\",
      \"cpu\": { \"load_1m\": $L1, \"temperature\": $TEMP },
      \"memory\": { \"total_mb\": $MEM_TOTAL, \"used_mb\": $MEM_USED, \"available_mb\": $MEM_AVAIL, \"percent\": $MEM_PCT, \"swap_percent\": $SWAP_PCT },
      \"disk\": { \"percent\": $DISK_PCT },
      \"docker\": { \"containers\": $CONTAINERS, \"images\": $IMAGES },
      \"processes\": $PROCESSES
    }"
}

# ─── COLETAR DADOS ────────────────────────────────

PI4=$(collect_pi "192.168.68.102" "Pi4")
PI5_108=$(collect_pi "localhost" "Pi5-108")
PI501_117=$(collect_pi "localhost" "Pi501-117")

# ─── DADOS GLOBAIS (servicos do Pi5-108) ──────────
# AzuraCast
AZURACAST_MEM=$(docker stats azuracast --no-stream --format '{{.MemPerc}}' 2>/dev/null | sed 's/%//' || echo "0")
AZURACAST_CPU=$(docker stats azuracast --no-stream --format '{{.CPUPerc}}' 2>/dev/null | sed 's/%//' || echo "0")

# qBittorrent
curl -s -X POST "http://localhost:8080/api/v2/auth/login" -d "username=admin&password=whisparr2026" -c /tmp/hlth_all 2>/dev/null
QBT_ACTIVE=$(curl -s -b /tmp/hlth_all "http://localhost:8080/api/v2/torrents/info?filter=active" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
QBT_SPEED=$(curl -s -b /tmp/hlth_all "http://localhost:8080/api/v2/transfer/info" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('dl_info_speed',0)//1024)" 2>/dev/null || echo "0")

# Radio
RADIO_DATA=$(curl -s "https://dublincalling.duckdns.org/api/nowplaying/dublincalling" 2>/dev/null)
LISTENERS=$(echo "$RADIO_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    print(d.get('listeners',{}).get('current',0))
except: print(0)
" 2>/dev/null || echo "0")

# Radio song
RADIO_SONG=$(echo "$RADIO_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    np = d.get('now_playing',{}).get('song',{})
    print(np.get('title','')[:40] + ' - ' + np.get('artist','')[:30])
except: print('offline')
" 2>/dev/null || echo "offline")

# ─── GERAR JSON FINAL ──────────────────────────────
cat > "$PORTFOLIO_DIR/health.json" << JSONEOF
{
  "updated": "$DATE",
  "pis": [$PI4, $PI5_108, $PI501_117],
  "services": {
    "azuracast_mem_percent": $AZURACAST_MEM,
    "azuracast_cpu_percent": $AZURACAST_CPU,
    "qbt_torrents_active": $QBT_ACTIVE,
    "qbt_download_speed_kbps": $QBT_SPEED,
    "radio_listeners": $LISTENERS,
    "radio_now_playing": "$RADIO_SONG"
  },
  "capacity": {
    "estimated_max_listeners": 200,
    "note": "Based on 2GB RAM limit for AzuraCast"
  }
}
JSONEOF

echo "✅ Health report saved: $PORTFOLIO_DIR/health.json" >> "$LOG"
cat "$PORTFOLIO_DIR/health.json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('Pis:', len(d['pis']))
for p in d['pis']:
    print(f'  {p[\"label\"]}: {p[\"score\"]}/100 - {p[\"grade\"]} ({p[\"ip\"]})')
print(f'Radio: {d[\"services\"][\"radio_listeners\"]} listeners')
print(f'Torrents: {d[\"services\"][\"qbt_torrents_active\"]} active')
"
