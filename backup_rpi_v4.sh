#!/bin/bash
# =============================================================================
# backup_rpi_v4.sh — Backup completo dos 3 Raspberry Pis
# =============================================================================
# Faz:
#   1. ClamAV antivírus scan nos downloads
#   2. Backup das configs de todos os Pis
#   3. Rsync para TrueNAS (CIFS)
#   4. Upload para OneDrive via rclone
#   5. Health report (score dos 3 Pis)
#   6. Git push para GitHub
#   7. Limpeza de backups antigos
#
# Agendado: Seg/Qua/Sex 03:30 (cron no Pi5-108)
# Manual:   bash /home/robert/scripts/backup_rpi_v4.sh
# =============================================================================

set -e

# ─── CONFIG ──────────────────────────────────────────────────────────
DATE=$(date +%Y%m%d_%H%M%S)
DATE_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DIR="/home/robert/backups"
LOG_DIR="$BACKUP_DIR/logs"
LOG_FILE="$LOG_DIR/backup_$DATE.log"
CIFS_MOUNT="/mnt/truenas_media"
REMOTE_BACKUP="$CIFS_MOUNT/whisparr/downloads/backup/pis"
GIT_REPO="/home/robert/Documents/docker/backup_raspberry"
PORTFOLIO_DIR="/home/robert/Documents/portfolio-html"

# Retenção
LOCAL_RETENTION_DAYS=15   # dias para manter backups locais
ONEDRIVE_RETENTION_DAYS=30 # dias para manter no OneDrive

# rclone / OneDrive
ONEDRIVE_REMOTE="onedrive:/backups"
RCLONE_OPTS="--progress --stats-one-line --stats=5s --log-level=INFO"

# Pis
declare -A PIS
PIS["192.168.68.102"]="Pi4"
PIS["192.168.68.108"]="Pi5-108"
PIS["192.168.68.117"]="Pi501-117"

# ─── FUNÇÕES ────────────────────────────────────────────────────────

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

section() {
    echo "" | tee -a "$LOG_FILE"
    echo "══════════════════════════════════════════════" | tee -a "$LOG_FILE"
    echo "  $1" | tee -a "$LOG_FILE"
    echo "══════════════════════════════════════════════" | tee -a "$LOG_FILE"
}

# 1. ClamAV Scan
run_antivirus() {
    section "🔒 ClamAV Antivírus Scan"
    log "Iniciando scan nos downloads..."
    
    if ssh robert@192.168.68.108 "docker exec clamav sh -c 'timeout 300 clamscan --recursive --infected /scan/ 2>/dev/null'" > /tmp/clamav_result.txt 2>&1; then
        INFECTED=$(grep "Infected files:" /tmp/clamav_result.txt | awk '{print $3}')
        if [ "$INFECTED" != "0" ] && [ -n "$INFECTED" ]; then
            log "❌ ALERTA: $INFECTED arquivos infectados!"
            cat /tmp/clamav_result.txt >> "$LOG_FILE"
        else
            log "✅ Nenhum vírus encontrado"
        fi
    else
        log "⚠️  ClamAV não respondeu (container pode estar parado)"
    fi
}

# 2. Backup de cada Pi
backup_pi() {
    local IP=$1
    local NAME=$2
    local TAR="$BACKUP_DIR/${NAME}_${DATE}.tar.gz"
    
    log "📦 Backup de $NAME ($IP)..."
    
    # Testa conectividade
    if ! ssh -o ConnectTimeout=5 "robert@$IP" "echo ok" 2>/dev/null; then
        log "⚠️  $NAME offline, pulando..."
        return
    fi
    
    # Coleta dados
    ssh "robert@$IP" bash -c "'tar czf - \
        /home/robert/scripts/ 2>/dev/null || true; \
        /home/robert/*/docker-compose.yml 2>/dev/null || true; \
        /home/robert/*/config/ 2>/dev/null || true'" > "$TAR" 2>/dev/null || true
    
    # Crontab
    ssh "robert@$IP" "crontab -l" 2>/dev/null > "$BACKUP_DIR/${NAME}_crontab_${DATE}.txt" || true
    
    # Docker info
    ssh "robert@$IP" "docker ps --format '{{.Names}} {{.Status}}'" 2>/dev/null > "$BACKUP_DIR/${NAME}_docker_${DATE}.txt" || true
    
    local SIZE=$(du -h "$TAR" 2>/dev/null | cut -f1)
    log "✅ $NAME concluído (${SIZE:-0})"
}

# 3. Rsync para TrueNAS
sync_truenas() {
    section "💾 Sincronizando com TrueNAS"
    
    if mount | grep -q "$CIFS_MOUNT"; then
        mkdir -p "$REMOTE_BACKUP" 2>/dev/null
        rsync -avz --delete "$BACKUP_DIR/" "$REMOTE_BACKUP/" >> "$LOG_FILE" 2>&1 || true
        log "✅ Sync TrueNAS concluído"
    else
        log "⚠️  TrueNAS não montado, tentando montar..."
        bash /home/robert/scripts/mount_cifs.sh >> "$LOG_FILE" 2>&1 || true
        if mount | grep -q "$CIFS_MOUNT"; then
            rsync -avz --delete "$BACKUP_DIR/" "$REMOTE_BACKUP/" >> "$LOG_FILE" 2>&1 || true
            log "✅ Sync TrueNAS concluído"
        else
            log "❌ TrueNAS não disponível"
        fi
    fi
}

# 4. Upload para OneDrive
upload_onedrive() {
    section "☁️  Upload para OneDrive"
    
    if ! command -v rclone &>/dev/null; then
        log "❌ rclone não instalado. Instale com: sudo apt install rclone"
        log "   Depois configure: rclone config (remote: onedrive)"
        return 1
    fi
    
    if ! rclone listremotes 2>/dev/null | grep -q "onedrive:"; then
        log "❌ Remote 'onedrive:' não configurado no rclone"
        log "   Configure com: rclone config (tipo: onedrive)"
        return 1
    fi
    
    log "📤 Enviando backups para OneDrive..."
    
    rclone copy "$BACKUP_DIR" "$ONEDRIVE_REMOTE" $RCLONE_OPTS 2>>"$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "✅ Upload para OneDrive concluído!"
        
        # Mostra espaço usado
        USED=$(rclone size "$ONEDRIVE_REMOTE" --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d.get(\"bytes\",0)/1024/1024/1024:.1f}GB')" 2>/dev/null || echo "?")
        log "📊 Espaço usado no OneDrive: $USED"
        
        # Deleta backups antigos no OneDrive
        log "🧹 Removendo backups com mais de ${ONEDRIVE_RETENTION_DAYS} dias do OneDrive..."
        rclone delete --min-age "${ONEDRIVE_RETENTION_DAYS}d" "$ONEDRIVE_REMOTE" 2>>"$LOG_FILE" || true
    else
        log "❌ Falha no upload para OneDrive"
    fi
}

# 5. Health Report
run_health_report() {
    section "📊 Coletando Health Report dos Pis"
    
    if [ -f "/home/robert/scripts/health_report.sh" ]; then
        bash /home/robert/scripts/health_report.sh >> "$LOG_FILE" 2>&1
        log "✅ Health report gerado"
    else
        log "⚠️  Script health_report.sh não encontrado"
    fi
}

# 6. Git Push
git_push() {
    section "📤 Git Push para GitHub"
    
    # Backup dos scripts
    cp /home/robert/scripts/backup_rpi_v4.sh "$GIT_REPO/scripts/" 2>/dev/null || true
    cp /home/robert/Documents/Docker/dashy/public/conf.yml "$GIT_REPO/dashy_conf_${DATE}.yml" 2>/dev/null || true
    
    if [ -d "$GIT_REPO/.git" ]; then
        cd "$GIT_REPO"
        git add -A 2>/dev/null
        git commit -m "Backup $DATE" --allow-empty -q 2>/dev/null || true
        git push origin main -q 2>/dev/null && log "✅ GitHub push concluído" || log "⚠️  Git push falhou"
    fi
}

# 7. Limpeza local
cleanup_local() {
    section "🧹 Limpeza de backups antigos"
    log "Removendo backups locais com mais de ${LOCAL_RETENTION_DAYS} dias..."
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$LOCAL_RETENTION_DAYS -delete 2>/dev/null
    find "$LOG_DIR" -name "*.log" -mtime +60 -delete 2>/dev/null
    log "✅ Limpeza concluída"
}

# ─── MAIN ───────────────────────────────────────────────────────────

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

log "══════════════════════════════════════════════"
log "🚀 backup_rpi_v4.sh iniciado: $DATE_HUMAN"
log "══════════════════════════════════════════════"

# 1. Antivírus
run_antivirus

# 2. Backup de cada Pi
section "📦 Backup dos 3 Raspberry Pis"
mkdir -p "$BACKUP_DIR"
for IP in "${!PIS[@]}"; do
    backup_pi "$IP" "${PIS[$IP]}"
done

# 3. Dashy config
log "📋 Salvando config do Dashy..."
cp /home/robert/Documents/Docker/dashy/public/conf.yml "$BACKUP_DIR/dashy_conf_${DATE}.yml" 2>/dev/null || true

# 4. Rsync TrueNAS
sync_truenas

# 5. Health Report
run_health_report

# 6. Upload OneDrive
upload_onedrive

# 7. Git Push
git_push

# 8. Limpeza
cleanup_local

section "✅ Backup concluído: $DATE_HUMAN"
log "📝 Log: $LOG_FILE"
log "📁 Local: $BACKUP_DIR"
log "☁️  OneDrive: $ONEDRIVE_REMOTE"

exit 0
