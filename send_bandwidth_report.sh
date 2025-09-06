#!/bin/sh
# -----------------------------------------------------------------------------
# Script      : send_bandwidth_report.sh
# Author      : Evander Fernandes
# Created     : July 13, 2025
# Description : Collects monthly per-device bandwidth usage from OpenWRT
#               using nlbwmon, maps IPs to hostnames from static leases,
#               and sends a summary to Telegram.
#
# Usage       : Set up as a cron job to run on the last day of the month.
#               Requires: nlbwmon, curl, and a Telegram bot token + chat ID.
#
# License     : MIT License - See LICENSE file or below.
# -----------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2025 Evander Fernandes
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# -----------------------------------------------------------------------------

# === CONFIG ===
TOKEN="your_bot_token_here"
CHAT_ID="your_chat_id_here"
MAPFILE="/tmp/ip_name_map.txt"
OUTFILE="/tmp/bandwidth_report.txt"
JSONFILE="/tmp/nlbwmon_dump.json"
> "$MAPFILE" > "$OUTFILE"

# === Step 1: Build IP -> Hostname Map from uci ===
current_ip=""
current_name=""
uci show dhcp | grep 'dhcp.@host' | while read -r line; do
    case "$line" in
        *".ip="*) current_ip=$(echo "$line" | cut -d"'" -f2) ;;
        *".name="*) current_name=$(echo "$line" | cut -d"'" -f2) ;;
        *".leasetime="*|*".mac="*)
            if [ -n "$current_ip" ] && [ -n "$current_name" ]; then
                echo "$current_ip|$current_name" >> "$MAPFILE"
                current_ip=""
                current_name=""
            fi
            ;;
    esac
done

# === Step 2: Dump nlbwmon JSON to file ===
nlbw -n -c json -g ip -o -rx > "$JSONFILE"

# === Step 3: Parse Usage Data from JSON file ===
# Get column indexes
IP_IDX=$(jq -r '.columns | index("ip")' "$JSONFILE")
RX_IDX=$(jq -r '.columns | index("rx_bytes")' "$JSONFILE")
TX_IDX=$(jq -r '.columns | index("tx_bytes")' "$JSONFILE")

jq -c '.data[]' "$JSONFILE" | while read -r row; do
    IP=$(echo "$row" | jq -r ".[$IP_IDX]")
    RX_BYTES=$(echo "$row" | jq -r ".[$RX_IDX]")
    TX_BYTES=$(echo "$row" | jq -r ".[$TX_IDX]")

    # Skip if download is 0 or missing
    [ -z "$RX_BYTES" ] || [ "$RX_BYTES" -eq 0 ] && continue

    # Find hostname from map
    NAME=$(grep "^$IP|" "$MAPFILE" | cut -d"|" -f2)
    [ -z "$NAME" ] && NAME="$IP"

    # Convert bytes to human-readable format
    to_human() {
        B="$1"
        if ! echo "$B" | grep -qE '^[0-9]+$'; then
            echo "0 B"
            return
        fi
        if [ "$B" -ge 1073741824 ]; then
            awk -v val="$B" 'BEGIN { printf "%.2f GB", val/1073741824 }'
        elif [ "$B" -ge 1048576 ]; then
            awk -v val="$B" 'BEGIN { printf "%.2f MB", val/1048576 }'
        elif [ "$B" -ge 1024 ]; then
            awk -v val="$B" 'BEGIN { printf "%.2f KB", val/1024 }'
        else
            echo "${B} B"
        fi
    }

    RX_HR=$(to_human "$RX_BYTES")
    TX_HR=$(to_human "$TX_BYTES")

    echo "Device: $NAME" >> "$OUTFILE"
    echo "Download: $RX_HR" >> "$OUTFILE"
    echo "Upload: $TX_HR" >> "$OUTFILE"
    echo "IP: $IP" >> "$OUTFILE"
    echo "" >> "$OUTFILE"
done

TITLE="📊 Bandwidth Usage - $(date +'%B %d %Y')
"

# === Step 4: Send to Telegram ===
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d parse_mode="Markdown" \
  --data-urlencode "text=$TITLE$(cat $OUTFILE)"
