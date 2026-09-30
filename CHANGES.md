# Project Changes Documentation

**Project:** NetDevOps Thesis — GNS3 Network, Ansible Automation, Zabbix Monitoring
**Scope:** Two enhancements added to the project: (1) Automated Nightly Backup with Zabbix Freshness Monitoring, and (2) Self-Healing Automation for Interface Failures. All values below were verified directly against live command output and Zabbix UI screenshots.

## Environment Reference

- Ansible Controller / Docker host: Ubuntu Server, IP `192.168.10.20`
- Project root: `/home/ansible/my-network-automation/`
- Inventory file: `inventory.ini` (project root)
- Playbooks directory: `/home/ansible/my-network-automation/playbooks/`
- Zabbix Server, Web, and PostgreSQL run as Docker containers on the same Ubuntu host (bridge subnet `172.18.0.0/16`)
- R1 (edge/core router): management-facing IP `192.168.10.254` on interface `Ethernet1/0` (toward swDistribution); WAN-facing interface `FastEthernet0/0` (toward VMnet8/internet)
- R1 is registered in Zabbix under the host name **`Router1`**; the Ubuntu server is registered as **`Ubuntu-server`**

---

## Change 1 — Automated Nightly Backup with Zabbix Freshness Monitoring

### Purpose

Scenario One of the thesis (`1_backup.yml`) already performs a full configuration backup of all managed devices when run manually. This enhancement schedules that playbook to run automatically every night via `cron`, and adds a Zabbix check that verifies a backup was actually produced within the expected window.

Zabbix was intentionally not used to trigger the backup itself, since Zabbix Actions are event-driven rather than time-based. Cron performs the scheduling; Zabbix monitors the outcome.

### 1. Scheduling the Backup

**Wrapper script** — `run_backup.sh` (project root), using absolute paths so it runs correctly under cron's minimal environment:
```bash
#!/bin/bash
cd /home/ansible/my-network-automation
/usr/bin/ansible-playbook -i inventory.ini playbooks/1_backup.yml >> /home/ansible/my-network-automation/backup_log.txt 2>&1
```
```bash
chmod +x /home/ansible/my-network-automation/run_backup.sh
```

**Cron entry** — target schedule (nightly at 21:00):
```
0 21 * * * /home/ansible/my-network-automation/run_backup.sh
```
> Note: at verification time, the live crontab still showed the earlier test value `54 20 * * *`. This entry needs to be updated on the server to match.

**Actual backup destination.** The wrapper script `cd`s into the project root, but the playbook resolves its relative destination path (`./backups/{{ date }}`) against the *playbook file's own directory*, not the shell's working directory. Backups are therefore actually written to:
```
/home/ansible/my-network-automation/playbooks/backups/<date>/
```

**Operational verification.** Cron is confirmed working: a backup folder timestamped `2026-07-28_20:54` matches exactly the cron time active at that point (`54 20 * * *`). No further backups have been produced since (system boot observed: `2026-09-28 12:58`, no matching `CRON` entries in syslog around it) — consistent with the lab VM not being left powered on continuously since July, not a scheduling fault.

### 2. Monitoring Backup Freshness in Zabbix

**Agent installation** (directly on the Ubuntu host, not in a container — confirmed `zabbix-agent 1:6.4.21-1+ubuntu22.04`, enabled and active):
```bash
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo apt update
sudo apt install zabbix-agent
```

**Agent configuration** (`/etc/zabbix/zabbix_agentd.conf`, confirmed):
```
Hostname=Ubuntu-server
Server=127.0.0.1,172.18.0.0/16
AllowKey=system.run[*]
Include=/etc/zabbix/zabbix_agentd.d/*.conf
```
The Docker bridge subnet is included in `Server=` so requests from the containerized Zabbix Server are accepted. `AllowKey=system.run[*]` is required for the remote command used in Change 2.

**Custom UserParameter** (`/etc/zabbix/zabbix_agentd.d/backup_check.conf`, confirmed):
```
UserParameter=backup.age,find /home/ansible/my-network-automation/playbooks/backups -mindepth 1 -maxdepth 1 -type d -printf '%T@\n' | sort -n | tail -1 | awk '{printf "%d\n", systime()-$1}'
```

**Filesystem permissions** — confirmed via `chmod` (no ACLs found):
```bash
sudo chmod o+x /home/ansible
sudo chmod o+x /home/ansible/my-network-automation
sudo chmod -R o+rX /home/ansible/my-network-automation/playbooks/backups
```

**Service:**
```bash
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
```

**Verification:** `zabbix_get -s 127.0.0.1 -k backup.age` returned a numeric value (`5332593`). Docker bridge subnet confirmed as `172.18.0.0/16`.

**Zabbix Host and Item:**

| Field | Value |
|---|---|
| Host name | `Ubuntu-server` |
| Agent interface | `192.168.10.20:10050` |
| Item name | `Backup Age` |
| Item type | Zabbix agent |
| Key | `backup.age` |
| Type of information | Numeric (unsigned) |
| Units | `s` |
| Update interval | `3h` |
| History / Trend storage | `90d` / `365d` |
| Status | Enabled |

**Backup-Stale Trigger** — confirmed created and enabled:

| Field | Value |
|---|---|
| Name | `Backup is stale on {HOST.NAME}` |
| Severity | Warning |
| Expression | `last(/Ubuntu-server/backup.age)>90000` |
| Status | Enabled |

(90,000 s ≈ 25 h — one hour of tolerance beyond the 24-hour cycle.)

### File Inventory — Change 1

| File | Location | Purpose |
|---|---|---|
| `1_backup.yml` | `playbooks/` (pre-existing) | Performs the device backup |
| `run_backup.sh` | project root | Cron-invoked wrapper with logging |
| `backup_log.txt` | project root | Output log of each cron run |
| `backup_check.conf` | `/etc/zabbix/zabbix_agentd.d/` | Custom UserParameter (`backup.age`) |
| crontab entry | user's crontab | `0 21 * * * .../run_backup.sh` |
| `backups/` | `playbooks/backups/` | Actual backup storage location |

---

## Change 2 — Self-Healing Automation for Interface Failures

### Purpose

Demonstrates closed-loop remediation: when a monitored interface goes administratively down, Zabbix detects the fault via SNMP polling and automatically triggers an Ansible playbook that restores the interface, without human intervention.

### Design Decision: Target Interface

The fault-injection target is `FastEthernet0/0` on R1 (the WAN/VMnet8-facing interface), **not** `Ethernet1/0`, which carries all management/SSH traffic between the Ansible Controller and R1 (per the thesis's NAT configuration: `Ethernet1/0` is the inside interface, `FastEthernet0/0` is the outside interface).

This avoids a chicken-and-egg failure mode: if the interface carrying the Controller's own management path to R1 were taken down, the healing playbook would be unable to reach R1 to repair it, since its own control channel would be severed by the very fault it is meant to fix. `FastEthernet0/0` sits outside the management path, making it a safe fault-injection target.

### Implementation

**Remediation playbook** — `playbooks/heal_interface.yml`, deliberately scoped to a single parameterized action:
```yaml
---
- name: Self-Healing - Restore Specific Interface
  hosts: "{{ target_host }}"
  gather_facts: false
  tasks:
    - name: Bring interface back up
      cisco.ios.ios_config:
        lines:
          - no shutdown
        parents: "interface {{ target_interface }}"
```

Validated end-to-end as the `zabbix` account (`PLAY RECAP: ok=1 changed=1`, no failures):
```bash
sudo -u zabbix HOME=/tmp/ansible_zabbix_tmp ANSIBLE_LOCAL_TEMP=/tmp/ansible_zabbix_tmp ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ansible/my-network-automation/inventory.ini /home/ansible/my-network-automation/playbooks/heal_interface.yml -e "target_host=R1 target_interface=fa0/0"
```

**Identifying the SNMP ifIndex:**
```bash
snmpget -v2c -c public 192.168.10.254 .1.3.6.1.2.1.2.2.1.2.1 .1.3.6.1.2.1.2.2.1.8.1
```
Result: `ifDescr.1 = "FastEthernet0/0"`, `ifOperStatus.1 = 1` (up).

**Zabbix Item** (host `Router1`, confirmed):

| Field | Value |
|---|---|
| Name | `R1 FastEthernet0/0 Status` |
| Type | SNMP agent |
| Key | `ifOperStatus.1` |
| Host interface | `192.168.10.254:161` |
| SNMP OID | `.1.3.6.1.2.1.2.2.1.8.1` |
| Type of information | Numeric (unsigned) |
| Update interval | `10s` |
| History / Trend storage | `90d` / `365d` |
| Status | Enabled |

**Zabbix Trigger** (host `Router1`, confirmed):

| Field | Value |
|---|---|
| Name | `R1 FastEthernet0/0 is Down` |
| Severity | Disaster |
| Expression | `last(/Router1/ifOperStatus.1)=2` |
| Status | Enabled |

**Zabbix Script** — required in Zabbix 6.4 for the Action's "Remote command" operation:

| Field | Value |
|---|---|
| Name | `Heal R1 Interface` |
| Scope | Action operation |
| Type | Script |
| Execute on | Zabbix agent |
| Host group | Linux servers |

Commands field (no `sudo -u zabbix` prefix — the Agent already runs as the `zabbix` account):
```
HOME=/tmp/ansible_zabbix_tmp
ANSIBLE_LOCAL_TEMP=/tmp/ansible_zabbix_tmp
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ansible/my-network-automation/inventory.ini /home/ansible/my-network-automation/playbooks/heal_interface.yml -e "target_host=R1 target_interface=fa0/0"
```

**Zabbix Trigger Action** — confirmed:

| Field | Value |
|---|---|
| Name | `Self-Heal R1 FastEthernet0/0` |
| Condition | Trigger equals "Router1: R1 FastEthernet0/0 is Down" |
| Operation | Run script "Heal R1 Interface" on host: `Ubuntu-server` |
| Status | Enabled |

**End-to-end validation:** `FastEthernet0/0` manually shut down on R1, no further manual action taken — Zabbix detected the fault, the Action executed, the playbook ran, the interface returned to `up` automatically, and the Problem resolved itself. Confirmed successful, re-confirmed in a later manual invocation.

**Note on `/tmp/ansible_zabbix_tmp`:** does not survive a reboot (`tmpfiles.d` clears `/tmp` on boot), but this is not an operational risk — when found missing, simply re-running the remediation command caused Ansible to recreate it automatically.

**Recommended follow-up (confirmed not yet implemented):** the Action's Conditions tab currently has only the single trigger-match condition above. A circuit-breaker condition (e.g., "Event count" < 3) was recommended during design to prevent a remediation loop on a persistent/physical fault, but has not been added.

### File Inventory — Change 2

| File / Object | Location | Purpose |
|---|---|---|
| `heal_interface.yml` | `playbooks/` | Remediation playbook (targeted `no shutdown`) |
| Item: `R1 FastEthernet0/0 Status` | Zabbix, host `Router1` | Monitors `ifOperStatus` via SNMP |
| Trigger: `R1 FastEthernet0/0 is Down` | Zabbix, host `Router1` | Fires when `ifOperStatus.1 = 2` |
| Script: `Heal R1 Interface` | Zabbix (Alerts → Scripts) | Defines the remote command |
| Action: `Self-Heal R1 FastEthernet0/0` | Zabbix (Alerts → Actions) | Links Trigger to Script execution |
| `/tmp/ansible_zabbix_tmp` | Ubuntu host | Home/temp dir for `zabbix`'s Ansible runs (auto-recreated) |
