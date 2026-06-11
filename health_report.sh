#!/bin/bash
# Pi Health Report - Coleta metricas de TODOS os Pis
# Gera /home/robert/Documents/portfolio-html/health.json
# Roda no Pi5-108. Conecta via SSH no Pi4.

DATE=$(date -Iseconds)
PORTFOLIO_DIR="/home/robert/Documents/portfolio-html"
mkdir -p "$PORTFOLIO_DIR"

# ─── Helper: coletar local ────────────────────────
collect_local() {
    local label="$1"
    LOAD1=$(awk '{print $1}' /proc/loadavg)
    LOAD5=$(awk '{print $2}' /proc/loadavg)
    LOAD15=$(awk '{print $3}' /proc/loadavg)
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.1f", $1/1000}' || echo "0")
    MEM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
    MEM_USED=$(free -m | awk '/Mem:/{print $3}')
    MEM_AVAIL=$(free -m | awk '/Mem:/{print $7}')
    [ "$MEM_TOTAL" -gt 0 ] && MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL )) || MEM_PCT=0
    SWAP_TOTAL=$(free -m | awk '/Swap:/{print $2}')
    SWAP_USED=$(free -m | awk '/Swap:/{print $3}')
    SWAP_PCT=0; [ "$SWAP_TOTAL" -gt 0 ] && SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
    DISK_PCT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    PROC=$(ps aux | wc -l)
    HOST=$(hostname)
    UP=$(uptime -p | sed 's/^up //')
    CONT=$(docker ps -q 2>/dev/null | wc -l)
    IMG=$(docker images -q 2>/dev/null | wc -l)
    
    SCORE=100
    [ "$(echo "$LOAD1 > 2" | bc -l)" -eq 1 ] && SCORE=$((SCORE - 15))
    [ "$(echo "$LOAD1 > 4" | bc -l)" -eq 1 ] && SCORE=$((SCORE - 15))
    [ "$MEM_PCT" -gt 50 ] && SCORE=$((SCORE - 15))
    [ "$MEM_PCT" -gt 75 ] && SCORE=$((SCORE - 20))
    [ "$SWAP_PCT" -gt 10 ] && SCORE=$((SCORE - 10))
    [ "$SWAP_PCT" -gt 50 ] && SCORE=$((SCORE - 15))
    [ "$(echo "$TEMP > 60" | bc -l)" -eq 1 ] && SCORE=$((SCORE - 10))
    [ "$(echo "$TEMP > 70" | bc -l)" -eq 1 ] && SCORE=$((SCORE - 15))
    [ "$DISK_PCT" -gt 85 ] && SCORE=$((SCORE - 15))
    [ "$DISK_PCT" -gt 95 ] && SCORE=$((SCORE - 20))
    [ "$SCORE" -lt 0 ] && SCORE=0
    [ "$SCORE" -ge 80 ] && GRADE="excellent"
    [ "$SCORE" -ge 60 ] && [ "$SCORE" -lt 80 ] && GRADE="good"
    [ "$SCORE" -ge 40 ] && [ "$SCORE" -lt 60 ] && GRADE="fair"
    [ "$SCORE" -lt 40 ] && GRADE="critical"
    
    echo "{\"label\":\"$label\",\"hostname\":\"$HOST\",\"ip\":\"local\",\"uptime\":\"$UP\",\"score\":$SCORE,\"grade\":\"$GRADE\",\"cpu\":{\"load_1m\":$LOAD1,\"temperature\":$TEMP},\"memory\":{\"total_mb\":$MEM_TOTAL,\"used_mb\":$MEM_USED,\"available_mb\":$MEM_AVAIL,\"percent\":$MEM_PCT,\"swap_percent\":$SWAP_PCT},\"disk\":{\"percent\":$DISK_PCT},\"docker\":{\"containers\":$CONT,\"images\":$IMG},\"processes\":$PROC}"
}

# ─── Helper: coletar remoto (via SSH) ─────────────
collect_remote() {
    local host="$1"
    local label="$2"
    local raw
    
    raw=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "robert@$host" "bash /tmp/pi_health.sh" 2>&-)
    
    if [ -z "$raw" ]; then
        echo "{\"label\":\"$label\",\"hostname\":\"$label\",\"ip\":\"$host\",\"uptime\":\"offline\",\"score\":0,\"grade\":\"offline\",\"cpu\":{\"load_1m\":0,\"temperature\":0},\"memory\":{\"total_mb\":0,\"used_mb\":0,\"available_mb\":0,\"percent\":0,\"swap_percent\":0},\"disk\":{\"percent\":0},\"docker\":{\"containers\":0,\"images\":0},\"processes\":0}"
        return
    fi
    
    LOAD1=$(echo "$raw" | sed -n '1p' | awk '{print $1}')
    TEMP=$(echo "$raw" | sed -n '2p')
    MEM_TOTAL=$(echo "$raw" | sed -n '3p' | awk '{print $1}')
    MEM_USED=$(echo "$raw" | sed -n '3p' | awk '{print $2}')
    MEM_AVAIL=$(echo "$raw" | sed -n '3p' | awk '{print $3}')
    [ -z "$MEM_TOTAL" ] && MEM_TOTAL=0; [ -z "$MEM_USED" ] && MEM_USED=0; [ -z "$MEM_AVAIL" ] && MEM_AVAIL=0
    [ "$MEM_TOTAL" -gt 0 ] 2>/dev/null && MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL )) || MEM_PCT=0
    
    SWAP_TOTAL=$(echo "$raw" | sed -n '4p' | awk '{print $1}')
    SWAP_USED=$(echo "$raw" | sed -n '4p' | awk '{print $2}')
    [ -z "$SWAP_TOTAL" ] && SWAP_TOTAL=0; [ -z "$SWAP_USED" ] && SWAP_USED=0
    SWAP_PCT=0; [ "$SWAP_TOTAL" -gt 0 ] 2>/dev/null && SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
    
    DISK_PCT=$(echo "$raw" | sed -n '5p' | awk '{print $3}' | sed 's/%//')
    [ -z "$DISK_PCT" ] && DISK_PCT=0
    
    PROC=$(echo "$raw" | sed -n '6p' | tr -d ' ')
    HOST=$(echo "$raw" | sed -n '7p')
    UP=$(echo "$raw" | sed -n '8p' | sed 's/^up //')
    CONT=$(echo "$raw" | sed -n '9p' | tr -d ' ')
    IMG=$(echo "$raw" | sed -n '10p' | tr -d ' ')
    
    [ -z "$PROC" ] && PROC=0; [ -z "$CONT" ] && CONT=0; [ -z "$IMG" ] && IMG=0
    [ -z "$UP" ] && UP="unknown"; [ -z "$HOST" ] && HOST="$label"
    
    SCORE=100
    [ "$(echo "$LOAD1 > 2" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && SCORE=$((SCORE - 15))
    [ "$(echo "$LOAD1 > 4" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && SCORE=$((SCORE - 15))
    [ "$MEM_PCT" -gt 50 ] 2>/dev/null && SCORE=$((SCORE - 15))
    [ "$MEM_PCT" -gt 75 ] 2>/dev/null && SCORE=$((SCORE - 20))
    [ "$SWAP_PCT" -gt 10 ] 2>/dev/null && SCORE=$((SCORE - 10))
    [ "$SWAP_PCT" -gt 50 ] 2>/dev/null && SCORE=$((SCORE - 15))
    [ "$(echo "$TEMP > 60" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && SCORE=$((SCORE - 10))
    [ "$(echo "$TEMP > 70" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && SCORE=$((SCORE - 15))
    [ "$DISK_PCT" -gt 85 ] 2>/dev/null && SCORE=$((SCORE - 15))
    [ "$DISK_PCT" -gt 95 ] 2>/dev/null && SCORE=$((SCORE - 20))
    [ "$SCORE" -lt 0 ] && SCORE=0
    [ "$SCORE" -ge 80 ] && GRADE="excellent" || true
    [ "$SCORE" -ge 60 ] && [ "$SCORE" -lt 80 ] && GRADE="good" || true
    [ "$SCORE" -ge 40 ] && [ "$SCORE" -lt 60 ] && GRADE="fair" || true
    [ "$SCORE" -lt 40 ] && GRADE="critical" || true
    
    echo "{\"label\":\"$label\",\"hostname\":\"$HOST\",\"ip\":\"$host\",\"uptime\":\"$UP\",\"score\":$SCORE,\"grade\":\"$GRADE\",\"cpu\":{\"load_1m\":$LOAD1,\"temperature\":$TEMP},\"memory\":{\"total_mb\":$MEM_TOTAL,\"used_mb\":$MEM_USED,\"available_mb\":$MEM_AVAIL,\"percent\":$MEM_PCT,\"swap_percent\":$SWAP_PCT},\"disk\":{\"percent\":$DISK_PCT},\"docker\":{\"containers\":$CONT,\"images\":$IMG},\"processes\":$PROC}"
}

# ─── COLETAR ───────────────────────────────────────
PI4=$(collect_remote "192.168.68.102" "Pi4")
PI5_108=$(collect_local "Pi5-108")
PI501_117=$(collect_local "Pi501-117")

# ─── SERVICOS ──────────────────────────────────────
AZURACAST_MEM=$(docker stats azuracast --no-stream --format '{{.MemPerc}}' 2>/dev/null | sed 's/%//' || echo "0")
AZURACAST_CPU=$(docker stats azuracast --no-stream --format '{{.CPUPerc}}' 2>/dev/null | sed 's/%//' || echo "0")

curl -s -X POST "http://localhost:8080/api/v2/auth/login" -d "username=admin&password=whisparr2026" -c /tmp/hlth_all 2>/dev/null
QBT_ACTIVE=$(curl -s -b /tmp/hlth_all "http://localhost:8080/api/v2/torrents/info?filter=active" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
QBT_SPEED=$(curl -s -b /tmp/hlth_all "http://localhost:8080/api/v2/transfer/info" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('dl_info_speed',0)//1024)" 2>/dev/null || echo "0")

RADIO_DATA=$(curl -s "https://dublincalling.duckdns.org/api/nowplaying/dublincalling" 2>/dev/null)
LISTENERS=$(echo "$RADIO_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    print(d.get('listeners',{}).get('current',0))
except: print(0)
" 2>/dev/null || echo "0")

RADIO_SONG=$(echo "$RADIO_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    np = d.get('now_playing',{}).get('song',{})
    t = np.get('title','')[:40]
    a = np.get('artist','')[:30]
    print(t + ' - ' + a if t else 'offline')
except: print('offline')
" 2>/dev/null || echo "offline")

# ─── GERAR JSON ────────────────────────────────────
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

echo "✅ Health report saved"
python3 -c "
import json,sys
with open('$PORTFOLIO_DIR/health.json') as f:
    d=json.load(f)
for p in d['pis']:
    print(f'  {p[\"label\"]}: {p[\"score\"]}/100 - {p[\"grade\"]} ({p[\"uptime\"]})')
print(f'  Radio: {d[\"services\"][\"radio_listeners\"]} listeners')
print(f'  Torrents: {d[\"services\"][\"qbt_torrents_active\"]} active @ {d[\"services\"][\"qbt_download_speed_kbps\"]} KB/s')
"
