#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Update dnf
#echo "Updating dnf..."
#sudo yum update -y

# Run firewall script
#"$SCRIPT_DIR/firewall/firewalld/whitelist.sh"

# Run the Node Exporter script
"$SCRIPT_DIR/node_exporter/main.sh"

# Run add Grafana repository script
#"$SCRIPT_DIR/dependencies/grafana_repository.sh"

# Run promtail script
#"$SCRIPT_DIR/promtail/promtail.sh"

exit 0