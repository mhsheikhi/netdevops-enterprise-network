#!/bin/bash
cd /home/ansible/my-network-automation
/usr/bin/ansible-playbook -i inventory.ini playbooks/1_backup.yml >> /home/ansible/my-network-automation/backup_log.txt 2>&1
