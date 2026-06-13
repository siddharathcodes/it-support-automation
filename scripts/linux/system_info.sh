#!/bin/bash
# ============================================================
# system_info.sh — Gather comprehensive system information
# IT Support Automation Toolkit
# Usage: sudo ./system_info.sh [--export] [--output /path/to/dir]
# ============================================================

EXPORT=false
OUTPUT_DIR="/tmp"

while [[ "$1" != "" ]]; do
    case $1 in
        --export) EXPORT=true ;;
        --output) shift; OUTPUT_DIR="$1" ;;
    esac
    shift
done

REPORT_FILE="$OUTPUT_DIR/sysinfo_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"
BUFFER=""

section() {
    echo ""
    echo "══════════════════════════════════════════"
    echo "  $1"
    echo "══════════════════════════════════════════"
}

capture() {
    local output
    output=$(eval "$1" 2>/dev/null)
    echo "$output"
    BUFFER+="$output\n"
}

# ── OS Info ─────────────────────────────────────────────────
section "OPERATING SYSTEM"
capture "uname -a"
if [ -f /etc/os-release ]; then
    capture "cat /etc/os-release | grep -E 'NAME|VERSION'"
fi
capture "uptime -p"

# ── CPU ─────────────────────────────────────────────────────
section "CPU"
capture "lscpu | grep -E 'Model name|Architecture|CPU\(s\)|Thread|Core'"

# ── Memory ──────────────────────────────────────────────────
section "MEMORY"
capture "free -h"

# ── Disk ────────────────────────────────────────────────────
section "DISK USAGE"
capture "df -hT | grep -v tmpfs | grep -v udev"

# ── Network ─────────────────────────────────────────────────
section "NETWORK"
if command -v ip &>/dev/null; then
    capture "ip -4 addr show | grep -E 'inet |^[0-9]'"
else
    capture "ifconfig | grep -E 'inet |^[a-z]'"
fi
echo ""
echo "  Default Gateway:"
capture "ip route | grep default"

# ── Users ───────────────────────────────────────────────────
section "LOGGED IN USERS"
capture "who"

section "LOCAL USERS (with login shell)"
capture "getent passwd | grep -v nologin | grep -v false | cut -d: -f1,5,7"

# ── Running Services ─────────────────────────────────────────
section "RUNNING SERVICES (Top 20)"
if command -v systemctl &>/dev/null; then
    capture "systemctl list-units --type=service --state=running --no-pager | head -25"
else
    capture "service --status-all 2>&1 | grep + | head -20"
fi

# ── Top Processes ────────────────────────────────────────────
section "TOP 10 PROCESSES (CPU)"
capture "ps aux --sort=-%cpu | head -11"

# ── Installed Packages ───────────────────────────────────────
section "INSTALLED PACKAGES"
if command -v dpkg &>/dev/null; then
    COUNT=$(dpkg -l | grep -c "^ii")
    echo "  apt/dpkg packages installed: $COUNT"
elif command -v rpm &>/dev/null; then
    COUNT=$(rpm -qa | wc -l)
    echo "  rpm packages installed: $COUNT"
fi

# ── Export ──────────────────────────────────────────────────
if [ "$EXPORT" = true ]; then
    {
        echo "=== System Report: $(hostname) | $(date) ==="
        uname -a
        echo "--- OS ---"
        cat /etc/os-release 2>/dev/null
        echo "--- CPU ---"
        lscpu
        echo "--- Memory ---"
        free -h
        echo "--- Disk ---"
        df -hT
        echo "--- Network ---"
        ip addr 2>/dev/null || ifconfig 2>/dev/null
        echo "--- Users ---"
        who
    } > "$REPORT_FILE"
    echo ""
    echo "[✔] Report exported to: $REPORT_FILE"
fi

echo ""
echo "[✔] System info complete."
echo ""
