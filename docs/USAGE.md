# 📖 IT Support Automation — Usage Guide

> When to use each script, how to run it, and what the flags do.

---

## Table of Contents
1. [Windows Scripts](#windows-scripts)
   - [system_info.ps1](#1-system_infops1)
   - [map_network_drives.ps1](#2-map_network_drivesps1)
   - [install_apps.ps1](#3-install_appsps1)
   - [run_updates.ps1](#4-run_updatesps1)
   - [backup_user_data.ps1](#5-backup_user_dataps1)
   - [restart_machine.ps1](#6-restart_machineps1)
2. [Linux Scripts](#linux-scripts)
   - [system_info.sh](#7-system_infosh)
   - [install_apps.sh](#8-install_appssh)
   - [run_updates.sh](#9-run_updatessh)
   - [backup_user_data.sh](#10-backup_user_datash)
   - [restart_machine.sh](#11-restart_machinesh)
3. [Cross-Platform](#cross-platform)
   - [ping_check.py](#12-ping_checkpy)
4. [Pro Tips](#pro-tips)

---

## Windows Scripts

> **Before running any `.ps1` script**, open PowerShell as Administrator and run:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

### 1. `system_info.ps1`

**What it does:** Pulls a full snapshot of the machine — OS version, CPU, RAM, disk usage, network adapters, local users, and running services.

**When to use it:**
- A user reports their PC is slow — check RAM and top processes
- You're setting up a new machine and need to document its specs
- Auditing machines before a software deployment
- Generating a report to send to a client or manager

**How to run it:**
```powershell
# Basic — just print to screen
.\scripts\windows\system_info.ps1

# Export to a .txt file on the Desktop
.\scripts\windows\system_info.ps1 -Export

# Export to a custom folder
.\scripts\windows\system_info.ps1 -Export -OutputPath "C:\IT_Reports"
```

**Output example:**
```
══ OPERATING SYSTEM ══
  OS Name    : Windows 11 Pro
  Version    : 10.0.22631
  Uptime     : 02d 04h 12m

══ DISK USAGE ══
  C:  Size: 476.9 GB  Free: 120.3 GB  Used: 74.8%
```

---

### 2. `map_network_drives.ps1`

**What it does:** Maps or unmaps shared network drives for a user. Has a built-in drive config table you can customise for your org (H: Home, S: Shared, T: Tools).

**When to use it:**
- New employee onboarding — map all org drives in one shot
- A user lost their network drives after a reboot
- Cleaning up stale drive mappings before reimaging
- Mapping a single specific share for a one-off task

**How to run it:**
```powershell
# List currently mapped drives
.\scripts\windows\map_network_drives.ps1 -Action List

# Map all predefined drives (edit $DriveMap in the script first)
.\scripts\windows\map_network_drives.ps1 -Action Map

# Map a single drive manually
.\scripts\windows\map_network_drives.ps1 -Action Map -DriveLetter Z -UNCPath "\\fileserver\projects"

# Map persistently (survives reboots)
.\scripts\windows\map_network_drives.ps1 -Action Map -Persistent

# Unmap a specific drive
.\scripts\windows\map_network_drives.ps1 -Action Unmap -DriveLetter Z

# Unmap all predefined drives
.\scripts\windows\map_network_drives.ps1 -Action Unmap
```

**Customise the drive list** (open the script and edit this block):
```powershell
$DriveMap = @(
    @{ Letter = "H"; Path = "\\YOUR-SERVER\home\$env:USERNAME"; Label = "Home Drive" }
    @{ Letter = "S"; Path = "\\YOUR-SERVER\shared";             Label = "Shared Files" }
)
```

---

### 3. `install_apps.ps1`

**What it does:** Silently installs software in bulk using `winget`. Has three built-in profiles: Basic (browsers, 7-Zip, Teams), Developer (VS Code, Git, Node, Docker), Security (Malwarebytes, Wireshark, Nmap).

**When to use it:**
- Onboarding a new employee — run Basic profile in minutes
- Setting up a developer workstation
- Provisioning a security analyst machine
- Installing one specific app without opening a browser

**Requirements:** `winget` must be installed (comes with Windows 11 / App Installer from the Microsoft Store).

**How to run it:**
```powershell
# Install basic apps (browsers, office tools)
.\scripts\windows\install_apps.ps1 -Profile Basic

# Install developer tools
.\scripts\windows\install_apps.ps1 -Profile Developer

# Install security tools
.\scripts\windows\install_apps.ps1 -Profile Security

# Install a single app by winget ID
.\scripts\windows\install_apps.ps1 -AppId "Slack.Slack"

# Preview what would be installed without installing
.\scripts\windows\install_apps.ps1 -Profile Developer -ListOnly
```

**Find a winget app ID:**
```powershell
winget search "app name"
# Example: winget search "visual studio code"
# Returns: Microsoft.VisualStudioCode
```

---

### 4. `run_updates.ps1`

**What it does:** Checks for and installs Windows Updates silently using the `PSWindowsUpdate` module (auto-installs it if missing). Optionally auto-restarts the machine.

**When to use it:**
- Monthly patch Tuesday — run on all machines
- A machine is flagged as out of date
- Pre-deployment check before pushing new software
- Remote remediation when a machine needs urgent security patches

**How to run it:**
```powershell
# Check and install updates, prompt for restart
.\scripts\windows\run_updates.ps1

# Auto-restart after updates (no prompt)
.\scripts\windows\run_updates.ps1 -AutoRestart

# Include driver updates
.\scripts\windows\run_updates.ps1 -DriverUpdates

# Everything — updates + drivers + auto-restart
.\scripts\windows\run_updates.ps1 -AutoRestart -DriverUpdates
```

> **Note:** Run PowerShell as Administrator, otherwise Windows Update access will fail.

---

### 5. `backup_user_data.ps1`

**What it does:** Copies user profile folders (Documents, Downloads, Pictures, Videos, Outlook data) to a backup destination. Optionally compresses to a `.zip`.

**When to use it:**
- Before reimaging or replacing a machine
- User's hard drive is failing — grab data fast
- End-of-contract offboarding
- Routine scheduled backup before a Windows upgrade

**How to run it:**
```powershell
# Backup current user to D:\IT_Backups
.\scripts\windows\backup_user_data.ps1

# Backup a specific user
.\scripts\windows\backup_user_data.ps1 -User "john.doe"

# Backup to a custom location
.\scripts\windows\backup_user_data.ps1 -Destination "\\fileserver\backups"

# Include Desktop folder
.\scripts\windows\backup_user_data.ps1 -IncludeDesktop

# Compress backup to a .zip file
.\scripts\windows\backup_user_data.ps1 -Compress

# Dry run — see what would be backed up without copying anything
.\scripts\windows\backup_user_data.ps1 -DryRun

# Full backup for offboarding
.\scripts\windows\backup_user_data.ps1 -User "jane.doe" -Destination "D:\Offboarding" -IncludeDesktop -Compress
```

---

### 6. `restart_machine.ps1`

**What it does:** Schedules a restart with a broadcast message, optional delay, and supports remote machines. Can also cancel a pending restart.

**When to use it:**
- After Windows Updates to apply changes
- After installing software that requires a reboot
- Remotely restarting a machine that's become unresponsive
- Scheduling a restart for off-hours (give users a delay)

**How to run it:**
```powershell
# Restart in 5 minutes (default), with confirmation prompt
.\scripts\windows\restart_machine.ps1

# Restart in 10 minutes
.\scripts\windows\restart_machine.ps1 -DelayMinutes 10

# Custom message to users
.\scripts\windows\restart_machine.ps1 -Message "Applying security patch — restart in 5 min"

# Force restart without prompt
.\scripts\windows\restart_machine.ps1 -Force

# Restart a remote machine (requires WinRM enabled on target)
.\scripts\windows\restart_machine.ps1 -Remote "DESKTOP-ABC123"

# Cancel a scheduled restart
.\scripts\windows\restart_machine.ps1 -Cancel
```

---

## Linux Scripts

> **Most scripts require root.** Always run with `sudo`.
> Make scripts executable first: `chmod +x scripts/linux/*.sh`

---

### 7. `system_info.sh`

**What it does:** Prints a full system snapshot — OS, CPU, memory, disk, network, logged-in users, running services, and top processes.

**When to use it:**
- SSH'd into a server and need a quick health check
- Diagnosing performance issues
- Documenting a server before making changes
- Incident response — baseline the system state

**How to run it:**
```bash
# Print to screen
sudo ./scripts/linux/system_info.sh

# Export to a file in /tmp
sudo ./scripts/linux/system_info.sh --export

# Export to custom directory
sudo ./scripts/linux/system_info.sh --export --output /var/log/it-reports
```

---

### 8. `install_apps.sh`

**What it does:** Installs common IT tools using the distro's native package manager (apt, dnf, yum, pacman). Three profiles: basic, developer, security.

**When to use it:**
- Provisioning a new Linux workstation or server
- Setting up a dev environment on a fresh Ubuntu/CentOS box
- Installing security audit tools on a test machine
- Installing a single missing package

**How to run it:**
```bash
# Install basic tools (curl, wget, git, htop, vim, etc.)
sudo ./scripts/linux/install_apps.sh --profile basic

# Install developer tools (node, python3, docker, jq, etc.)
sudo ./scripts/linux/install_apps.sh --profile developer

# Install security tools (nmap, wireshark, fail2ban, etc.)
sudo ./scripts/linux/install_apps.sh --profile security

# Install a single package
sudo ./scripts/linux/install_apps.sh --pkg neofetch
```

---

### 9. `run_updates.sh`

**What it does:** Detects your distro's package manager and runs a full update + upgrade + cleanup cycle. Supports apt, dnf, yum, zypper, and pacman.

**When to use it:**
- Monthly patching of Linux servers
- Before installing new software (ensure deps are fresh)
- Post-deployment hygiene
- Security incident response — patch immediately

**How to run it:**
```bash
# Full update
sudo ./scripts/linux/run_updates.sh

# Update and auto-restart if required
sudo ./scripts/linux/run_updates.sh --auto-restart

# Dry run — see what would be updated
sudo ./scripts/linux/run_updates.sh --dry-run
```

**Log file** is saved automatically to `/var/log/it_updates_<timestamp>.log`.

---

### 10. `backup_user_data.sh`

**What it does:** Uses `rsync` to back up key user folders (Documents, Downloads, Pictures, .config, .ssh). Creates timestamped backups.

**When to use it:**
- Before upgrading Ubuntu to a new LTS version
- Before wiping and reinstalling a Linux workstation
- Backing up a remote user's home directory via SSH
- Protecting `.ssh` keys and `.config` before a migration

**How to run it:**
```bash
# Backup current user to /mnt/backups
sudo ./scripts/linux/backup_user_data.sh

# Backup a specific user
sudo ./scripts/linux/backup_user_data.sh --user john

# Backup to a custom destination
sudo ./scripts/linux/backup_user_data.sh --dest /media/external/backups

# Dry run — preview without copying
sudo ./scripts/linux/backup_user_data.sh --dry-run

# Full offboarding backup
sudo ./scripts/linux/backup_user_data.sh --user jane --dest /mnt/offboarding
```

**SSH backup to remote machine:**
```bash
rsync -az /home/user/ user@remote-server:/backups/user/
```

---

### 11. `restart_machine.sh`

**What it does:** Schedules a system restart with a broadcast `wall` message to all logged-in users. Supports cancel.

**When to use it:**
- After kernel or glibc updates that require a reboot
- Scheduled maintenance windows on a server
- Giving remote users time to save work before restart
- Cancelling a restart someone scheduled by mistake

**How to run it:**
```bash
# Restart in 5 minutes (default)
sudo ./scripts/linux/restart_machine.sh

# Restart in 15 minutes
sudo ./scripts/linux/restart_machine.sh --delay 15

# Custom message to logged-in users
sudo ./scripts/linux/restart_machine.sh --message "Server restarting at 11pm for kernel update"

# Force restart, no confirmation prompt
sudo ./scripts/linux/restart_machine.sh --force

# Cancel a scheduled restart
sudo ./scripts/linux/restart_machine.sh --cancel
```

---

## Cross-Platform

### 12. `ping_check.py`

**What it does:** Pings a list of hosts in parallel, shows UP/DOWN/TIMEOUT status with latency, and optionally exports a report. Works on Windows, Linux, and macOS.

**When to use it:**
- Network is acting up — check which hosts are reachable
- Before and after a router/switch change
- Monitoring a list of critical servers
- Verifying VPN connectivity (ping internal IPs through the VPN)
- Generating a quick reachability report for a client

**Requirements:** Python 3.8+ (no pip installs needed — stdlib only)

**How to run it:**
```bash
# Ping the default host list
python scripts/cross-platform/ping_check.py

# Ping specific hosts
python scripts/cross-platform/ping_check.py --hosts 192.168.1.1 8.8.8.8 google.com

# Load hosts from a file (one per line)
python scripts/cross-platform/ping_check.py --file my_hosts.txt

# More pings per host (better accuracy)
python scripts/cross-platform/ping_check.py --count 10

# Export results to a .txt report
python scripts/cross-platform/ping_check.py --export

# More parallel threads (faster for large host lists)
python scripts/cross-platform/ping_check.py --threads 20

# Full production check
python scripts/cross-platform/ping_check.py --file servers.txt --count 5 --export --threads 15
```

**Example `hosts.txt`:**
```
# Critical infrastructure
192.168.1.1       # Gateway
192.168.1.10      # DNS server
192.168.1.20      # File server
8.8.8.8           # Google DNS (internet check)
```

**Exit codes:** `0` = all hosts up, `1` = one or more hosts down (useful for scripts/monitoring).

---

## Pro Tips

**Run Windows scripts on multiple machines:**
```powershell
# Loop over a list of PCs (requires WinRM/PSRemoting)
$machines = @("PC-001", "PC-002", "PC-003")
foreach ($m in $machines) {
    Invoke-Command -ComputerName $m -FilePath .\scripts\windows\run_updates.ps1
}
```

**Schedule a script to run automatically (Windows Task Scheduler):**
```powershell
$action  = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\it-support-automation\scripts\windows\run_updates.ps1 -AutoRestart"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Tuesday -At 11pm
Register-ScheduledTask -TaskName "IT_WeeklyUpdates" -Action $action -Trigger $trigger -RunLevel Highest
```

**Schedule a Linux script with cron:**
```bash
# Open crontab
sudo crontab -e

# Run updates every Sunday at 2am
0 2 * * 0 /opt/it-support-automation/scripts/linux/run_updates.sh --auto-restart

# Run system_info backup every day at 6am
0 6 * * * /opt/it-support-automation/scripts/linux/system_info.sh --export --output /var/log/it-reports
```

**Git push workflow:**
```bash
git init
git remote add origin https://github.com/siddharathcodes/it-support-automation.git
git add .
git commit -m "feat: IT support automation toolkit"
git push -u origin main
```
