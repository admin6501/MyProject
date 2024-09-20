#!/bin/bash

# Path to the authorized_keys file
AUTHORIZED_KEYS_FILE="/root/.ssh/authorized_keys"

# Remove SSH keys from the authorized_keys file
if [ -f "$AUTHORIZED_KEYS_FILE" ]; then
    > "$AUTHORIZED_KEYS_FILE"
    echo "SSH keys have been removed from $AUTHORIZED_KEYS_FILE."
else
    echo "$AUTHORIZED_KEYS_FILE does not exist."
fi

# Enable password login for the root user
SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

if grep -q "^PermitRootLogin" "$SSHD_CONFIG_FILE"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG_FILE"
else
    echo "PermitRootLogin yes" >> "$SSHD_CONFIG_FILE"
fi

if grep -q "^PasswordAuthentication" "$SSHD_CONFIG_FILE"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG_FILE"
else
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG_FILE"
fi

# Restart the SSH service
systemctl restart sshd

echo "Password login for the root user has been enabled."

# Prompt for a new password for the root user
echo "Please enter a new password for the root user:"
read -s new_password

# Change the root user's password
echo "root:$new_password" | chpasswd

echo "The root user's password has been changed."
