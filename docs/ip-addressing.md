# 📋 Network Reference — IP Addressing, VLANs & Device Roles

> Complete addressing plan and logical design reference for the NetDevOps lab environment.
> All addresses are statically assigned unless noted otherwise.

---

## 🗺️ Topology Overview

```
           INTERNET (VMnet8 — NAT)
                   │
            192.168.33.x (DHCP)
                   │
              ┌────┴────┐
              │   R1    │  Edge Router — NAT/PAT
              └────┬────┘
         192.168.10.254 (VLAN 10)
                   │
         ┌─────────┴──────────┐
         │   swDistribution   │  Layer 3 Core Switch
         └──┬──────────────┬──┘
     VLAN40 │              │ VLAN50
       ┌────┴────┐    ┌────┴────┐
       │  swEdu  │    │ swTech  │  Access Switches
       └────┬────┘    └────┬────┘
        4×VPCS          4×VPCS
      192.168.40.x    192.168.50.x
```

---

## 🖥️ Device IP Address Table

| # | Device | Role | Interface | IP Address | Subnet Mask | VLAN | Notes |
|---|--------|------|-----------|------------|-------------|------|-------|
| 1 | **R1** | Edge Router / NAT | Fa0/0 | 192.168.33.x | /24 | — | DHCP from VMware NAT (VMnet8) |
| 2 | **R1** | Edge Router / NAT | Eth1/0 | 192.168.10.254 | /24 | 10 | Default gateway for VLAN 10 |
| 3 | **swDistribution** | L3 Core Switch | SVI VLAN 10 | 192.168.10.1 | /24 | 10 | Management network gateway |
| 4 | **swDistribution** | L3 Core Switch | SVI VLAN 40 | 192.168.40.1 | /24 | 40 | Education network gateway |
| 5 | **swDistribution** | L3 Core Switch | SVI VLAN 50 | 192.168.50.1 | /24 | 50 | Technology network gateway |
| 6 | **swEdu** | L2 Access Switch | Mgmt SVI | 192.168.10.11 | /24 | 10 | Ansible management target |
| 7 | **swTech** | L2 Access Switch | Mgmt SVI | 192.168.10.12 | /24 | 10 | Ansible management target |
| 8 | **Ubuntu Server** | Ansible Controller + Docker Host | eth0 | 192.168.10.20 | /24 | 10 | Runs Ansible + Zabbix (Docker) |
| 9 | **Windows Server 2022** | DHCP + DNS Server | NIC | 192.168.10.10 | /24 | 10 | Serves DHCP for all VLANs |
| 10 | **PC2–PC12 (swEdu)** | End-user hosts | — | 192.168.40.x | /24 | 40 | Dynamic — DHCP from Win2022 |
| 11 | **PC5–PC9 (swTech)** | End-user hosts | — | 192.168.50.x | /24 | 50 | Dynamic — DHCP from Win2022 |

---

## 🔀 VLAN Design Table

| VLAN ID | Name | Subnet | Purpose | Tagged On |
|---------|------|--------|---------|-----------|
| **10** | `mgmt` | 192.168.10.0/24 | Management — all infrastructure devices, Ansible, Zabbix | All trunk ports |
| **40** | `edu` | 192.168.40.0/24 | Education department end-users | swEdu access ports + trunk |
| **50** | `tech` | 192.168.50.0/24 | Technology department end-users | swTech access ports + trunk |
| **71** | `Test` | — | Isolated test VLAN — not routed | swDistribution only |
| **99** | `native` | — | 802.1Q native VLAN (untagged trunk frames) | All trunk links |

> ⚠️ VLAN 1 (Cisco default native) is **not used** as native VLAN in this design.
> VLAN 99 is assigned as native to mitigate VLAN hopping attacks.

---

## 🔗 Key Trunk Links

| Link | From | To | Mode | Native VLAN | Allowed VLANs |
|------|------|----|------|-------------|---------------|
| Uplink | R1 Eth1/0 | swDistribution | Routed (L3) | — | — |
| Core–Edu | swDistribution | swEdu | Trunk (802.1Q) | 99 | 10, 40, 99 |
| Core–Tech | swDistribution | swTech | Trunk (802.1Q) | 99 | 10, 50, 99 |

---

## 🔐 Ansible Inventory Groups

```ini
[routers]
R1                  ansible_host=192.168.10.254

[core_switches]
swDistribution      ansible_host=192.168.10.1

[access_switches]
swEdu               ansible_host=192.168.10.11
swTech              ansible_host=192.168.10.12

[network_devices:children]
routers
core_switches
access_switches
```

---

## 📡 Zabbix Monitoring Targets

| Host in Zabbix | IP Polled | Protocol | Template |
|----------------|-----------|----------|----------|
| R1 | 192.168.10.254 | SNMPv2c | Cisco IOS by SNMP |
| swDistribution | 192.168.10.1 | SNMPv2c | Cisco IOS by SNMP |
| swEdu | 192.168.10.11 | SNMPv2c | Cisco IOS by SNMP |
| swTech | 192.168.10.12 | SNMPv2c | Cisco IOS by SNMP |

> SNMP community string restricted via ACL to source IP `192.168.10.20` (Zabbix server) only.

---

## 🌐 Default Gateways Summary

| Network | Subnet | Default Gateway |
|---------|--------|----------------|
| Management | 192.168.10.0/24 | 192.168.10.254 (R1) |
| Education | 192.168.40.0/24 | 192.168.40.1 (swDistribution SVI) |
| Technology | 192.168.50.0/24 | 192.168.50.1 (swDistribution SVI) |

---

*Generated as part of the NetDevOps Bachelor's Thesis — Academic Year 2025–2026*
