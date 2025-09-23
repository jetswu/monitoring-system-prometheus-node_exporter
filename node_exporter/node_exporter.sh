#!/bin/bash

NODE_EXPORTER_VERSION="1.8.2"

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "wget is not installed. Installing wget..."
    sudo yum install -y wget
fi

echo "Installing Node Exporter..."

# Download and extract Node Exporter
cd /usr/src || exit
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

tar --no-same-owner -xf  node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/

# Create Node Exporter user
sudo adduser -M -r -s /sbin/nologin node_exporter

# Create systemd service file
sudo bash -c 'cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config.file=/usr/local/bin/node_exporter_textfile/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd, enable start the service
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# Create directory for Node Exporter collector
sudo mkdir -p /usr/local/bin/node_exporter_textfile/

echo '# create config.yml on /usr/local/bin/node_exporter_textfile
basic_auth_users:
    idcloudhost2024: $2b$12$BB/2xzcBasp6/QbLqnCXpecaNFoqF9InJl5ne1F1NV7VfaHlLjAoK
' | sudo tee /usr/local/bin/node_exporter_textfile/config.yml > /dev/null

# Berikan hak akses pada direktori dan file
sudo chown -R node_exporter:node_exporter /usr/local/bin/node_exporter_textfile

# Restart the Node Exporter service
sudo systemctl restart node_exporter

exit 0
