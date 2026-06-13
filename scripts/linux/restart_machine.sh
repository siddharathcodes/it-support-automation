#!/bin/bash
# ============================================================
# restart_machine.sh — Schedule or cancel a system restart
# IT Support Automation Toolkit
# Usage: sudo ./restart_machine.sh [--delay 10] [--force] [--cancel] [--message "reason"]
# ============================================================

DELAY=5
FORCE=false
CANCEL=false
MESSAGE="IT Support: Scheduled system restart. Please save your work."

while [[ "$1" != "" ]]; do
    case $1 in
        --delay)   shift; DELAY="$1" ;;
        --force)   FORCE=true ;;
        --cancel)  CANCEL=true ;;
        --message) shift; MESSAGE="$1" ;;
    esac
    shift
done

if [[ $EUID -ne 0 ]]; then
    echo "[✖] Run as root: sudo ./restart_machine.sh"
    exit 1
fi

echo ""
echo "══════════════════════════════════════════"
echo "  Restart Manager — $(hostname)"
echo "══════════════════════════════════════════"
echo ""

if [ "$CANCEL" = true ]; then
    shutdown -c 2>/dev/null && echo "  [✔] Pending restart cancelled." || echo "  [!] No pending restart found."
    echo ""
    exit 0
fi

echo "  Delay  : $DELAY minute(s)"
echo "  Message: $MESSAGE"
echo ""

if [ "$FORCE" = false ]; then
    read -rp "  Proceed with restart? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        echo "  Restart cancelled."
        exit 0
    fi
fi

# Broadcast message to logged-in users
wall "$MESSAGE"

shutdown -r "+$DELAY" "$MESSAGE"
echo ""
echo "  [✔] Restart scheduled in $DELAY minute(s)."
echo "  Run with --cancel to abort."
echo ""
