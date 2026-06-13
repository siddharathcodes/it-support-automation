# 🏢 Enterprise IT Support — Complete A to Z Guide
### Small to Mid-Size Company (50–500 Users)

> From day-one basics to full automation. Covers Windows, Linux, macOS, printers, cameras, mobile, networking, and everything in between.

---

## Table of Contents

1. [The IT Support Mindset](#1-the-it-support-mindset)
2. [Infrastructure Overview](#2-infrastructure-overview)
3. [User & Identity Management](#3-user--identity-management)
4. [Endpoint Management](#4-endpoint-management)
5. [Networking](#5-networking)
6. [Printers & Peripherals](#6-printers--peripherals)
7. [Cameras & Physical Security](#7-cameras--physical-security)
8. [Mobile Device Management](#8-mobile-device-management)
9. [Software & Licensing](#9-software--licensing)
10. [Backup & Disaster Recovery](#10-backup--disaster-recovery)
11. [Security & Compliance](#11-security--compliance)
12. [Monitoring & Alerting](#12-monitoring--alerting)
13. [Helpdesk & Ticketing](#13-helpdesk--ticketing)
14. [Automation Stack](#14-automation-stack)
15. [Cloud & SaaS Management](#15-cloud--saas-management)
16. [Documentation Standards](#16-documentation-standards)
17. [Vendor & Asset Management](#17-vendor--asset-management)
18. [Onboarding & Offboarding](#18-onboarding--offboarding)
19. [Disaster Scenarios & Playbooks](#19-disaster-scenarios--playbooks)
20. [Tools Reference](#20-tools-reference)

---

## 1. The IT Support Mindset

IT support is not just fixing computers. You are the **operational backbone** of the company. Every minute of downtime costs money. Every security gap is a liability.

**Core principles:**
- Document everything. If it's not written down, it didn't happen.
- Automate repetitive tasks. Manual work = future incidents.
- Least privilege always. Users get exactly what they need, nothing more.
- Test before deploying. Never push changes to prod on a Friday.
- Own your mistakes fast. Escalate early, not late.

**Ticket priority framework:**
```
P1 — CRITICAL   : Company-wide outage, server down, ransomware       → Respond in 15 min
P2 — HIGH       : Single dept down, email outage, VPN broken          → Respond in 1 hour
P3 — MEDIUM     : Single user issue, slow PC, printer down            → Respond same day
P4 — LOW        : Software requests, setup questions, training         → Respond in 2 days
```

---

## 2. Infrastructure Overview

### What a typical SME IT environment looks like:

```
INTERNET
    │
   [ISP Router / Modem]
    │
   [Firewall] ← pfSense / Fortinet / Cisco ASA
    │
   [Core Switch] ← Managed L2/L3 switch
    ├── [VLAN 10] — Staff workstations
    ├── [VLAN 20] — Servers
    ├── [VLAN 30] — Guest WiFi
    ├── [VLAN 40] — IP Cameras / IoT
    └── [VLAN 50] — Printers
         │
        [Access Points] ← Ubiquiti / Cisco Meraki
         │
    [File Server / NAS]   [Domain Controller]   [Mail Server / M365]
```

### Must-have servers for 50–500 users:
| Role | Software | Purpose |
|------|----------|---------|
| Domain Controller | Windows Server + AD DS | User auth, group policy |
| DNS / DHCP | AD-integrated or Pi-Hole | Name resolution, IP assignment |
| File Server | Windows Server / TrueNAS | Shared drives, home folders |
| Backup Server | Veeam / Bacula | Full system backups |
| Monitoring | Zabbix / Grafana + Prometheus | Uptime, alerts |
| Patch Management | WSUS / Ansible | Automated updates |
| Helpdesk | Freshdesk / osTicket | Ticket tracking |

---

## 3. User & Identity Management

### Active Directory (Windows)

**Create a user:**
```powershell
New-ADUser `
  -Name "John Doe" `
  -GivenName "John" `
  -Surname "Doe" `
  -SamAccountName "john.doe" `
  -UserPrincipalName "john.doe@company.com" `
  -AccountPassword (ConvertTo-SecureString "TempPass@123" -AsPlainText -Force) `
  -Enabled $true `
  -Path "OU=Staff,DC=company,DC=local" `
  -ChangePasswordAtLogon $true
```

**Reset a password:**
```powershell
Set-ADAccountPassword -Identity "john.doe" -Reset `
  -NewPassword (ConvertTo-SecureString "NewPass@456" -AsPlainText -Force)
Unlock-ADAccount -Identity "john.doe"
```

**Disable account (offboarding):**
```powershell
Disable-ADAccount -Identity "john.doe"
Move-ADObject -Identity (Get-ADUser "john.doe").DistinguishedName `
  -TargetPath "OU=Disabled,DC=company,DC=local"
```

**Group Policy basics:**
- Password policy: min 12 chars, complexity on, 90-day expiry
- Lock screen: auto-lock after 10 minutes
- USB restrictions: block USB storage company-wide via GPO
- Software restriction: whitelist approved apps only

### Linux / LDAP equivalent:
```bash
# Create user
sudo useradd -m -s /bin/bash -G sudo john.doe
sudo passwd john.doe

# Lock account
sudo usermod -L john.doe

# LDAP-based (for larger Linux environments)
ldapadduser john.doe staff
```

### MFA / SSO (critical for any company):
- **Small company (<50):** Google Workspace / Microsoft 365 built-in MFA
- **Mid company (50–500):** Okta, Azure AD, JumpCloud
- **Self-hosted:** Authentik, Keycloak

---

## 4. Endpoint Management

### Windows endpoints

**Group Policy Objects (GPO) you must have:**
```
Computer Config → Windows Settings → Security Settings:
  - Password Policy (min length 12, complexity)
  - Account Lockout (5 attempts, 30 min lockout)
  - Audit Policy (logon events, object access)

Computer Config → Admin Templates:
  - Disable USB storage
  - Disable autorun
  - Force Windows Defender on
  - Configure Windows Update (point to WSUS)

User Config → Admin Templates:
  - Restrict Control Panel access
  - Map network drives by OU
  - Desktop wallpaper policy
```

**WSUS — Windows Server Update Services:**
```powershell
# On WSUS server — approve critical updates
Get-WsusUpdate -Classification Critical -Approval Unapproved |
  Approve-WsusUpdate -Action Install -TargetGroupName "All Computers"
```

**Inventory all domain machines:**
```powershell
Get-ADComputer -Filter * -Properties LastLogonDate, OperatingSystem |
  Select Name, OperatingSystem, LastLogonDate |
  Export-Csv "C:\Reports\endpoints.csv" -NoTypeInformation
```

### Linux endpoints (Ubuntu/Debian)

**Puppet / Ansible for config management (god tier):**
```yaml
# Ansible playbook — apply to all Linux workstations
- name: Enforce baseline config
  hosts: workstations
  become: yes
  tasks:
    - name: Ensure UFW is enabled
      ufw: state=enabled

    - name: Disable root SSH login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'

    - name: Set automatic security updates
      apt:
        name: unattended-upgrades
        state: present
```

### macOS endpoints
```bash
# Enroll in MDM (Jamf / Kandji) for fleet management
# Basic hardening:
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool NO
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool YES
# Enable FileVault encryption:
sudo fdesetup enable
```

---

## 5. Networking

### VLANs — why you need them
Segment your network so a compromised printer can't reach payroll servers.

```
VLAN 10  192.168.10.0/24  — Staff workstations
VLAN 20  192.168.20.0/24  — Servers
VLAN 30  192.168.30.0/24  — Guest WiFi (internet only, isolated)
VLAN 40  192.168.40.0/24  — IP Cameras (no internet, local only)
VLAN 50  192.168.50.0/24  — Printers
VLAN 60  192.168.60.0/24  — VoIP phones
```

### DHCP reservations (must-do for servers/printers):
```
Assign static IPs (or DHCP reservations by MAC) to:
- All servers
- All printers
- IP cameras
- Network switches / APs
- NAS devices
```

### DNS management:
```powershell
# Add internal DNS record (Windows DNS)
Add-DnsServerResourceRecordA -Name "fileserver" -ZoneName "company.local" -IPv4Address "192.168.20.10"

# Add PTR (reverse lookup)
Add-DnsServerResourceRecordPtr -Name "10" -ZoneName "20.168.192.in-addr.arpa" -PtrDomainName "fileserver.company.local"
```

### VPN setup:
- **WireGuard** — fastest, modern, self-hosted
- **OpenVPN** — mature, widely supported
- **Tailscale** — easiest setup, zero-config mesh VPN, great for SMEs

```bash
# WireGuard quick setup (server)
apt install wireguard
wg genkey | tee privatekey | wg pubkey > publickey
# Configure /etc/wireguard/wg0.conf
systemctl enable --now wg-quick@wg0
```

### Firewall rules (pfSense/OPNsense baseline):
```
ALLOW  LAN → WAN       (internet access)
ALLOW  LAN → SERVERS   (port 443, 445, 3389 only)
BLOCK  CAMERAS → WAN   (cameras never reach internet)
BLOCK  GUEST → LAN     (guest WiFi internet only)
BLOCK  ANY → ANY       (default deny all)
```

### Network troubleshooting toolkit:
```bash
# Check connectivity
ping -c 4 8.8.8.8
traceroute google.com

# DNS lookup
nslookup fileserver.company.local
dig @192.168.20.1 company.local

# Port scan (check if service is up)
nmap -p 80,443,445,3389 192.168.20.10

# Bandwidth test between machines
iperf3 -s           # on server
iperf3 -c 192.168.20.10  # on client

# Capture packets for diagnosis
tcpdump -i eth0 -w capture.pcap host 192.168.20.10
```

---

## 6. Printers & Peripherals

### Printer management — the full picture

**IP Printer setup (network printer):**
1. Assign a static IP or DHCP reservation by MAC address
2. Put it on VLAN 50 (isolated printer VLAN)
3. Add via Group Policy so all domain machines get it automatically

```powershell
# Add a network printer via PowerShell
Add-PrinterPort -Name "IP_192.168.50.10" -PrinterHostAddress "192.168.50.10"
Add-Printer -Name "HP LaserJet Floor2" -DriverName "HP LaserJet Universal" -PortName "IP_192.168.50.10"

# Deploy printer to all users via GPO
# Computer Config → Windows Settings → Deployed Printers → Add printer by UNC path
# \\printserver\HP-LaserJet-Floor2
```

**Print server (Windows Print Spooler):**
```powershell
# List all printers on print server
Get-Printer -ComputerName "printserver"

# Check print queue
Get-PrintJob -PrinterName "HP LaserJet Floor2"

# Clear stuck print queue
Stop-Service -Name Spooler
Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Recurse
Start-Service -Name Spooler
```

**Linux CUPS (Common Unix Printing System):**
```bash
# Install CUPS
sudo apt install cups

# Add network printer
sudo lpadmin -p "HP-Floor2" -E -v socket://192.168.50.10 -m everywhere

# Set default printer
sudo lpoptions -d HP-Floor2

# Check queue
lpq -P HP-Floor2

# Cancel all jobs
cancel -a HP-Floor2
```

**Common printer issues and fixes:**
| Issue | Fix |
|-------|-----|
| Printer offline | Check IP, ping it, power cycle, clear spooler |
| Stuck print queue | Stop spooler, delete files in PRINTERS folder, restart |
| Driver missing | Download from vendor site, push via GPO |
| Printing garbage | Wrong driver installed, reinstall correct one |
| Can't scan to email | Configure SMTP relay on printer's web UI |
| Toner low alert | Keep 1 spare per model, track via monitoring |

**Scan to email setup (on printer web UI):**
```
SMTP Server: smtp.office365.com (or your mail server)
Port: 587
Auth: service account (it-printer@company.com)
TLS: STARTTLS
From: printer@company.com
```

---

## 7. Cameras & Physical Security

### IP Camera setup

**Network segmentation (critical):**
- All cameras on VLAN 40
- BLOCK cameras from accessing internet (stop data exfiltration)
- BLOCK cameras from accessing internal servers
- Only NVR/DVR can talk to cameras

**NVR (Network Video Recorder) setup:**
```
Recommended: Synology Surveillance Station, QNAP, or dedicated NVR hardware
Storage: 1 camera @ 1080p ≈ 20–40 GB/day. Plan 30-day retention.
Storage formula: (cameras × GB/day × retention days) × 1.2 safety buffer
Example: 8 cameras × 30 GB × 30 days × 1.2 = ~8.6 TB
```

**ONVIF protocol** — most IP cameras support it. Use ONVIF Device Manager to discover cameras on your network.

**Camera placement checklist:**
```
✔ Main entrance / exit
✔ Server room door
✔ Reception desk
✔ Car park / loading bay
✔ Finance / HR department
✔ Network equipment room
✗ Bathrooms, changing rooms (legal requirement)
```

**Access control integration:**
- Badge readers: HID, Suprema, ZKTeco
- Software: Lenel, Genetec, open-source Kerberos (not the auth protocol — the VMS)
- Connect to AD: badge = AD account, disable badge on offboarding

**Door access script — disable badge on offboarding:**
```powershell
# Trigger from offboarding script
# Call your access control API or software SDK here
# Example with ZKTeco REST API:
Invoke-RestMethod -Uri "http://accesscontrol.local/api/users/john.doe/disable" `
  -Method POST -Headers @{Authorization = "Bearer $token"}
```

---

## 8. Mobile Device Management (MDM)

### Why MDM matters
Without MDM, a lost phone = a data breach. With MDM, you can wipe it in 30 seconds.

### MDM solutions by company size:
| Size | Solution | Cost |
|------|----------|------|
| <50 users | Google Workspace MDM / Microsoft Intune Basic | Free–$6/user |
| 50–200 | Microsoft Intune, Jamf Now | $8–12/user/month |
| 200–500 | Jamf Pro (Apple), Intune + Autopilot | $15–20/user/month |
| Self-hosted | Headscale + custom MDM | Free |

### Microsoft Intune — key policies to enforce:
```
Device Compliance Policies:
  ✔ Require PIN/biometric
  ✔ Require encryption (BitLocker/FileVault)
  ✔ Minimum OS version
  ✔ Block jailbroken/rooted devices
  ✔ Require Defender / antivirus

App Protection Policies:
  ✔ Prevent copy-paste from corporate apps to personal
  ✔ Require PIN for Outlook/Teams
  ✔ Remote wipe on unenroll
  ✔ Block screenshots in corporate apps
```

**Remote wipe a device:**
```powershell
# Intune via PowerShell (Microsoft Graph)
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
$device = Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq 'john.doe@company.com'"
Invoke-MgRetireDeviceManagementManagedDevice -ManagedDeviceId $device.Id
```

**BYOD vs Company-owned policy:**
```
Company-owned:
  - Full MDM enrollment, full control
  - Track location, remote wipe
  - Push apps, enforce all policies

BYOD (Bring Your Own Device):
  - MAM only (Mobile App Management, not full MDM)
  - Control only corporate apps, not personal data
  - Container approach: corporate data isolated
  - Remote wipe corporate data only (not personal photos)
```

---

## 9. Software & Licensing

### License management — what to track:
```
For each software title, record:
  - Product name and version
  - License type (per seat, per device, concurrent, OEM)
  - Number of licenses purchased
  - Number in use
  - Expiry / renewal date
  - Cost
  - Vendor contact
  - License key / activation info (encrypted)
```

**Audit installed software across domain:**
```powershell
# Pull installed software from all domain computers
$computers = Get-ADComputer -Filter * | Select -Expand Name
foreach ($pc in $computers) {
    Invoke-Command -ComputerName $pc -ScriptBlock {
        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Select DisplayName, DisplayVersion, Publisher
    } -ErrorAction SilentlyContinue
} | Export-Csv "C:\Reports\software_audit.csv" -NoTypeInformation
```

**Tools:**
- **Snipe-IT** (self-hosted, free) — asset + license tracking
- **Lansweeper** — automatic network asset discovery
- **PDQ Inventory** — Windows software inventory

---

## 10. Backup & Disaster Recovery

### The 3-2-1 rule (non-negotiable):
```
3 copies of data
2 different storage media types
1 copy offsite (cloud or physical offsite)

Example:
  Copy 1: Production server (live data)
  Copy 2: Local NAS / backup server (same site)
  Copy 3: Cloud (AWS S3 / Backblaze B2) or offsite tape
```

### Backup tiers:
```
Critical (daily): AD, file server, databases, email
Important (weekly): workstation backups, application configs
Archive (monthly): compliance data, old project files
```

### Veeam backup (Windows — industry standard):
```powershell
# Veeam PowerShell — run backup job
Add-PSSnapin VeeamPSSnapIn
$job = Get-VBRJob -Name "Daily Server Backup"
Start-VBRJob -Job $job
```

### Restic (Linux — open source, god tier):
```bash
# Initialize backup repo
restic init --repo /mnt/backup/company

# Backup /home and /etc
restic backup /home /etc --repo /mnt/backup/company

# Backup to S3
restic backup /data --repo s3:s3.amazonaws.com/company-backups

# Verify backup integrity
restic check --repo /mnt/backup/company

# Restore specific file
restic restore latest --target /restore --include /home/john/Documents

# Prune old backups (keep 7 daily, 4 weekly, 12 monthly)
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

### RTO and RPO — know these terms:
```
RPO (Recovery Point Objective): How much data can you afford to lose?
  Example: Daily backups = max 24 hours of data loss. RPO = 24h.

RTO (Recovery Time Objective): How fast must you be back online?
  Example: Business needs email back in 4 hours. RTO = 4h.

Design your backup strategy around these numbers.
```

### Disaster recovery drill (do this quarterly):
```
1. Pick a server to simulate failure
2. Restore it from backup to a test machine
3. Verify data integrity and service functionality
4. Measure how long it took
5. Compare to your RTO target
6. Document findings and improve
```

---

## 11. Security & Compliance

### Baseline security checklist (every company):
```
Network:
  ✔ Firewall with default-deny rules
  ✔ VLAN segmentation
  ✔ VPN for remote access (no RDP exposed to internet)
  ✔ WiFi WPA3, separate SSID for guests
  ✔ Change all default passwords on network gear

Endpoints:
  ✔ Antivirus / EDR on all machines (Defender ATP or CrowdStrike)
  ✔ BitLocker / FileVault encryption
  ✔ Auto-lock screen after 10 minutes
  ✔ Disable USB storage (via GPO)
  ✔ Application whitelisting

Identity:
  ✔ MFA on all accounts (especially admin)
  ✔ No shared accounts
  ✔ Separate admin account from daily-use account
  ✔ Privileged Access Workstation (PAW) for domain admin tasks
  ✔ Regular access reviews (quarterly)

Data:
  ✔ Classify data (public / internal / confidential / restricted)
  ✔ Encrypt sensitive data at rest and in transit
  ✔ DLP (Data Loss Prevention) policies
  ✔ Regular backup verification
```

### Incident response — the 6 phases:
```
1. PREPARATION   — policies, playbooks, tools ready before incident
2. IDENTIFICATION — detect the incident (alert, user report, anomaly)
3. CONTAINMENT   — isolate affected systems (disconnect from network)
4. ERADICATION   — remove the threat (malware, attacker access)
5. RECOVERY      — restore systems from clean backups, verify
6. LESSONS       — post-incident review, patch the gap
```

**Ransomware response playbook:**
```
IMMEDIATELY:
  1. Disconnect affected machine from network (unplug cable / disable WiFi)
  2. Do NOT restart or shut down (evidence + may spread)
  3. Identify patient zero — who opened what?
  4. Check if backup server is infected (isolate it too if unsure)
  5. Alert management and legal (ransomware = potential breach notification)

INVESTIGATION:
  6. Boot from USB to image the disk (preserve evidence)
  7. Check AD for compromised accounts, reset all admin passwords
  8. Scan all other machines with offline scanner

RECOVERY:
  9. Rebuild from clean OS + restore from last known good backup
 10. Patch the vector (phishing = email training, RDP = VPN only)
 11. Document everything for insurance / compliance
```

### Patch management schedule:
```
Week 1 of month: Test patches on 5 pilot machines
Week 2 of month: Deploy to all workstations
Week 3 of month: Deploy to non-critical servers
Week 4 of month: Deploy to critical servers (during maintenance window)

Emergency patch (zero-day): Deploy within 24–48 hours after testing
```

---

## 12. Monitoring & Alerting

### What to monitor:
```
Servers:        CPU >80%, RAM >85%, Disk >90%, service down
Network:        Interface down, bandwidth spike, latency >50ms
Security:       Failed logins >5 in 10 min, new admin account, firewall rule change
Backups:        Job failed, no backup in 25 hours
Certificates:   SSL cert expiring in <30 days
UPS:            Battery low, on battery power
```

### Zabbix (self-hosted, free, industry standard):
```bash
# Install Zabbix server (Ubuntu)
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
apt update && apt install zabbix-server-mysql zabbix-frontend-php zabbix-agent

# Install agent on monitored machine
apt install zabbix-agent
# Edit /etc/zabbix/zabbix_agentd.conf
# Server=192.168.20.30  (your Zabbix server IP)
systemctl restart zabbix-agent
```

### Grafana + Prometheus stack (god tier — modern):
```bash
# Docker compose (quickest way)
version: '3'
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports: ["9090:9090"]
  grafana:
    image: grafana/grafana
    ports: ["3000:3000"]
  node-exporter:
    image: prom/node-exporter
    ports: ["9100:9100"]
```

### Uptime Kuma (lightweight, beautiful UI, self-hosted):
```bash
docker run -d --restart always -p 3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma louislam/uptime-kuma:1
```

### Alert channels to configure:
- Email (Postfix or SMTP relay)
- Slack / Teams webhook
- PagerDuty for P1/P2
- SMS via Twilio for critical alerts

---

## 13. Helpdesk & Ticketing

### Ticket workflow:
```
User reports issue
    ↓
Ticket created (auto-assign priority)
    ↓
L1 Support attempts fix (30 min time limit)
    ↓
Escalate to L2 if unresolved
    ↓
Escalate to L3 / vendor if needed
    ↓
Resolution + root cause documented
    ↓
Ticket closed + user satisfied
    ↓
KB article created if new issue
```

### Self-service portal — reduce ticket volume by 40%:
```
Add KB articles for:
  - Password reset (self-service via SSPR)
  - VPN connection guide
  - Printer setup for new users
  - Common Outlook issues
  - Software request process
  - WiFi setup for guest / BYOD
```

### Metrics to track weekly:
```
- First Contact Resolution Rate (target: >70%)
- Average Resolution Time by priority
- Ticket volume by category (find patterns)
- SLA breach rate (target: <5%)
- Reopened ticket rate (target: <10%)
```

### Best helpdesk tools:
| Tool | Best for | Cost |
|------|----------|------|
| Freshdesk | SME, easy setup | Free–$15/agent |
| osTicket | Self-hosted, free | Free |
| Jira Service Management | Dev-heavy companies | $20/agent |
| Zammad | Open source, full-featured | Free (self-hosted) |
| Zoho Desk | Budget SME | $14/agent |

---

## 14. Automation Stack

### Automation by maturity level:

**Level 1 — Basic (scripts like this toolkit):**
- PowerShell / Bash for individual tasks
- Task Scheduler / cron for scheduling
- Batch onboarding / offboarding scripts

**Level 2 — Intermediate:**
```powershell
# Auto-create AD user from CSV (HR sends you a spreadsheet)
Import-Csv "new_hires.csv" | ForEach-Object {
    New-ADUser `
      -Name "$($_.FirstName) $($_.LastName)" `
      -SamAccountName "$($_.FirstName.ToLower()).$($_.LastName.ToLower())" `
      -Department $_.Department `
      -Title $_.JobTitle `
      -Enabled $true `
      -AccountPassword (ConvertTo-SecureString "Welcome@2024!" -AsPlainText -Force) `
      -ChangePasswordAtLogon $true
    
    # Add to department group
    Add-ADGroupMember -Identity "GRP_$($_.Department)" -Members "$($_.FirstName.ToLower()).$($_.LastName.ToLower())"
    
    Write-Host "Created: $($_.FirstName) $($_.LastName)"
}
```

**Level 3 — Advanced (Ansible):**
```yaml
# Ansible — configure 50 Linux machines at once
- name: Baseline all workstations
  hosts: all
  roles:
    - security_hardening
    - software_install
    - monitoring_agent
    - backup_client
```

**Level 4 — God Tier (Infrastructure as Code):**
```hcl
# Terraform — provision cloud infrastructure
resource "aws_instance" "backup_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  tags = { Name = "IT-Backup-Server" }
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "company-backups-prod"
  lifecycle_rule {
    expiration { days = 90 }
  }
}
```

### Automation tools reference:
| Tool | Use case | Learn it |
|------|----------|----------|
| PowerShell | Windows automation | Must-have |
| Bash | Linux automation | Must-have |
| Ansible | Cross-platform config management | Year 1 |
| Terraform | Cloud infrastructure | Year 2 |
| Python | Glue scripts, APIs, reporting | Year 1 |
| n8n / Zapier | No-code workflow automation | Now |

---

## 15. Cloud & SaaS Management

### Microsoft 365 admin tasks:
```powershell
# Connect to M365
Connect-ExchangeOnline -UserPrincipalName admin@company.com

# Create mailbox
New-Mailbox -Name "John Doe" -MicrosoftOnlineServicesID "john.doe@company.com" -Password (ConvertTo-SecureString "Pass@123" -AsPlainText -Force)

# Set mailbox size limit
Set-Mailbox "john.doe" -ProhibitSendReceiveQuota 50GB

# Add shared mailbox member
Add-MailboxPermission -Identity "support@company.com" -User "john.doe" -AccessRights FullAccess

# Check MFA status for all users
Get-MsolUser -All | Where-Object {$_.StrongAuthenticationMethods.Count -eq 0} | Select DisplayName
```

### Google Workspace via GAM (CLI tool):
```bash
# Create user
gam create user john.doe firstname John lastname Doe password "TempPass@123"

# Add to group
gam update group staff@company.com add member john.doe@company.com

# Suspend user (offboarding)
gam update user john.doe suspended on

# Transfer Drive files to manager on offboarding
gam user john.doe@company.com transfer drive manager@company.com
```

---

## 16. Documentation Standards

### What to document (non-negotiable):

**Network diagram:** Every device, IP, VLAN, connection. Update when anything changes.

**Asset register:** Every computer, server, switch, printer, camera, phone — serial number, location, assigned user, purchase date, warranty.

**Runbooks:** Step-by-step for every routine task. Written so a junior can follow without asking questions.

**Password vault:** All service accounts, device admin passwords, API keys. Use Bitwarden for Teams or HashiCorp Vault.

**Change log:** Every change to production systems. Date, what changed, who did it, why, rollback plan.

### Documentation tools:
| Tool | Best for |
|------|----------|
| Confluence | Team wikis, runbooks |
| Notion | Flexible, great for small teams |
| IT Glue | MSP-grade, very structured |
| BookStack | Self-hosted, free |
| Markdown in Git | Version-controlled docs (this repo) |

---

## 17. Vendor & Asset Management

### Asset lifecycle:
```
Procurement → Deployment → Management → Refresh → Disposal

Refresh cycle:
  Laptops/Desktops: 4–5 years
  Servers:          5–7 years
  Switches/Routers: 7–10 years
  Printers:         5–7 years
  UPS batteries:    3–4 years
```

### Asset register fields:
```
- Asset tag (e.g. IT-WS-0042)
- Type (Laptop / Desktop / Server / Printer)
- Make / Model
- Serial number
- Purchase date
- Warranty expiry
- Assigned user
- Location / desk
- OS and version
- Last seen (auto-updated by monitoring)
- Status (Active / Storage / Disposed)
```

### Secure disposal:
```bash
# NIST 800-88 compliant disk wipe (Linux)
sudo shred -vzn 3 /dev/sda

# Or use DBAN (Darik's Boot and Nuke) — boot from USB
# For SSDs: manufacturer secure erase tool (Secure Erase, not shred)
# For phones: Factory reset + remove SIM/SD
```

---

## 18. Onboarding & Offboarding

### New hire checklist (automated where possible):
```
T-5 days (pre-arrival):
  □ Create AD account
  □ Assign M365 / Google Workspace license
  □ Add to correct security groups / mailing lists
  □ Pre-configure laptop (image + software profile)
  □ Set up email signature template
  □ Order hardware if needed

Day 1:
  □ Hand over laptop + peripherals
  □ Walk through VPN setup
  □ Add to printer (or auto-push via GPO)
  □ Set up badge / access card
  □ Add to Slack/Teams workspace
  □ Enroll phone in MDM if needed

Week 1:
  □ Complete security awareness training
  □ Confirm all software access working
  □ Collect IT policy acknowledgement
```

### Offboarding checklist (must be same-day):
```
IMMEDIATE (same day as HR notification):
  □ Disable AD account
  □ Revoke MFA devices
  □ Disable VPN access
  □ Disable badge / physical access
  □ Block email, forward to manager
  □ Remove from all shared mailboxes
  □ Revoke API keys / personal access tokens

WITHIN 48 HOURS:
  □ Transfer Google Drive / OneDrive to manager
  □ Export and archive Slack history
  □ Recover hardware (laptop, phone, access card, keys)
  □ Wipe MDM-managed devices
  □ Remove from all vendor portals (GitHub, AWS, etc.)
  □ Update asset register
  □ Cancel per-seat software licenses

30 DAYS:
  □ Backup and delete mailbox data
  □ Delete / archive AD account
  □ Final license audit
```

---

## 19. Disaster Scenarios & Playbooks

### Scenario 1: Server room flooding
```
1. Cut power to server room (UPS bypass or main breaker)
2. Do NOT enter a room with standing water + live electricity
3. Notify management + insurance immediately
4. Activate DR plan — spin up cloud failover if available
5. Assess hardware damage after safety clearance
6. Restore from offsite backup to temporary cloud infrastructure
7. Document everything for insurance claim
```

### Scenario 2: CEO laptop stolen
```
1. Take report — when, where, what data was on it
2. Remote wipe via MDM immediately (< 30 min target)
3. Check if disk was encrypted (BitLocker/FileVault) — if yes, risk is low
4. Reset CEO's AD password and MFA
5. Revoke all active sessions (M365 admin center)
6. Notify legal/compliance (data breach assessment)
7. File police report (insurance requirement)
8. Provision replacement laptop from spare pool
```

### Scenario 3: Cryptolocker / Ransomware
```
→ See Section 11 Ransomware Response Playbook
```

### Scenario 4: User accidentally deletes critical shared folder
```
1. Identify exact folder path and deletion time
2. Check if Recycle Bin / Trash has it (check the server's recycle bin too)
3. Windows Server: Previous Versions (shadow copies) → right-click folder → Restore previous version
4. If not: restore from last backup
5. Enable shadow copies if not already on (protect future data)
6. Consider DFS replication to secondary server for critical shares
```

---

## 20. Tools Reference

### Essential tools every IT engineer should know:

**Remote access:**
```
RDP (mstsc)         — Windows remote desktop
SSH                 — Linux/server remote access
TeamViewer          — User support, cross-platform
AnyDesk             — Lightweight, fast
RustDesk            — Self-hosted TeamViewer alternative
```

**Network:**
```
Wireshark           — Packet capture and analysis
nmap                — Network scanner
PuTTY               — SSH client (Windows)
Angry IP Scanner    — Fast host discovery
PRTG / Zabbix       — Network monitoring
```

**Security:**
```
Nessus / OpenVAS    — Vulnerability scanner
Autopsy             — Digital forensics
Sysinternals Suite  — Windows internals toolkit (Process Monitor, Autoruns, TCPView)
CyberChef           — Data encoding/decoding analysis
OSSEC               — Host-based IDS
```

**Scripting / Automation:**
```
PowerShell ISE / VS Code  — PowerShell development
Ansible AWX               — Web UI for Ansible
Rundeck                   — Job scheduler / automation
n8n                       — Visual workflow automation
```

**Backup:**
```
Veeam               — Windows/VM backup (industry standard)
Restic              — Linux backup (modern, encrypted)
Acronis             — All-platform backup
Backblaze B2        — Cheap cloud backup destination
```

**Documentation:**
```
draw.io             — Network diagrams
Snipe-IT            — Asset management
Bitwarden Teams     — Password management
Confluence / Notion — Team wikis
```

---

*This guide covers the operational reality of running IT for a 50–500 person company. It is a living document — update it as your environment evolves.*

*Version: 1.0 | Platform: Windows, Linux, macOS, Cloud*
