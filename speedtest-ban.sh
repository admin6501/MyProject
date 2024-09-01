#!/bin/bash

# Function to block speed test sites
block_speed_test_sites() {
    for site in "${speed_test_sites[@]}"; do
        echo "127.0.0.1 $site" | sudo tee -a /etc/hosts
    done
    echo "Speed test sites successfully blocked!"
}

# Function to unblock speed test sites
unblock_speed_test_sites() {
    for site in "${speed_test_sites[@]}"; do
        sudo sed -i "/$site/d" /etc/hosts
    done
    echo "Speed test sites successfully unblocked!"
}

# List of speed test sites
speed_test_sites=(
    "speedtest.net"
    "fast.com"
    "speedof.me"
    # Add more sites...
)

# Display menu
echo "1. Block speed test sites"
echo "2. Unblock speed test sites"
read -p "Please choose an option (1 or 2): " choice

case "$choice" in
    1) block_speed_test_sites ;;
    2) unblock_speed_test_sites ;;
    *) echo "Invalid choice!" ;;
esac
