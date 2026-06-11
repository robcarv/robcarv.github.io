#!/bin/bash
# Mount TrueNAS CIFS sob demanda (evita travamentos no boot)
# Chama via cron ou sempre antes de scripts que precisam do CIFS

MOUNT="/mnt/truenas_media"
SERVER="192.168.68.124"
SHARE="Media"

# Ja esta montado?
mount | grep -q "$MOUNT" && exit 0

# Tentar montar
mkdir -p "$MOUNT"
mount -t cifs "//$SERVER/$SHARE" "$MOUNT" \
    -o credentials=/etc/smbcredentials/truenas,vers=3.0,uid=1000,gid=1000,\
file_mode=0755,dir_mode=0755,iocharset=utf8,soft,noserverino,nobrl,\
echo_interval=5,actimeo=1,closetimeo=1,_netdev,noatime 2>/dev/null

if mount | grep -q "$MOUNT"; then
    echo "[$(date)] CIFS montado: $MOUNT"
else
    echo "[$(date)] ERRO: CIFS nao montou"
    exit 1
fi
