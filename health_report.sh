#!/bin/bash
# Pi Health Report v3 - Roda no Pi501-117, coleta dos 3 Pis
# Gera /home/robert/Documents/portfolio-html/health.json

DATE=$(date -Iseconds)
PORTFOLIO_DIR="/home/robert/Documents/portfolio-html"
mkdir -p "$PORTFOLIO_DIR"

collect_local() {
    local label="$1"
    local hostname=$(hostname)
    local uptime=$(uptime -p | sed 's/^up //')
    local load1=$(awk '{print $1}' /proc/loadavg)
    local load5=$(awk '{print $2}' /proc/loadavg)
    local load15=$(awk '{print $3}' /proc/loadavg)
    local temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.1f", $1/1000}' || echo "0")
    local mem_total=$(free -m | awk '/Mem:/{print $2}')
    local mem_used=$(free -m | awk '/Mem:/{print $3}')
    local mem_avail=$(free -m | awk '/Mem:/{print $7}')
    local mem_pct=$(( mem_used * 100 / mem_total ))
    local swap_total=$(free -m | awk '/Swap:/{print $2}')
    local swap_used=$(free -m | awk '/Swap:/{print $3}')
    local swap_pct=0; [ "$swap_total" -gt 0 ] && swap_pct=$(( swap_used * 100 / swap_total ))
    local disk_pct=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local procs=$(ps aux | wc -l)
    local containers=$(docker ps -q 2>/dev/null | wc -l)
    local images=$(docker images -q 2>/dev/null | wc -l)
    local ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    
    local score=100
    [ "$(echo "$load1 > 2" | bc -l)" -eq 1 ] && score=$((score - 15))
    [ "$(echo "$load1 > 4" | bc -l)" -eq 1 ] && score=$((score - 15))
    [ "$mem_pct" -gt 50 ] && score=$((score - 15))
    [ "$mem_pct" -gt 75 ] && score=$((score - 20))
    [ "$swap_pct" -gt 10 ] && score=$((score - 10))
    [ "$swap_pct" -gt 50 ] && score=$((score - 15))
    [ "$(echo "$temp > 60" | bc -l)" -eq 1 ] && score=$((score - 10))
    [ "$(echo "$temp > 70" | bc -l)" -eq 1 ] && score=$((score - 15))
    [ "$disk_pct" -gt 85 ] && score=$((score - 15))
    [ "$disk_pct" -gt 95 ] && score=$((score - 20))
    [ "$score" -lt 0 ] && score=0
    
    if [ "$score" -ge 80 ]; then grade="excellent"
    elif [ "$score" -ge 60 ]; then grade="good"
    elif [ "$score" -ge 40 ]; then grade="fair"
    else grade="critical"; fi
    
    echo "{\"label\":\"$label\",\"hostname\":\"$hostname\",\"ip\":\"$ip\",\"uptime\":\"$uptime\",\"score\":$score,\"grade\":\"$grade\",\"cpu\":{\"load_1m\":$load1,\"temperature\":$temp},\"memory\":{\"total_mb\":$mem_total,\"used_mb\":$mem_used,\"available_mb\":$mem_avail,\"percent\":$mem_pct,\"swap_percent\":$swap_pct},\"disk\":{\"percent\":$disk_pct},\"docker\":{\"containers\":$containers,\"images\":$images},\"processes\":$procs}"
}

collect_remote() {
    local host="$1"
    local label="$2"
    
    local raw=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "robert@$host" "bash /tmp/pi_health.sh" 2>&-)
    
    if [ -z "$raw" ]; then
        echo "{\"label\":\"$label\",\"hostname\":\"$label\",\"ip\":\"$host\",\"uptime\":\"offline\",\"score\":0,\"grade\":\"offline\",\"cpu\":{\"load_1m\":0,\"temperature\":0},\"memory\":{\"total_mb\":0,\"used_mb\":0,\"available_mb\":0,\"percent\":0,\"swap_percent\":0},\"disk\":{\"percent\":0},\"docker\":{\"containers\":0,\"images\":0},\"processes\":0}"
        return
    fi
    
    local load1=$(echo "$raw" | sed -n '1p' | awk '{print $1}')
    local temp=$(echo "$raw" | sed -n '2p')
    local mem_total=$(echo "$raw" | sed -n '3p' | awk '{print $1}')
    local mem_used=$(echo "$raw" | sed -n '3p' | awk '{print $2}')
    local mem_avail=$(echo "$raw" | sed -n '3p' | awk '{print $3}')
    [ -z "$mem_total" ] && mem_total=0; [ -z "$mem_used" ] && mem_used=0; [ -z "$mem_avail" ] && mem_avail=0
    [ "$mem_total" -gt 0 ] 2>/dev/null && local mem_pct=$(( mem_used * 100 / mem_total )) || local mem_pct=0
    
    local swap_total=$(echo "$raw" | sed -n '4p' | awk '{print $1}')
    local swap_used=$(echo "$raw" | sed -n '4p' | awk '{print $2}')
    [ -z "$swap_total" ] && swap_total=0; [ -z "$swap_used" ] && swap_used=0
    local swap_pct=0; [ "$swap_total" -gt 0 ] 2>/dev/null && swap_pct=$(( swap_used * 100 / swap_total ))
    
    local disk_pct=$(echo "$raw" | sed -n '5p' | awk '{print $3}' | sed 's/%//')
    [ -z "$disk_pct" ] && disk_pct=0
    local procs=$(echo "$raw" | sed -n '6p' | tr -d ' ')
    local hostname=$(echo "$raw" | sed -n '7p')
    local uptime=$(echo "$raw" | sed -n '8p' | sed 's/^up //')
    local containers=$(echo "$raw" | sed -n '9p' | tr -d ' ')
    local images=$(echo "$raw" | sed -n '10p' | tr -d ' ')
    
    [ -z "$procs" ] && procs=0; [ -z "$containers" ] && containers=0; [ -z "$images" ] && images=0
    [ -z "$uptime" ] && uptime="?"; [ -z "$hostname" ] && hostname="$label"
    
    local score=100
    [ "$(echo "$load1 > 2" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && score=$((score - 15))
    [ "$(echo "$load1 > 4" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && score=$((score - 15))
    [ "$mem_pct" -gt 50 ] 2>/dev/null && score=$((score - 15))
    [ "$mem_pct" -gt 75 ] 2>/dev/null && score=$((score - 20))
    [ "$swap_pct" -gt 10 ] 2>/dev/null && score=$((score - 10))
    [ "$swap_pct" -gt 50 ] 2>/dev/null && score=$((score - 15))
    [ "$(echo "$temp > 60" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && score=$((score - 10))
    [ "$(echo "$temp > 70" | bc -l 2>/dev/null)" -eq 1 ] 2>/dev/null && score=$((score - 15))
    [ "$disk_pct" -gt 85 ] 2>/dev/null && score=$((score - 15))
    [ "$disk_pct" -gt 95 ] 2>/dev/null && score=$((score - 20))
    [ "$score" -lt 0 ] && score=0
    
    if [ "$score" -ge 80 ]; then local grade="excellent"
    elif [ "$score" -ge 60 ]; then local grade="good"
    elif [ "$score" -ge 40 ]; then local grade="fair"
    else local grade="critical"; fi
    
    echo "{\"label\":\"$label\",\"hostname\":\"$hostname\",\"ip\":\"$host\",\"uptime\":\"$uptime\",\"score\":$score,\"grade\":\"$grade\",\"cpu\":{\"load_1m\":$load1,\"temperature\":$temp},\"memory\":{\"total_mb\":$mem_total,\"used_mb\":$mem_used,\"available_mb\":$mem_avail,\"percent\":$mem_pct,\"swap_percent\":$swap_pct},\"disk\":{\"percent\":$disk_pct},\"docker\":{\"containers\":$containers,\"images\":$images},\"processes\":$procs}"
}

# ─── COLETAR ───────────────────────────────────────
echo "Coletando Pi4..." >&2
PI4=$(collect_remote "192.168.68.102" "Pi4")

echo "Coletando Pi5-108..." >&2
PI5_108=$(collect_remote "192.168.68.108" "Pi5-108")

echo "Coletando Pi501-117 (local)..." >&2
PI501_117=$(collect_local "Pi501-117")

# ─── SERVICOS DO Pi5-108 ───────────────────────────
echo "Coletando servicos do Pi5-108..." >&2
SVC=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "robert@192.168.68.108" bash << 'SVCEOF'
curl -s -X POST "http://localhost:8080/api/v2/auth/login" -d "username=admin&password=whisparr2026" -c /tmp/hlth_svc 2>/dev/null
QBT_ACTIVE=$(curl -s -b /tmp/hlth_svc "http://localhost:8080/api/v2/torrents/info?filter=active" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
QBT_SPEED=$(curl -s -b /tmp/hlth_svc "http://localhost:8080/api/v2/transfer/info" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('dl_info_speed',0)//1024)" 2>/dev/null || echo "0")
AZU_MEM=$(docker stats azuracast --no-stream --format '{{.MemPerc}}' 2>/dev/null | sed 's/%//' || echo "0")
AZU_CPU=$(docker stats azuracast --no-stream --format '{{.CPUPerc}}' 2>/dev/null | sed 's/%//' || echo "0")
echo "{\"qbt_active\":$QBT_ACTIVE,\"qbt_speed\":$QBT_SPEED,\"azu_mem\":$AZU_MEM,\"azu_cpu\":$AZU_CPU}"
SVCEOF
)

RADIO=$(curl -s "https://dublincalling.duckdns.org/api/nowplaying/dublincalling" 2>/dev/null)
LISTENERS=$(echo "$RADIO" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    print(d.get('listeners',{}).get('current',0))
except: print(0)
" 2>/dev/null || echo "0")

RADIO_SONG=$(echo "$RADIO" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    np = d.get('now_playing',{}).get('song',{})
    t = np.get('title','')[:45]
    a = np.get('artist','')[:30]
    print((t + ' - ' + a) if t else 'offline')
except: print('offline')
" 2>/dev/null || echo "offline")

QBT_ACTIVE=$(echo "$SVC" | python3 -c "import json,sys; print(json.load(sys.stdin).get('qbt_active',0))" 2>/dev/null || echo "0")
QBT_SPEED=$(echo "$SVC" | python3 -c "import json,sys; print(json.load(sys.stdin).get('qbt_speed',0))" 2>/dev/null || echo "0")
AZU_MEM=$(echo "$SVC" | python3 -c "import json,sys; print(json.load(sys.stdin).get('azu_mem',0))" 2>/dev/null || echo "0")
AZU_CPU=$(echo "$SVC" | python3 -c "import json,sys; print(json.load(sys.stdin).get('azu_cpu',0))" 2>/dev/null || echo "0")

# ─── GERAR JSON ────────────────────────────────────
cat > "$PORTFOLIO_DIR/health.json" << JSONEOF
{
  "updated": "$DATE",
  "pis": [$PI4, $PI5_108, $PI501_117],
  "services": {
    "azuracast_mem_percent": $AZU_MEM,
    "azuracast_cpu_percent": $AZU_CPU,
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
    print(f'  {p[\"label\"]}: {p[\"score\"]}/100 - {p[\"grade\"]} ({p[\"hostname\"]}, {p[\"uptime\"]})')
print(f'  Radio: {d[\"services\"][\"radio_listeners\"]} listeners')
print(f'  Torrents: {d[\"services\"][\"qbt_torrents_active\"]} active @ {d[\"services\"][\"qbt_download_speed_kbps\"]} KB/s')
"
