#!/bin/bash

while true; do
    echo -e "\n==== Firewalld Management Menu ===="
    echo "1. Allow IP for a specific port"
    echo "2. Allow IP for all ports"
    echo "3. Remove allowed IP and port"
    echo "4. Remove IP for all ports"
    echo "5. View allowed IPs and ports"
    echo "6. View rejected IPs and ports"
    echo "7. Exit"
    read -p "Choose an option: " choice

    case $choice in
        1)
            read -p "Enter source IP address: " source_address
            read -p "Enter port: " port
            sudo firewall-cmd --permanent --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"$source_address\" port protocol=\"tcp\" port=\"$port\" accept"
            sudo firewall-cmd --reload
            echo "Rule added: $source_address on port $port."
            ;;
        2)
            read -p "Enter source IP address: " source_address
            sudo firewall-cmd --permanent --zone=public --add-rich-rule="rule family=\"ipv4\" source address=\"$source_address\" accept"
            sudo firewall-cmd --reload
            echo "Rule added: $source_address allowed for all ports."
            ;;
        3)
            read -p "Enter source IP address: " source_address
            read -p "Enter port: " port
            sudo firewall-cmd --permanent --zone=public --remove-rich-rule="rule family=\"ipv4\" source address=\"$source_address\" port protocol=\"tcp\" port=\"$port\" accept"
            sudo firewall-cmd --reload
            echo "Rule removed: $source_address on port $port."
            ;;
        4)
            read -p "Enter source IP address: " source_address
            sudo firewall-cmd --permanent --zone=public --remove-rich-rule="rule family=\"ipv4\" source address=\"$source_address\" accept"
            sudo firewall-cmd --reload
            echo "Rule removed: $source_address from all ports."
            ;;
        5)
            echo "Allowed IPs and ports:"
            sudo firewall-cmd --zone=public --list-rich-rules | grep -v reject
            ;;
        6)
            echo "Rejected IPs and ports:"
            sudo firewall-cmd --zone=public --list-all | grep -i reject
            ;;
        7)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option. Please choose between 1-7."
            ;;
    esac
done
