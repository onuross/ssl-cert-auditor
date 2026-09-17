#!/usr/bin/env bash

# SSL Certificate Expiry Auditor
# Refactored for modern shell scripting standards

# Exit Codes:
# 0 = Success
# 1 = Invalid number of parameters
# 2 = Target date format is not DD-MM-YYYY
# 3 = Invalid target date provided
# 4 = Connection failed or invalid input (not a file, IPv4, or hostname)

# Enable defensive bash programming
# -e: Exit immediately if a command exits with a non-zero status
# -u: Treat unset variables as an error
# -o pipefail: The return value of a pipeline is the status of the last command to exit with a non-zero status
set -euo pipefail

# Regular expressions for validation
# Stored as variables for readability instead of inline grep usage
ipv4_regex="\<\(\(25[0-5]\|2[0-4][0-9]\|[01]\?[0-9][0-9]\?\)\.\)\{3\}\(25[0-5]\|2[0-4][0-9]\|[01]\?[0-9][0-9]\?\)\>"
date_regex="\<[[:digit:]]\{2\}-[[:digit:]]\{2\}-[[:digit:]]\{4\}\>"

# Validate parameter count
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <Hostname/IPv4/File_Path> [DD-MM-YYYY]" >&2
    exit 1
fi

# Assign arguments to descriptive variables
# ${2:-} is used to prevent unbound variable errors (set -u) if the 2nd parameter is missing
TARGET_INPUT="$1"
TARGET_DATE="${2:-}"

calculate_duration() {
    local raw_date="$1"
    local user_date="$2"

    # Validate DD-MM-YYYY format if the second parameter is provided
    # '|| true' is appended to prevent 'set -e' from terminating the script if grep finds no match
    if [ -n "$user_date" ] && [ "$user_date" != "$(echo "$user_date" | grep -o "$date_regex" || true)" ]; then
        echo "Error: Date format must be DD-MM-YYYY" >&2
        exit 2
    fi

    # Convert the certificate expiration date to seconds
    # LC_ALL=C ensures 'date' correctly parses English month names output by openssl
    local timestamp_cert
    timestamp_cert=$(LC_ALL=C date -d "$raw_date" +%s)

    local timestamp_target
    if [ -z "$user_date" ]; then
        # Default to current time if no target date is provided
        timestamp_target=$(date +%s)
    else
        local day month year
        day=$(echo "$user_date" | cut -d'-' -f1)
        month=$(echo "$user_date" | cut -d'-' -f2)
        year=$(echo "$user_date" | cut -d'-' -f3)
      
        # Convert to ISO 8601 format (YYYY-MM-DD) for compatibility with the 'date' command
        if ! timestamp_target=$(date -d "$year-$month-$day" +%s 2>/dev/null); then
            echo "Error: Invalid date provided." >&2
            exit 3
        fi
    fi

    local remaining_duration=$((timestamp_cert - timestamp_target))

    # Check if the certificate has already expired relative to the target date
    if [ "$remaining_duration" -le 0 ]; then
        echo "Warning: Certificate has expired or target date is past the expiration date." >&2
        echo "0 days, 0 hours, 0 minutes"
        return
    fi

    local duration_days=$((remaining_duration / 86400))
    local duration_hours=$(((remaining_duration % 86400) / 3600))
    local duration_mins=$(((remaining_duration % 3600) / 60))

    echo "$duration_days days, $duration_hours hours, $duration_mins minutes"
}

check_certificate_validity() {
    local target_host="$1"
    local user_date="$2"
    local raw_date

    # Fetch the SSL certificate and extract the 'NotAfter' date
    # 'timeout 5' ensures execution within the required < 10s timeframe
    # '|| true' prevents pipeline failure from crashing the script under 'set -e'
    raw_date=$( (echo -n | timeout 5 openssl s_client -connect "$target_host":443 2>/dev/null | grep -o "NotAfter.*" | head -n 1 | tr -s ' ' | cut -d' ' -f 2-6) || true )
    if [ -z "$raw_date" ]; then
        echo "Error: Connection to '$target_host' failed or no certificate found." >&2
        return 1
    else
        calculate_duration "$raw_date" "$user_date"
    fi
}

# 1. Check if the input is a valid file path
if [ -f "$TARGET_INPUT" ]; then
    echo "Reading from file: $TARGET_INPUT" >&2

    # Loop through each line in the file
    while read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | tr -d '\r')   
        
        # Skip empty lines
        if [ -n "$line" ]; then
            echo "Checking host: $line" >&2
            check_certificate_validity "$line" "$TARGET_DATE" || true
        fi
    done < "$TARGET_INPUT"

# 2. Check if the input matches the IPv4 pattern
elif [ "$TARGET_INPUT" = "$(echo "$TARGET_INPUT" | grep -o "$ipv4_regex" || true)" ]; then
    echo "Checking IPv4 address: $TARGET_INPUT" >&2
    if ! check_certificate_validity "$TARGET_INPUT" "$TARGET_DATE"; then
        exit 4
    fi

# 3. Default to treating the input as a hostname
else
    echo "Checking hostname: $TARGET_INPUT" >&2
    if ! check_certificate_validity "$TARGET_INPUT" "$TARGET_DATE"; then
        exit 4
    fi
fi

exit 0