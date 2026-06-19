# IT Support Automation Toolkit

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-121011?style=flat&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![License](https://img.shields.io/github/license/siddharathcodes/it-support-automation)

Production-grade IT support automation scripts for Windows, Linux, and cross-platform environments.
Covers system info, updates, backups, app installs, auto-repair, network drives, and host monitoring.

---

## Quick Start

### Windows (run as Administrator)

```powershell
# Step 1 - Clone or download the repo
git clone https://github.com/siddharathcodes/it-support-automation.git
cd it-support-automation

# Step 2 - Run setup (one time only)
.\SETUP.bat

# Step 3 - Launch master control panel
powershell -ExecutionPolicy Bypass -File .\scripts\windows\master.ps1
```

### Without cloning (run directly from internet)

```powershell
irm https://raw.githubusercontent.com/siddharathcodes/it-support-automation/main/scripts/windows/system_info.ps1 | iex
```

### Linux

```bash
chmod +x scripts/linux/*.sh
sudo ./scripts/linux/system_info.sh --export
sudo ./scripts/linux/run_updates.sh
```

---

## Repo Structure

```
it-support-automation/
├── SETUP.bat                        # One-click setup for Windows
├── scripts/
│   ├── windows/
│   │   ├── master.ps1               # Master control panel (run this)
│   │   ├── system_info.ps1          # Full system snapshot + export
│   │   ├── install_apps.ps1         # Numbered app installer menu
│   │   ├── run_updates.ps1          # Windows Update automation
│   │   ├── backup_user_data.ps1     # User profile backup + ZIP
│   │   ├── auto_repair.ps1          # SFC + DISM + drivers + network fix
│   │   ├── map_network_drives.ps1   # Map/unmap network drives
│   │   └── restart_machine.ps1      # Scheduled/remote restart
│   ├── linux/
│   │   ├── system_info.sh           # Full system snapshot
│   │   ├── install_apps.sh          # Package install by profile
│   │   ├── run_updates.sh           # Cross-distro update script
│   │   ├── backup_user_data.sh      # rsync-based user backup
│   │   └── restart_machine.sh       # Scheduled restart + broadcast
│   └── cross-platform/
│       └── ping_check.py            # Parallel host ping checker
├── docs/
│   └── public/
│       ├── ENTERPRISE_IT_GUIDE.md   # A-Z enterprise IT operations guide
│       └── USAGE.md                 # Full flag reference for every script
└── .gitignore
```

---

## What Each Script Does

| Script | What it solves |
|--------|---------------|
| `master.ps1` | Single numbered menu — run everything from one place |
| `system_info.ps1` | PC slow? Audit a machine? Export full report |
| `install_apps.ps1` | New PC setup — pick apps by number, installs silently |
| `run_updates.ps1` | Monthly patching, force update any machine |
| `backup_user_data.ps1` | Before reimaging, offboarding, failing disk |
| `auto_repair.ps1` | Corrupt files, broken drivers, internet issues, stuck updates |
| `map_network_drives.ps1` | New hire onboarding, drives lost after reboot |
| `restart_machine.ps1` | After updates, remote reboot with delay |
| `ping_check.py` | Network down — check which hosts are alive |

---

## Enterprise IT Guide

The `docs/public/ENTERPRISE_IT_GUIDE.md` covers A-Z operations for 50-500 user companies:

- Active Directory and user lifecycle management
- VLAN segmentation and firewall rules
- Printer setup, print servers, stuck queue fixes
- IP camera placement and NVR configuration
- Mobile Device Management (Intune, Jamf)
- Backup and disaster recovery (3-2-1 rule, Veeam, Restic)
- Security hardening and incident response playbooks
- Monitoring with Zabbix, Grafana, Uptime Kuma
- Onboarding and offboarding automation
- Full automation maturity roadmap (scripts to Ansible to Terraform)

---

## Requirements

- **Windows scripts:** PowerShell 5.1+, winget (App Installer from Microsoft Store)
- **Linux scripts:** bash, rsync, curl
- **Python script:** Python 3.8+ (no external packages needed)

---

## License

MIT License - see LICENSE file for details.
