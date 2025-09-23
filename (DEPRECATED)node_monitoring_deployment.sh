#!/bin/bash

# Variables
hostname=$(hostname)

NODE_EXPORTER_VERSION="1.8.2"

# Define log paths and labels
declare -A log_paths=(
  ["cronjob"]="/var/log/cron"
  ["authentication_activity"]="/var/log/secure"
  ["syslog"]="/var/log/messages"
)

declare -A whm_log_paths=(
  ["session_log"]="/usr/local/cpanel/logs/session_log"
  ["api_tokens_log"]="/usr/local/cpanel/logs/api_tokens_log"
  ["login_log"]="/usr/local/cpanel/logs/login_log"
  ["accounting_log"]="/var/cpanel/accounting.log"
)

# ================================Node Exporter=============================

echo "Installing Node Exporter..."

# Download and extract Node Exporter
cd /usr/src || exit
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

tar -xf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
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
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/usr/local/bin/node_exporter_textfile/textfile

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

# Create Node Exporter collector file
echo '#!/bin/bash

# Daftar nama layanan yang akan diperiksa
services=("lsws.service" "mysqld.service" "pdns.service" "exim.service")

# Lokasi file output untuk Textfile Collector
status_file="/usr/local/bin/node_exporter_textfile/textfile/service_status.prom"
uptime_file="/usr/local/bin/node_exporter_textfile/textfile/service_uptime.prom"

# Kosongkan isi file status dan uptime terlebih dahulu
> "$status_file"
> "$uptime_file"

# Loop untuk memeriksa status dan uptime setiap layanan
for service in "${services[@]}"; do
    # Nama layanan tanpa ".service" untuk output yang lebih bersih
    service_name=$(echo "$service" | sed 's/\.service//')

    # Cek status layanan
    if systemctl is-active --quiet "$service"; then
        echo "${service_name}_status 1" >> "$status_file"
    else
        echo "${service_name}_status 0" >> "$status_file"
    fi

    # Mendapatkan waktu uptime dari service
    UPTIME=$(systemctl show -p ActiveEnterTimestamp "$service" | sed 's/ActiveEnterTimestamp=//')

    # Mengonversi waktu uptime dan waktu sekarang ke detik sejak epoch (Unix timestamp)
    UPTIME_SECONDS=$(date -d "$UPTIME" +%s)
    CURRENT_TIME=$(date +%s)

    # Menghitung selisih waktu (uptime dalam detik)
    DIFFERENCE=$((CURRENT_TIME - UPTIME_SECONDS))

    # Menyimpan hasil uptime dalam format yang bisa dipahami oleh Prometheus
    echo "${service_name}_uptime_seconds $DIFFERENCE" >> "$uptime_file"
done' | sudo tee /usr/local/bin/node_exporter_textfile/script/collector.sh > /dev/null

# Berikan hak akses eksekusi pada file collector
sudo chmod +x /usr/local/bin/node_exporter_textfile/script/collector.sh

# Create trigger script to run the collector every 10 seconds
echo '# Jalankan setiap 10 detik
#!/bin/bash

# Jalankan file collector setiap 10 detik dalam 1 menit
for ((i=0; i<6; i++)); do
  /usr/local/bin/node_exporter_textfile/script/collector.sh &
  sleep 10
done' | sudo tee /usr/local/bin/node_exporter_textfile/script/trigger.sh > /dev/null

# Berikan hak akses eksekusi pada file trigger
sudo chmod +x /usr/local/bin/node_exporter_textfile/script/trigger.sh

# Berikan hak akses pada direktori dan file
sudo chown -R node_exporter:node_exporter /usr/local/bin/node_exporter_textfile

# Add cron job to run the collector script every 10 seconds
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/node_exporter_textfile/script/trigger.sh") | crontab -

# Restart the Node Exporter service
sudo systemctl restart node_exporter


# ================================Promtail================================

echo "Installing Promtail..."

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
sslcacert=/etc/pki/tls/certs/ca-bundle.crt' > /etc/yum.repos.d/grafana.repo

# Install Promtail
dnf install -y promtail

# Enable and start Promtail service
systemctl enable --now promtail

# Create Promtail configuration directory if it doesn't exist
mkdir -p /etc/promtail

# Configure Promtail
cat <<EOF > /etc/promtail/config.yml
# Minimal config scrapes specific log files.
# https://github.com/grafana/loki/issues/11398

server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
- url: http://grafa.idcloudhost-tutorial.my.id:3100/loki/api/v1/push

scrape_configs:
EOF

# Add general logs
for job in "${!log_paths[@]}"; do
  cat <<EOF >> /etc/promtail/config.yml
- job_name: ${job}
  static_configs:
  - targets:
      - localhost
    labels:
      job: ${job}
      host: ${hostname}:9100
      __path__: ${log_paths[$job]}
EOF
done

# Add WHM logs
cat <<EOF >> /etc/promtail/config.yml
- job_name: whm_log
  static_configs:
EOF

for job in "${!whm_log_paths[@]}"; do
  cat <<EOF >> /etc/promtail/config.yml
  - targets:
      - localhost
    labels:
      job: ${job}
      host: ${hostname}:9100
      __path__: ${whm_log_paths[$job]}
EOF
done

# Set ACL permissions for Promtail to read logs
for path in "${log_paths[@]}" "${whm_log_paths[@]}"; do
  setfacl -m u:promtail:r ${path}
done

# Restart Promtail service
systemctl restart promtail

echo "Promtail installation and configuration completed."