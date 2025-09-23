#!/bin/bash

# IP addresses and ports to whitelist
declare -A IP_PORTS=(
    ["103.123.62.55"]="9080"
    ["103.123.63.63"]="9100"
)

# Check if Imunify360 CLI is installed
if ! command -v imunify360-agent &> /dev/null
then
    echo "Imunify360 CLI not found. Please install it first."
    exit 1
fi

# Whitelist the IP addresses
for IP in "${!IP_PORTS[@]}"; do
    PORT=${IP_PORTS[$IP]}
    imunify360-agent whitelist add $IP --comment "Whitelist for port $PORT"
    
    # Verify the IP is whitelisted
    if imunify360-agent whitelist list | grep -q $IP; then
        echo "IP $IP successfully whitelisted for port $PORT."
    else
        echo "Failed to whitelist IP $IP."
    fi
done

exit 0