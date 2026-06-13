#!/bin/bash
# ============================================================
# run_updates.sh — Full system update across distros
# IT Support Automation Toolkit
# Usage: sudo ./run_updates.sh [--auto-restart] [--dry-run]
# ============================================================

AUTO_RESTART=false
DRY_RUN=false

while [[ "$1" != "" ]]; do
    case $1 in
        --auto-restart) AUTO_RESTART=true ;;
        --dry-run)      DRY_RUN=true ;;
    esac
    shift
done

LOG_FILE="/var/log/it_updates_$(date +%Y%m%d_%H%M%S).log"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
section() { echo ""; log "══ $1 ══"; }

# ── Root check ───────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "[✖] This script must be run as root (sudo)."
    exit 1
fi

section "Starting System Update"
log "Hostname : $(hostname)"
log "Distro   : $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
log "Log file : $LOG_FILE"

if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN MODE — no changes will be made]"
fi

# ── Detect package manager ─────────────────────────────────
if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
else
    log "[✖] No supported package manager found."
    exit 1
fi

log "Package Manager: $PKG_MANAGER"

# ── Run updates ───────────────────────────────────────────
section "Updating Package Lists"
case $PKG_MANAGER in
    apt)
        if [ "$DRY_RUN" = false ]; then
            apt update -y 2>&1 | tee -a "$LOG_FILE"
        else
            apt update --dry-run 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    dnf|yum)
        if [ "$DRY_RUN" = false ]; then
            $PKG_MANAGER check-update 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    pacman)
        if [ "$DRY_RUN" = false ]; then
            pacman -Sy 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
esac

section "Upgrading Packages"
case $PKG_MANAGER in
    apt)
        if [ "$DRY_RUN" = false ]; then
            apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
            apt dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"
            apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
            apt autoclean 2>&1 | tee -a "$LOG_FILE"
        else
            apt upgrade --dry-run 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    dnf)
        if [ "$DRY_RUN" = false ]; then
            dnf upgrade -y 2>&1 | tee -a "$LOG_FILE"
        else
            dnf upgrade --assumeno 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    yum)
        if [ "$DRY_RUN" = false ]; then
            yum update -y 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    zypper)
        if [ "$DRY_RUN" = false ]; then
            zypper update -y 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    pacman)
        if [ "$DRY_RUN" = false ]; then
            pacman -Su --noconfirm 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
esac

# ── Reboot check ─────────────────────────────────────────────
section "Checking Reboot Required"
REBOOT_REQUIRED=false

if [ -f /var/run/reboot-required ]; then
    REBOOT_REQUIRED=true
    log "[!] Reboot required (detected via /var/run/reboot-required)"
fi

if [ "$REBOOT_REQUIRED" = true ]; then
    if [ "$AUTO_RESTART" = true ] && [ "$DRY_RUN" = false ]; then
        log "Auto-restart enabled. Rebooting in 1 minute..."
        shutdown -r +1 "IT Support: System restart after updates."
    else
        log "[!] Please restart the system at your earliest convenience."
    fi
fi

section "Update Complete"
log "[✔] All updates applied. Log: $LOG_FILE"
echo ""
