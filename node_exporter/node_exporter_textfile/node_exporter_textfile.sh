#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

echo "Configuring Node Exporter Textfile"

# Create systemd service file
sudo bash -c 'cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config.file=/usr/local/bin/node_exporter_textfile/config.yml --collector.textfile.directory=/usr/local/bin/node_exporter_textfile/textfile
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# Create directory for Node Exporter collector
sudo mkdir -p /usr/local/bin/node_exporter_textfile/textfile

# Create Node Exporter collector file directory
sudo mkdir -p /usr/local/bin/node_exporter_textfile/script

echo '# create config.yml on /usr/local/bin/node_exporter_textfile
basic_auth_users:
    idcloudhost2024: $2b$12$BB/2xzcBasp6/QbLqnCXpecaNFoqF9InJl5ne1F1NV7VfaHlLjAoK
' | sudo tee /usr/local/bin/node_exporter_textfile/config.yml > /dev/null

#  Copy all scripts from /textfile_custom_metrics to /usr/local/bin/node_exporter_textfile/script
sudo cp -r "$SCRIPT_DIR/textfile_custom_metrics"/* /usr/local/bin/node_exporter_textfile/script

# Create trigger script to run the collector every 10 seconds
echo '# Jalankan setiap 10 detik
#!/bin/bash

for i in {1..6}
do
  /usr/local/bin/node_exporter_textfile/script/service_uptime.sh
  /usr/local/bin/node_exporter_textfile/script/exim_queue.sh
  /usr/local/bin/node_exporter_textfile/script/total_suspended.sh
  /usr/local/bin/node_exporter_textfile/script/total_users.sh
  sleep 10
done' | sudo tee /usr/local/bin/node_exporter_textfile/script/trigger.sh > /dev/null

# Berikan hak akses eksekusi pada file trigger
sudo chmod +x /usr/local/bin/node_exporter_textfile/script/trigger.sh

# Berikan hak akses pada direktori dan file
sudo chown -R node_exporter:node_exporter /usr/local/bin/node_exporter_textfile

# Add cron job to run the collector script every 10 seconds
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/node_exporter_textfile/script/trigger.sh > /dev/null 2>&1") | crontab -

# Restart the Node Exporter service
sudo systemctl restart node_exporter

exit 0