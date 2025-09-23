#!/bin/bash

# Fungsi untuk mengambil status dan waktu aktif dari sebuah layanan
get_active_time() {
    local service_name=$1
    local active_time=$(echo $(systemctl status "$service_name") | grep "Active:" | sed -n 's/.*; \(.*\) ago.*/\1/p')
    echo "$active_time"
}

# Fungsi untuk memeriksa status layanan (1 untuk aktif, 0 untuk tidak aktif)
get_service_status() {
    local service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        echo 1  # Layanan aktif
    else
        echo 0  # Layanan tidak aktif
    fi
}

# Fungsi untuk mengonversi waktu ke detik
convert_to_seconds() {
    local years=0
    local months=0
    local weeks=0
    local days=0
    local hours=0
    local minutes=0
    local seconds=0

    # Cek apakah ada tahun
    if [[ $1 =~ ([0-9]+)\ year ]]; then
        years=${BASH_REMATCH[1]}
    fi

    # Cek apakah ada bulan
    if [[ $1 =~ ([0-9]+)\ month ]]; then
        months=${BASH_REMATCH[1]}
    fi

    # Cek apakah ada minggu
    if [[ $1 =~ ([0-9]+)\ week ]]; then
        weeks=${BASH_REMATCH[1]}
    fi

    # Cek apakah ada hari
    if [[ $1 =~ ([0-9]+)\ day ]]; then
        days=${BASH_REMATCH[1]}
    fi

    # Cek apakah ada jam (dalam format "hour", "h", atau "13h")
    if [[ $1 =~ ([0-9]+)h ]]; then
        hours=${BASH_REMATCH[1]}
    fi

    # Cek apakah ada menit
    if [[ $1 =~ ([0-9]+)min ]]; then
        minutes=${BASH_REMATCH[1]}
    fi

    # Cek apakah ada detik
    if [[ $1 =~ ([0-9]+)s ]]; then
        seconds=${BASH_REMATCH[1]}
    fi

    # Hitung total detik
    total_seconds=$((years * 365 * 24 * 60 * 60 + months * 30 * 24 * 60 * 60 + weeks * 7 * 24 * 60 * 60 + days * 24 * 60 * 60 + hours * 60 * 60 + minutes * 60 + seconds))
    echo $total_seconds
}

# Daftar layanan yang ingin diperiksa
services=("mysqld" "exim" "pdns" "lsws")

# File output untuk menyimpan uptime
uptime_output_file="/usr/local/bin/node_exporter_textfile/textfile/service_uptime.prom"
status_output_file="/usr/local/bin/node_exporter_textfile/textfile/service_status.prom"

# Kosongkan file output sebelum menulis
> "$uptime_output_file"
> "$status_output_file"

# Loop melalui setiap layanan dan ambil waktu aktif serta konversi ke detik
for service in "${services[@]}"; do
    active_time=$(get_active_time "$service")
    total_seconds=$(convert_to_seconds "$active_time")
    
    # Tulis ke file output dalam format servicename_uptime_second
    echo "${service}_uptime_seconds $total_seconds" >> "$uptime_output_file"

    # Dapatkan status layanan dan tulis ke file status
    service_status=$(get_service_status "$service")
    echo "${service}_status $service_status" >> "$status_output_file"
done