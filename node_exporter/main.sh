#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Run the Node Exporter script
"$SCRIPT_DIR/node_exporter.sh"

# Run the Node Exporter Textfile script
"$SCRIPT_DIR/node_exporter_textfile/node_exporter_textfile.sh"

exit 0
