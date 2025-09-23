#!/bin/bash

# Path for saving prom result
suspended_account="/usr/local/bin/node_exporter_textfile/textfile/total_suspended_account.prom"

# Caputre the output of the ls command into the variable 'total'
total=$(/usr/sbin/whmapi1 listsuspended | grep 'user:' | wc -l)

# Save the total number of suspended hosting account to a textfile
echo "suspended_hosting_account $total" > "$suspended_account"