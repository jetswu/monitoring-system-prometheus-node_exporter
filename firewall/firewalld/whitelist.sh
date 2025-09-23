#!/bin/bash

# IP addresses and ports to whitelist
declare -A IP_PORTS=(
    ["103.123.62.55"]="9080"
    ["103.123.63.63"]="9100"
)

# Check if firewalld is installed
if ! command -v firewall-cmd &> /dev/null; then
    echo "firewalld is not installed. Installing firewalld..."
    sudo yum install -y firewalld
    sudo systemctl enable firewalld
    sudo systemctl start firewalld
else
    # Check if firewalld is active
    if ! sudo systemctl is-active --quiet firewalld; then
        echo "firewalld is installed but not active. Activating firewalld..."
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
    fi
fi

# Iterate over the associative array and add firewall rules
for IP in "${!IP_PORTS[@]}"; do
    PORT=${IP_PORTS[$IP]}
    sudo firewall-cmd --permanent --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"$IP\" port protocol=\"tcp\" port=\"$PORT\" accept"
done

# Reload the firewall to apply the changes
sudo firewall-cmd --reload

echo "Firewall rules have been updated."

exit 0