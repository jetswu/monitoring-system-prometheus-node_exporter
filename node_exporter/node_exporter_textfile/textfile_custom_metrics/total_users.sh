#!/bin/bash

# Path for saving prom result
path="/usr/local/bin/node_exporter_textfile/textfile/total_users.prom"

# Caputre the output of the ls command into the variable 'total'
total=$(/usr/sbin/whmapi1 --output=jsonpretty   get_current_users_count | jq -r '.data.users')

# Cek apakah total tidak kosong
if [[ -n "$total" && "$total" =~ ^[0-9]+$ ]]; then
    echo "total_hosting_users $total" > "$path"
else
    echo "total_hosting_users 0" > "$path"
fi