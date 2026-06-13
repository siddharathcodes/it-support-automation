#!/bin/bash
# ============================================================
# install_apps.sh — Install common IT tools by profile
# IT Support Automation Toolkit
# Usage: sudo ./install_apps.sh [--profile basic|developer|security] [--pkg package-name]
# ============================================================

PROFILE="basic"
SINGLE_PKG=""

while [[ "$1" != "" ]]; do
    case $1 in
        --profile) shift; PROFILE="$1" ;;
        --pkg)     shift; SINGLE_PKG="$1" ;;
    esac
    shift
done

# ── App profiles ───────────────────────────────────────────
BASIC_APPS=(curl wget git unzip zip htop net-tools vim nano)
DEVELOPER_APPS=(nodejs npm python3 python3-pip docker.io build-essential jq)
SECURITY_APPS=(nmap wireshark ufw fail2ban lynis chkrootkit)

# ── Detect package manager ─────────────────────────────────
if command -v apt &>/dev/null; then     PKG="apt";     INSTALL="apt install -y"
elif command -v dnf &>/dev/null; then   PKG="dnf";     INSTALL="dnf install -y"
elif command -v yum &>/dev/null; then   PKG="yum";     INSTALL="yum install -y"
elif command -v pacman &>/dev/null; then PKG="pacman"; INSTALL="pacman -S --noconfirm"
else echo "[✖] No supported package manager."; exit 1; fi

echo ""
echo "══════════════════════════════════════════"
echo "  App Installer | Profile: $PROFILE | PM: $PKG"
echo "══════════════════════════════════════════"
echo ""

install_pkg() {
    echo "  Installing: $1..."
    if $INSTALL "$1" &>/dev/null; then
        echo "  [✔] $1"
    else
        echo "  [✖] $1 — failed or not found"
    fi
}

if [ -n "$SINGLE_PKG" ]; then
    install_pkg "$SINGLE_PKG"
else
    case $PROFILE in
        basic)
            echo "  Packages: ${BASIC_APPS[*]}"
            echo ""
            for pkg in "${BASIC_APPS[@]}"; do install_pkg "$pkg"; done
            ;;
        developer)
            echo "  Packages: ${DEVELOPER_APPS[*]}"
            echo ""
            for pkg in "${DEVELOPER_APPS[@]}"; do install_pkg "$pkg"; done
            ;;
        security)
            echo "  Packages: ${SECURITY_APPS[*]}"
            echo ""
            for pkg in "${SECURITY_APPS[@]}"; do install_pkg "$pkg"; done
            ;;
        *)
            echo "[✖] Unknown profile: $PROFILE"
            exit 1
            ;;
    esac
fi

echo ""
echo "[✔] Installation complete."
echo ""
