# 🛠️ IT Support Automation Toolkit

A production-grade automation toolkit for IT Support Engineers — covering Windows, Linux, networking, printers, cameras, mobile, security, and full enterprise operations.

## 📁 Repo Structure

```
it-support-automation/
├── scripts/
│   ├── windows/
│   │   ├── system_info.ps1         # Full system snapshot
│   │   ├── map_network_drives.ps1  # Map/unmap network drives
│   │   ├── install_apps.ps1        # Silent bulk installs (winget)
│   │   ├── run_updates.ps1         # Windows Update automation
│   │   ├── backup_user_data.ps1    # User profile backup
│   │   └── restart_machine.ps1     # Scheduled/remote restart
│   ├── linux/
│   │   ├── system_info.sh          # Full system snapshot
│   │   ├── install_apps.sh         # Package install by profile
│   │   ├── run_updates.sh          # Cross-distro update script
│   │   ├── backup_user_data.sh     # rsync-based user backup
│   │   └── restart_machine.sh      # Scheduled restart + broadcast
│   └── cross-platform/
│       └── ping_check.py           # Parallel host ping checker
├── docs/
│   ├── public/
│   │   ├── ENTERPRISE_IT_GUIDE.md  # A–Z enterprise IT operations guide
│   │   └── USAGE.md                # How to use every script
│   └── private/                    # .gitignored — local only
└── .gitignore
```

## ⚡ Quick Start

### Windows (run as Administrator)
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\system_info.ps1
.\scripts\windows\install_apps.ps1 -Profile Basic
.\scripts\windows\run_updates.ps1 -AutoRestart
```

### Linux
```bash
chmod +x scripts/linux/*.sh
sudo ./scripts/linux/system_info.sh --export
sudo ./scripts/linux/run_updates.sh --auto-restart
```

### Python (cross-platform)
```bash
python scripts/cross-platform/ping_check.py --export
```

## 📚 Documentation

| Doc | What it covers |
|-----|----------------|
| [USAGE.md](docs/public/USAGE.md) | When and how to run every script |
| [ENTERPRISE_IT_GUIDE.md](docs/public/ENTERPRISE_IT_GUIDE.md) | Full A–Z IT operations — AD, networking, printers, cameras, MDM, security, monitoring, automation |

## ✅ What This Toolkit Solves

| Task | Windows | Linux |
|------|---------|-------|
| System info & auditing | ✅ | ✅ |
| Network drive mapping | ✅ | — |
| Bulk app installation | ✅ | ✅ |
| Patch management | ✅ | ✅ |
| User data backup | ✅ | ✅ |
| Scheduled restart | ✅ | ✅ |
| Host reachability check | ✅ Python | ✅ Python |

## 🔧 Requirements

- **Windows:** PowerShell 5.1+, winget (App Installer)
- **Linux:** bash, rsync, curl
- **Python:** 3.8+ (no external packages)

## 📖 Enterprise IT Guide Covers

- Active Directory & user lifecycle management
- VLAN segmentation & firewall rules
- Printer setup, print servers, CUPS
- IP camera placement & NVR configuration
- Mobile Device Management (Intune, Jamf)
- Backup & disaster recovery (3-2-1 rule, Veeam, Restic)
- Security hardening & incident response
- Monitoring (Zabbix, Grafana, Uptime Kuma)
- Onboarding & offboarding automation
- Cloud & SaaS management (M365, Google Workspace)
- Full automation maturity roadmap (scripts → Ansible → Terraform)

---

> Maintained by IT Support Engineering. Built for real-world SME environments (50–500 users).
