#!/bin/bash
# ============================================================
# backup_user_data.sh — rsync-based user data backup
# IT Support Automation Toolkit
# Usage: sudo ./backup_user_data.sh [--user john] [--dest /mnt/backup] [--dry-run]
# ============================================================

TARGET_USER="${USER}"
DEST_BASE="/mnt/backups"
DRY_RUN=false

while [[ "$1" != "" ]]; do
    case $1 in
        --user)   shift; TARGET_USER="$1" ;;
        --dest)   shift; DEST_BASE="$1" ;;
        --dry-run) DRY_RUN=true ;;
    esac
    shift
done

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SRC="/home/$TARGET_USER"
DEST="$DEST_BASE/$TARGET_USER/$TIMESTAMP"
LOG="$DEST/backup.log"

FOLDERS=("Documents" "Downloads" "Pictures" "Videos" ".config" ".ssh")

echo ""
echo "══════════════════════════════════════════"
echo "  Backup: $TARGET_USER → $DEST"
if [ "$DRY_RUN" = true ]; then echo "  [DRY RUN — no files copied]"; fi
echo "══════════════════════════════════════════"
echo ""

# ── Validate ──────────────────────────────────────────────
if [ ! -d "$SRC" ]; then
    echo "[✖] User home not found: $SRC"
    exit 1
fi

if ! command -v rsync &>/dev/null; then
    echo "[!] rsync not found. Installing..."
    apt install rsync -y 2>/dev/null || yum install rsync -y 2>/dev/null
fi

# ── Create destination ─────────────────────────────────────
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$DEST"
fi

# ── Backup loop ────────────────────────────────────────────
TOTAL_SIZE=0
declare -A RESULTS

for folder in "${FOLDERS[@]}"; do
    SRC_PATH="$SRC/$folder"
    DEST_PATH="$DEST/$folder"

    if [ ! -d "$SRC_PATH" ]; then
        echo "  [SKIP] $folder — not found"
        RESULTS[$folder]="SKIPPED"
        continue
    fi

    FOLDER_SIZE=$(du -sh "$SRC_PATH" 2>/dev/null | cut -f1)
    echo "  Copying $folder ($FOLDER_SIZE)..."

    RSYNC_OPTS="-az --progress"
    if [ "$DRY_RUN" = true ]; then RSYNC_OPTS="$RSYNC_OPTS --dry-run"; fi

    if rsync $RSYNC_OPTS "$SRC_PATH/" "$DEST_PATH/" 2>&1 | tee -a "$LOG" | tail -1; then
        echo "  [✔] $folder done"
        RESULTS[$folder]="OK"
    else
        echo "  [✖] $folder failed"
        RESULTS[$folder]="FAILED"
    fi
done

# ── Summary ────────────────────────────────────────────────
echo ""
echo "  ── Summary ──"
for folder in "${!RESULTS[@]}"; do
    printf "  %-20s %s\n" "$folder" "${RESULTS[$folder]}"
done

if [ "$DRY_RUN" = false ]; then
    BACKUP_SIZE=$(du -sh "$DEST" 2>/dev/null | cut -f1)
    echo ""
    echo "  Total backup size: $BACKUP_SIZE"
    echo "  Location: $DEST"
fi

echo ""
echo "[✔] Backup complete."
echo ""
