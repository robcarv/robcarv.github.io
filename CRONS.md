# 🕒 Complete Cron Job Documentation — Raspberry Pi Homelab

**Generated**: 2026-06-12 09:05 IST  
**Covers**: All 3 Raspberry Pis in the homelab

---

## Network Topology

| Host | Hostname | IP | Model | Role |
|------|----------|----|-------|------|
| **Pi5-108** | `raspberrypi5` | 192.168.68.108 | Raspberry Pi 5 | Torrent pipeline, radio, monitoring |
| **Pi4** | `raspberrypi4` | 192.168.68.102 | Raspberry Pi 4 | Pi-hole, dashboard, backups |
| **Pi501-117** | `raspberrypi501` | 192.168.68.117 | Raspberry Pi 5 | Dashboard, news, subscriptions, health reports |

---

## Pi5-108 (raspberrypi5) — 7 cron jobs

### 1. @reboot — Enable multi-arch Docker support
```
@reboot docker run --privileged --rm tonistiigi/binfmt --install x86_64
```
- **What**: Installs QEMU binfmt handlers so ARM Pi can run x86_64 Docker containers
- **Why**: Some containers (e.g. Duplicati) are x86-only; this emulates them
- **Runs**: Every boot
- **Manual**: `docker run --privileged --rm tonistiigi/binfmt --install x86_64`

### 2. `*/5 * * * *` — Guardian health monitor
```
*/5 * * * * /home/robert/scripts/guardian.sh
```
- **What**: Checks system load (>8), memory (>85%), swap (>50%). Logs warnings and takes action if thresholds exceeded
- **Script**: `/home/robert/scripts/guardian.sh`
- **Log**: `/home/robert/scripts/guardian.log`
- **Runs**: Every 5 minutes, 24/7
- **Manual**: `bash /home/robert/scripts/guardian.sh`

### 3. `*/5 * * * *` — CIFS mount checker
```
*/5 * * * * /home/robert/scripts/mount_cifs.sh > /dev/null 2>&1
```
- **What**: Checks if `//192.168.68.124/Media` is mounted at `/mnt/truenas_media`. If not, remounts it. Silent (stdout to /dev/null)
- **Script**: `/home/robert/scripts/mount_cifs.sh`
- **Log**: None (stdout discarded)
- **Runs**: Every 5 minutes, 24/7
- **Manual**: `bash /home/robert/scripts/mount_cifs.sh`

### 4. `0 */6 * * *` — Torrent health check
```
0 */6 * * * /home/robert/scripts/torrent_health_cron.sh >> /home/robert/scripts/torrent_health.log 2>&1
```
- **What**: Runs inside qBittorrent container — detects stuck torrents (100% complete but 0 bytes), rechecks them, force-resumes. Logs results
- **Script**: `/home/robert/scripts/torrent_health_cron.sh` → calls `docker exec qbittorrent python3 /usr/local/bin/torrent_health.py`
- **Log**: `/home/robert/scripts/torrent_health.log`
- **Runs**: Every 6 hours (00:00, 06:00, 12:00, 18:00)
- **Manual**: `bash /home/robert/scripts/torrent_health_cron.sh`

### 5. `0 3 * * *` — ClamAV antivirus scan
```
0 3 * * * /home/robert/scripts/torrent_antivirus.sh >> /home/robert/scripts/clamav_scan.log 2>&1
```
- **What**: Scans all completed torrent downloads with ClamAV (inside Docker container). Scans `/mnt/truenas_media/whisparr/downloads/complete`
- **Script**: `/home/robert/scripts/torrent_antivirus.sh`
- **Log**: `/home/robert/scripts/clamav_scan.log`
- **Runs**: Daily at 03:00
- **Manual**: `bash /home/robert/scripts/torrent_antivirus.sh`

### 6. `0 4 * * *` — Daily pipeline backup (rsync)
```
0 4 * * * rsync -avz --delete /mnt/truenas_media/whisparr/downloads/complete/ /mnt/truenas_media/whisparr/downloads/backup/diario/ >> /home/robert/scripts/backup_pipeline.log 2>&1
```
- **What**: Rsyncs completed torrent downloads to a daily backup folder on the same TrueNAS share. Retention handled by rsync --delete
- **Log**: `/home/robert/scripts/backup_pipeline.log`
- **Runs**: Daily at 04:00
- **Manual**: `rsync -avz --delete /mnt/truenas_media/whisparr/downloads/complete/ /mnt/truenas_media/whisparr/downloads/backup/diario/`

### 7. `30 3 * * 1,3,5` — Full pipeline config backup
```
30 3 * * 1,3,5 /home/robert/scripts/backup_pipeline.sh >> /home/robert/scripts/backup_pipeline.log 2>&1
```
- **What**: Backs up Whisparr/Prowlarr/qBittorrent configs and scripts. Separate from the rsync data backup above
- **Script**: `/home/robert/scripts/backup_pipeline.sh`
- **Log**: `/home/robert/scripts/backup_pipeline.log`
- **Runs**: Mon/Wed/Fri at 03:30
- **Manual**: `bash /home/robert/scripts/backup_pipeline.sh`

---

## Pi4 (raspberrypi4) — 2 cron jobs

### 1. @reboot — Enable multi-arch Docker support
```
@reboot docker run --privileged --rm tonistiigi/binfmt --install x86_64
```
- **What**: Same as Pi5 — installs QEMU binfmt handlers for cross-arch containers
- **Runs**: Every boot
- **Manual**: `docker run --privileged --rm tonistiigi/binfmt --install x86_64`

### 2. `0 3 * * 1,3,5` — Full multi-Pi backup
```
0 3 * * 1,3,5 /home/robert/Documents/backup/backup_rpi.sh
```
- **What**: Master backup script. Backs up configs from ALL 3 Pis (Pi4, Pi5-108, Pi501-117) sequentially:
  - Docker configs (Whisparr, Prowlarr, qBittorrent)
  - Scripts directories
  - Crontab dumps
  - Dashy conf.yml
  - Documentation
  - Runs ClamAV on Pi5 before backup
  - Syncs to TrueNAS share if mounted
  - Git commit+push if repo configured
  - Cleans backups older than 30 days
- **Script**: `/home/robert/Documents/backup/backup_rpi.sh`
- **Log**: `/home/robert/Documents/backup/logs/backup_YYYYMMDD_HHMMSS.log`
- **Runs**: Mon/Wed/Fri at 03:00
- **Manual**: `bash /home/robert/Documents/backup/backup_rpi.sh`

> **Note**: The commented-out line `#0 3 * * * /home/robert/Documents/backup/backup_rpi.sh` is a leftover from a previous daily schedule — only the Mon/Wed/Fri line is active.

---

## Pi501-117 (raspberrypi501) — 1 cron job

### 1. `0 0,6,12,18 * * *` — NewsBot v3
```
0 0,6,12,18 * * * cd /home/robert/Documents/vscode_projects/news_colletector && bash run_newsbot.sh >> /home/robert/Documents/vscode_projects/news_colletector/logs/cron.log 2>&1
```
- **What**: Collects RSS feeds, generates audio summaries, posts to Telegram. Runs 4x daily with nice/ionice for low priority
- **Script**: `/home/robert/Documents/vscode_projects/news_colletector/run_newsbot.sh`
- **Python venv**: `/home/robert/Documents/vscode_projects/news_colletector/venv/`
- **Log**: `/home/robert/Documents/vscode_projects/news_colletector/logs/cron.log`
- **Runs**: Daily at 00:00, 06:00, 12:00, 18:00
- **Manual**: `cd /home/robert/Documents/vscode_projects/news_colletector && bash run_newsbot.sh`
- **Dry run**: `cd /home/robert/Documents/vscode_projects/news_colletector && bash run_newsbot.sh --dry-run`
- **Single feed**: `cd /home/robert/Documents/vscode_projects/news_colletector && bash run_newsbot.sh --feed N` (where N = feed index)

---

## Summary Table

| Schedule | Pi | Cron | Description |
|----------|----|------|-------------|
| @reboot | Pi5-108 | `binfmt --install x86_64` | Multi-arch Docker |
| @reboot | Pi4 | `binfmt --install x86_64` | Multi-arch Docker |
| `*/5 * * * *` | Pi5-108 | `guardian.sh` | System health check |
| `*/5 * * * *` | Pi5-108 | `mount_cifs.sh` | CIFS mount watchdog |
| `0 */6 * * *` | Pi5-108 | `torrent_health_cron.sh` | Torrent health check |
| `0 3 * * *` | Pi5-108 | `torrent_antivirus.sh` | ClamAV daily scan |
| `0 4 * * *` | Pi5-108 | `rsync backup` | Daily pipeline data backup |
| `30 3 * * 1,3,5` | Pi5-108 | `backup_pipeline.sh` | Config backup (Mon/Wed/Fri) |
| `0 3 * * 1,3,5` | Pi4 | `backup_rpi.sh` | Full multi-Pi backup (Mon/Wed/Fri) |
| `0 0,6,12,18 * * *` | Pi501-117 | `run_newsbot.sh` | NewsBot RSS collection (4x daily) |

---

## Quick Manual Execution Reference

```bash
# === Pi5-108 ===
ssh robert@192.168.68.108

# Guardian health check
bash /home/robert/scripts/guardian.sh

# Remount CIFS share
bash /home/robert/scripts/mount_cifs.sh

# Torrent health recheck
bash /home/robert/scripts/torrent_health_cron.sh

# ClamAV antivirus scan
bash /home/robert/scripts/torrent_antivirus.sh

# Daily pipeline rsync
rsync -avz --delete /mnt/truenas_media/whisparr/downloads/complete/ /mnt/truenas_media/whisparr/downloads/backup/diario/

# Pipeline config backup
bash /home/robert/scripts/backup_pipeline.sh

# === Pi4 ===
ssh robert@192.168.68.102

# Full multi-Pi backup
bash /home/robert/Documents/backup/backup_rpi.sh

# === Pi501-117 (local) ===

# NewsBot full run
cd /home/robert/Documents/vscode_projects/news_colletector && bash run_newsbot.sh

# NewsBot dry run
cd /home/robert/Documents/vscode_projects/news_colletector && bash run_newsbot.sh --dry-run
```

---

## Environment Variables (from Pi4 backup script)

- **SSH password**: `Totvs@123#456` (used for inter-Pi SSH access)
- **qBittorrent WebUI**: `admin` / `whisparr2026`
- **TrueNAS SMB**: `robert` / `Totvs@123#456` (in `/etc/smbcredentials/truenas`)
- **Telegram**: From `~/backup.env` (TELEGRAM_TOKEN, TELEGRAM_CHAT_ID)

---

## Notes

1. **Time zone**: All cron schedules run in `Europe/Dublin` (IST, UTC+1)
2. **Memory from audit**: The old audit mentioned NewsBot on Pi4 at `0 8,20 * * *` but the actual crontab only has the commented-out daily schedule — the **active** NewsBot runs on **Pi501-117** at `0,6,12,18`
3. **Backup schedule correction**: The `nextRun()` JS function in the portfolio HTML says "03:30" but the actual backup runs at **03:00**. This is corrected below.
4. **Health report**: Generated by `/home/robert/Documents/portfolio-html/health_report.sh` which runs on Pi501-117 and collects from all 3 Pis
