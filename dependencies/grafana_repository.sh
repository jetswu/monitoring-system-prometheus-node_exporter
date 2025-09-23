#!/bin/bash

# Check if the Grafana repository already exists
if ! grep -q "\[grafana\]" /etc/yum.repos.d/grafana.repo 2>/dev/null; then
    echo "Adding Grafana repository..."

    # Install wget
    yum install -y wget
    
    # Add Grafana repository
    wget -q -O gpg.key https://rpm.grafana.com/gpg.key

    # Import the GPG key
    rpm --import gpg.key

    # Add the Grafana repository
    echo '[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt' | sudo tee /etc/yum.repos.d/grafana.repo > /dev/null

    echo "Grafana repository added successfully."
else
    echo "Grafana repository already exists."
fi

exit 0