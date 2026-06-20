<div align="center">

<br>

```
███╗   ██╗███████╗████████╗██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗ ███████╗
████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║   ██║██╔═══██╗██╔══██╗██╔════╝
██╔██╗ ██║█████╗     ██║   ██║  ██║█████╗  ██║   ██║██║   ██║██████╔╝███████╗
██║╚██╗██║██╔══╝     ██║   ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔═══╝ ╚════██║
██║ ╚████║███████╗   ██║   ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║     ███████║
╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝     ╚══════╝
```

### Enterprise Network Design · Ansible Automation · Zabbix Monitoring

<br>

[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Zabbix](https://img.shields.io/badge/Zabbix-6.0_LTS-CC0000?style=for-the-badge&logo=zabbix&logoColor=white)](https://www.zabbix.com/)
[![Docker](https://img.shields.io/badge/Docker-24.x-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Cisco IOS](https://img.shields.io/badge/Cisco_IOL-15.x-1BA0D7?style=for-the-badge&logo=cisco&logoColor=white)](https://www.cisco.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![GNS3](https://img.shields.io/badge/GNS3-2.x-FF6D00?style=for-the-badge&logo=gnome&logoColor=white)](https://www.gns3.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br>

> **A Unified Approach to Network Design, Purpose-Driven Automation with Ansible,**
> **and Monitoring Implementation with Zabbix in a Small Enterprise Environment**

<br>

**Mohammad Hossein Sheikhi** · Supervised by **Dr. Parham Arjmand**
B.Sc. Thesis · Computer Engineering · Academic Year 2025–2026

<br>

[📄 Read the Thesis](docs/thesis.docx) &nbsp;·&nbsp;
[🔧 Ansible Playbooks](ansible/playbooks/) &nbsp;·&nbsp;
[📊 Monitoring Stack](monitoring/) &nbsp;·&nbsp;
[🚀 Quick Start](#-quick-start)

<br>

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Network Architecture](#-network-architecture)
- [Three-Phase NetDevOps Pipeline](#-three-phase-netdevops-pipeline)
- [Technology Stack](#-technology-stack)
- [Repository Structure](#-repository-structure)
- [Implementation Highlights](#-implementation-highlights)
- [Quick Start](#-quick-start)
- [Results & KPIs](#-results--kpis)
- [Key Innovations](#-key-innovations)
- [Academic Citation](#-academic-citation)
- [Author](#-author)

---

## 🎯 Overview

This repository contains the full implementation of a **NetDevOps pipeline** for enterprise network management — the practical deliverable of a Computer Engineering bachelor's thesis.

The project demonstrates that the core principles of DevOps — **declarative configuration, version control, idempotency, and continuous observability** — can be applied directly to a traditional Cisco-based hierarchical network, without requiring SDN controllers, proprietary tools, or expensive licensing.

The work spans three tightly integrated phases:

| Phase | Focus | Primary Tool | Core Outcome |
|:-----:|-------|:------------:|-------------|
| **I** | Hierarchical Network Design & Deployment | GNS3 + Cisco IOL | Stable 3-layer topology with full VLAN segmentation and inter-VLAN routing |
| **II** | Configuration Automation | Ansible | Five idempotent playbooks covering backup, standardization, VLANs, security hardening, and SNMP preparation |
| **III** | Centralized Monitoring & Observability | Zabbix 6 + Docker | Containerized monitoring stack with proactive alerting, LLD, network maps, and escalation paths |

---

## 🏗 Network Architecture

```
                              ┌──────────────┐
                              │   INTERNET   │
                              └──────┬───────┘
                                     │  VMnet8 (NAT)
                         ┌───────────▼──────────────┐
                         │         R1 (Router)       │
                         │     Edge / NAT / PAT      │
                         │   Gi0/0: 192.168.33.x/24  │
                         │   Gi0/1: 192.168.10.254   │
                         └───────────┬──────────────┘
                                     │  Layer 3 Routed Link
                         ┌───────────▼──────────────┐
                         │    swDistribution          │
                         │    Layer 3 Core Switch     │
                         │  ┌────────────────────┐   │
                         │  │  VLAN 10  SVI .1   │   │  ← Management
                         │  │  VLAN 40  SVI .1   │   │  ← Education
                         │  │  VLAN 50  SVI .1   │   │  ← Technology
                         │  │  VLAN 99  Native   │   │
                         │  └────────────────────┘   │
                         └────────┬─────────┬─────────┘
                                  │         │
                    Trunk (802.1Q) │         │ Trunk (802.1Q)
                 ┌────────────────▼──┐  ┌───▼──────────────────┐
                 │      swEdu        │  │       swTech          │
                 │   Access Switch   │  │    Access Switch      │
                 │   VLAN 40 + Mgmt  │  │    VLAN 50 + Mgmt     │
                 └────────┬──────────┘  └──────────┬────────────┘
                          │                         │
              ┌───────────▼──────┐      ┌───────────▼──────────┐
              │  Education PCs    │      │   Technology PCs      │
              │  192.168.40.0/24  │      │   192.168.50.0/24    │
              │  DHCP via Win2022 │      │   DHCP via Win2022   │
              └───────────────────┘      └──────────────────────┘

  ╔══════════════════════ VLAN 10 — Management Backbone ══════════════════════╗
  ║                                                                            ║
  ║  ┌─────────────────────┐            ┌───────────────────────┐             ║
  ║  │    Ubuntu 20.04 LTS  │            │   Windows Server 2022  │            ║
  ║  │    192.168.10.20     │            │    192.168.10.10       │            ║
  ║  │  ┌───────────────┐  │            │  ┌─────────────────┐  │            ║
  ║  │  │ Ansible 2.15+ │  │            │  │   DHCP Server   │  │            ║
  ║  │  │ Control Node  │  │            │  │   DNS Server    │  │            ║
  ║  │  ├───────────────┤  │            │  └─────────────────┘  │            ║
  ║  │  │ Docker 24.x   │  │            └───────────────────────┘            ║
  ║  │  │ ┌───────────┐ │  │                                                  ║
  ║  │  │ │  Zabbix 6  │ │  │                                                  ║
  ║  │  │ │  MySQL 8   │ │  │                                                  ║
  ║  │  │ │  Nginx     │ │  │◄── SNMP polls all devices via VLAN 10           ║
  ║  │  │ └───────────┘ │  │                                                  ║
  ║  │  └───────────────┘  │                                                  ║
  ║  └─────────────────────┘                                                  ║
  ╚══════════════════════════════════════════════════════════════════════════╝
```

---
![Network Topology](screenshots/topology.jpg)
## 🔄 Three-Phase NetDevOps Pipeline

```mermaid
flowchart TD
    subgraph PH1["⚙️  PHASE I — Foundation"]
        direction LR
        A1[Topology\nDesign] --> A2[VLAN\nSegmentation]
        A2 --> A3[Inter-VLAN\nRouting SVIs]
        A3 --> A4[NAT/PAT\nEdge Routing]
        A4 --> A5[DHCP + DNS\nWin Server 2022]
    end

    subgraph PH2["🤖  PHASE II — Automation"]
        direction LR
        B0[Ansible\nControl Node] --> B1[1 Backup\nTimestamped]
        B1 --> B2[2 Standardize\nBanner + Encrypt]
        B2 --> B3[3 VLANs\nData-Driven Loop]
        B3 --> B4[4 Security\nCIS Hardening]
        B4 --> B5[5 SNMP Prep\nZabbix Bridge]
    end

    subgraph PH3["📡  PHASE III — Observability"]
        direction LR
        C0[Zabbix 6\nDocker Stack] --> C1[SNMP\nPolling]
        C1 --> C2[LLD Auto\nDiscovery]
        C2 --> C3[Trigger +\nHysteresis]
        C3 --> C4[Escalation\nSelf-Healing]
        C4 --> C5[Network Map\nLive Dashboard]
    end

    PH1 -->|"Stable\nTopology"| PH2
    PH2 -->|"SNMP-Ready\nDevices"| PH3

    style PH1 fill:#1a3a5c,color:#ffffff,stroke:#2980b9
    style PH2 fill:#5c1a1a,color:#ffffff,stroke:#c0392b
    style PH3 fill:#1a4a2e,color:#ffffff,stroke:#27ae60
```

---

## 🛠 Technology Stack

| Category | Technology | Version | Purpose |
|----------|-----------|:-------:|---------|
| **Emulation** | GNS3 | 2.x | Full network testbed with real IOS |
| **Network OS** | Cisco IOL (IOS-on-Linux) | 15.x | L2/L3 switches + edge router |
| **Automation** | Ansible | 2.15+ | Agentless configuration management |
| **SSH Transport** | `network_cli` connection plugin | — | Persistent SSH sessions to Cisco IOS |
| **Monitoring** | Zabbix Server | 6.0 LTS | SNMP polling, triggers, alerting |
| **Database** | MySQL | 8.0 | Zabbix history & trends backend |
| **Web UI** | Nginx + PHP | — | Zabbix frontend |
| **Containers** | Docker + Compose | 24.x | Full Zabbix stack deployment |
| **Control Node OS** | Ubuntu Server | 20.04 LTS | Ansible + Docker host |
| **Services OS** | Windows Server | 2022 | DHCP, DNS |
| **Monitoring Protocol** | SNMPv2c + ACL | — | Telemetry with source-IP restriction |
| **CI/CD** | GitLab CI | — | Syntax check → Dry-run → Deploy |
| **Version Control** | Git | — | Infrastructure-as-Code backbone |

---

## 📁 Repository Structure

```
netdevops-enterprise-network/
│
├── 📄  README.md                          ← You are here
│
├── 📂  ansible/
│   ├── inventory.ini                      ← Device groups & connection variables
│   ├── ansible.cfg                        ← Control node defaults
│   └── playbooks/
│       ├── 1_backup.yml                   ← Timestamped config backup to local disk
│       ├── 2_standardize.yml              ← MOTD, password encryption, DNS
│       ├── 3_vlan.yml                     ← Data-driven VLAN provisioning (VTP transparent)
│       ├── 4_security.yml                 ← CIS-aligned hardening (SSH, VTY, CDP, HTTP)
│       └── 5_monitoring_prep.yml          ← SNMP community + ACL for Zabbix
│
├── 📂  monitoring/
│   ├── docker-compose.yml                 ← Full Zabbix 6 stack (server + web + MySQL)
│   └── daemon.json                        ← Docker registry mirror config (sanctions workaround)
│
├── 📂  ci/
│   └── gitlab-ci.yml                      ← 3-stage pipeline: validate → dry-run → deploy
│
└── 📂  docs/
    └── thesis.docx                        ← Full academic thesis document
```

---

## ✨ Implementation Highlights

### 🔁 Five-Playbook Ansible Pipeline

Each playbook is a **single-responsibility, idempotent unit**.
The full pipeline can be re-run safely at any time — no side effects, no surprises.

<details>
<summary><b>Scenario 1 — Dynamic Timestamped Backup</b></summary>

```yaml
# Creates a folder per timestamp, saves each device's running config locally
- name: Get Date
  command: date +%Y-%m-%d_%H:%M
  register: date_var
  delegate_to: localhost

- name: Save Config to Timestamped File
  copy:
    content: "{{ config_output.stdout[0] }}"
    dest: "./backups/{{ date_var.stdout }}/{{ inventory_hostname }}.txt"
  delegate_to: localhost
```
</details>

<details>
<summary><b>Scenario 3 — Data-Driven VLAN Provisioning</b></summary>

```yaml
# To add/remove a VLAN: edit the vars block only — zero logic change
vars:
  my_vlans:
    - { id: 10, name: mgmt  }
    - { id: 40, name: edu   }
    - { id: 50, name: tech  }
    - { id: 99, name: native }

tasks:
  - name: Create and Name VLANs
    ios_config:
      parents: vlan {{ item.id }}
      lines:  [ name {{ item.name }} ]
    loop: "{{ my_vlans }}"
```
</details>

<details>
<summary><b>Idempotency Guard — Only Save When Something Changed</b></summary>

```yaml
# Protects NVRAM from unnecessary write cycles
- name: Save Config
  ios_config:
    save_when: modified   # NVRAM write is skipped if this run changed nothing
```
</details>

---

### 📦 Containerized Zabbix Stack

One command boots the entire monitoring platform:

```bash
docker compose up -d
```

Three containers, one network, zero dependency conflicts:

```
zabbix-mysql-server   ←→   zabbix-server   ←→   zabbix-web-nginx
    MySQL 8.0              Zabbix 6.0 LTS        Nginx + PHP frontend
  (persistent vol)        (port 10051)             (port 8080)
```

**Monitoring capabilities active out of the box:**

| Capability | Details |
|-----------|---------|
| 🟢 SNMP Polling | All Cisco devices via built-in `Cisco IOS by SNMP` template |
| 🔍 Low-Level Discovery | Auto-detects new switch interfaces — zero manual host config |
| 🔔 Trigger + Hysteresis | Separate ON/OFF thresholds eliminate alert flapping |
| 🚨 6-Tier Severity | Information → Warning → Average → High → Critical → Disaster |
| 🔁 Escalation + Self-Healing | Level 1 → Level 2 → Automated Ansible hook |
| 🗺️ Live Network Map | Real-time bandwidth macros displayed on each link |
| 📈 History vs Trends | 7–30 day raw history · 1 year aggregated trends |
| 🔒 Source-Restricted SNMP | ACL limits responses to Zabbix IP only |

---

### 🔗 Ansible → Zabbix Integration Bridge

Playbook 5 (`5_monitoring_prep.yml`) is the architectural glue between Phase II and Phase III.
It configures SNMP uniformly across all devices via Ansible, so that the moment Zabbix comes online, polling works immediately — **zero manual switch configuration**.

```
┌─────────────────────────────────────────────────────────────┐
│   Phase II ends with 5_monitoring_prep.yml                   │
│                                                             │
│   Ansible ──► All switches: SNMP community + ACL applied   │
│                                                             │
│   Phase III begins:                                         │
│                                                             │
│   docker compose up -d ──► Zabbix boots ──► Starts polling │
│                                             immediately ✅  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

> **Prerequisites:** GNS3 ≥ 2.x with Cisco IOL images · Ubuntu 20.04 LTS VM · Docker 24.x · Python 3.10+

### Step 1 — Clone the Repository

```bash
git clone https://github.com/mhsheikhi/netdevops-enterprise-network.git
cd netdevops-enterprise-network
```

### Step 2 — Install Ansible

```bash
sudo apt update && sudo apt install -y ansible python3-pip
pip3 install paramiko netmiko --break-system-packages
```

### Step 3 — Configure Your Inventory

Edit `ansible/inventory.ini` and replace the IP addresses with your GNS3 device IPs.
Use Ansible Vault for credentials in any non-lab environment:

```bash
ansible-vault encrypt_string 'your_password' --name 'ansible_password'
```

### Step 4 — Verify Connectivity

```bash
ansible -i ansible/inventory.ini network_devices -m ping
```

### Step 5 — Run the Full Automation Pipeline

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/1_backup.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/2_standardize.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/3_vlan.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/4_security.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/5_monitoring_prep.yml
```

### Step 6 — Deploy the Monitoring Stack

```bash
# (Optional) Configure domestic registry mirrors if needed:
sudo cp monitoring/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

# Start Zabbix:
cd monitoring/
docker compose up -d

# Access the Zabbix web UI:
# URL:      http://192.168.10.20:8080
# Username: Admin
# Password: zabbix
```

---

## 📊 Results & KPIs

| Metric | Traditional CLI Approach | This NetDevOps Pipeline | Change |
|--------|:------------------------:|:-----------------------:|:------:|
| Config deployment time | Minutes (sequential, per-device) | Seconds (parallel, all devices) | ↓ ~90% |
| Configuration drift | Undetected until failure | Eliminated by idempotent enforcement | ↓ ~100% |
| Mean Time to Detect (MTTD) | Hours (reactive — user reports) | Seconds (proactive Zabbix trigger) | ↓ critical |
| Human error surface | Every CLI session | Eliminated — code is the only interface | Near zero |
| Monitoring license cost | High (SolarWinds / PRTG / etc.) | **Zero** (fully open-source) | ↓ 100% |
| Stack re-deployment time | Days (manual reinstall) | `docker compose up -d` → seconds | ↓ ~99% |
| Audit trail | None | Full Git history of every change | ✅ |
| Rollback capability | Manual CLI reversal | `git revert` + re-run playbook | ✅ |

---

## 💡 Key Innovations

### 1 — Sanctions-Resilient Container Deployment

Docker Hub is unreachable from Iranian IP ranges at the network layer (HTTP 403 / TLS timeout).
This project documents a reproducible solution: re-engineering the Docker daemon to route all image pulls through domestic Iranian mirrors.

```json
// /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.ir",
    "https://huecker.io"  
  ]
}
```

All Zabbix images (server, web, MySQL) pulled successfully at full line speed.
**This is a documented, reproducible model for containerized deployment under international infrastructure restrictions.**

---

### 2 — NetDevOps on Vendor Hardware (No SDN Required)

The full DevOps lifecycle — Infrastructure as Code, version control, idempotency, CI/CD pipelines, and continuous observability — is demonstrated here on **traditional Cisco IOS-based hardware**, not cloud-native or SDN environments. No proprietary controller. No NMS license. No vendor lock-in.

---

### 3 — Automation-First Monitoring Bootstrap

Playbook 5 acts as the bridge between the automation and monitoring phases.
By the time Zabbix starts, SNMP is already uniformly configured on every device — a direct result of the automation phase. The monitoring system can begin polling immediately with no manual intervention on any switch.

---

### 4 — Self-Healing Architecture Foundation

The Zabbix escalation path (Level 1 NOC → Level 2 Engineer → Remote Command hook) provides the scaffolding for a fully self-healing network. The `remote command` feature can invoke Ansible playbooks directly, enabling automated remediation before a human technician is ever involved.

---

## 📚 Academic Citation

If you reference this work in your research, please cite:

```bibtex
@thesis{sheykhi2026netdevops,
  author   = {MohammadHossein Sheykhi},
  title    = {A Unified Approach to Network Design, Purpose-Driven Automation
              with Ansible, and Monitoring Implementation with Zabbix in a
              Small Enterprise Environment},
  school   = {[SalmanFarsi University of Kazerun]},
  type     = {Bachelor's Thesis},
  year     = {2026},
  advisor  = {Dr. Parham Arjmand},
  url      = {https://github.com/mhsheikhi/netdevops-enterprise-network}
}
```

---

## 📸 Screenshots

### Network Topology (GNS3)
![Topology](screenshots/topology.jpg)

### Zabbix Dashboard
![Dashboard](screenshots/zabbix_dashboard.png)

### Live Network Map
![Network Map](screenshots/zabbix_network_map.png)

### Configured Triggers
![Triggers](screenshots/zabbix_triggers.png)

### Ansible — Play Recap
![Ansible](screenshots/ansible_playrecap.jpg)

## 👤 Author

<div align="center">

**Mohammad Hossein Sheikhi**

B.Sc. Computer Engineering · Academic Year 2025–2026

Supervisor: **Dr. Parham Arjmand**

<br>

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/YOUR_USERNAME)

</div>

---

<div align="center">

*Built with open-source tools · No vendor lock-in · No licensing fees*

`Cisco IOS` · `Ansible` · `Zabbix` · `Docker` · `GNS3` · `Python` · `Ubuntu`

<br>

⭐ **If this project helped you, consider leaving a star.**

</div>
