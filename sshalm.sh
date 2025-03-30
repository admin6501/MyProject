#!/bin/bash

Ensure the script is run as root 

if [[ $(id -u) -ne 0 ]]; then echo "This script must be run as root!" >&2 exit 1 fi

Prompt for a new root password 

echo "Enter a new password for the root user:" read -s ROOT_PASS

echo "Confirm the password:" read -s ROOT_PASS_CONFIRM

if [[ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]]; then echo "Passwords do not match!" >&2 exit 1 fi

Set the root password 

echo "root:$ROOT_PASS" | chpasswd

Modify SSH configuration to allow password authentication for root 

SSH_CONFIG="/etc/ssh/sshd_config" sed -i 's/^#PermitRootLogin./PermitRootLogin yes/' "$SSH_CONFIG" sed -i 's/^#PasswordAuthentication./PasswordAuthentication yes/' "$SSH_CONFIG"

Restart SSH service 

systemctl restart sshd

echo "Root login with password has been enabled. Make sure your firewall allows SSH access."

