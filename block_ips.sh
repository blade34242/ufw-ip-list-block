#!/bin/bash

# Directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Log file
LOG_FILE="$DIR/block_ips.log"

# Function to print debug messages
debug() {
    if [ "$debug_mode" = true ]; then
        echo "[DEBUG] $1" >> "$LOG_FILE"
    fi
}

# Function to get the number of lines in a file
get_num_lines() {
    local num_lines=$(wc -l < "$1")
    echo "$num_lines"
}

# Function to calculate estimated time
calculate_estimated_time() {
    local ip_example=$(head -n 1 "$1")  # Get the first IP address from the list
    local start_time=$(date +%s%3N)  # Start time in milliseconds
    sudo ufw insert 1 deny from "$ip_example" &>> "$LOG_FILE"
    local end_time=$(date +%s%3N)  # End time in milliseconds
    local elapsed_time=$((end_time - start_time))  # Elapsed time in milliseconds
    local time_per_ip=$((elapsed_time))  # Time per IP in milliseconds
    local estimated_time=$((time_per_ip * num_lines))  # Estimated time in milliseconds
    local seconds=$((estimated_time / 1000))
    local minutes=$((seconds / 60))
    local hours=$((minutes / 60))
    local days=$((hours / 24))
    if [ "$days" -gt 0 ]; then
        echo "$days days, $((hours % 24)) hours"
    elif [ "$hours" -gt 0 ]; then
        echo "$hours hours, $((minutes % 60)) minutes"
    elif [ "$minutes" -gt 0 ]; then
        echo "$minutes minutes, $((seconds % 60)) seconds"
    else
        echo "$seconds seconds"
    fi
}

# Function to update progress
update_progress() {
    local current="$1"
    local total="$2"
    local percentage=$((current * 100 / total))
    printf "\rProgress: %d%% (%d/%d IPs blocked)" "$percentage" "$current" "$total"
}

# Function to handle keyboard interrupt
cleanup() {
    echo -e "\nKeyboard interrupt detected. Cleaning up..."
    exit 1
}

# Trap SIGINT signal (Ctrl+C)
trap cleanup SIGINT

# Check if debug mode is enabled
debug_mode=false
if [ "$1" = "-d" ]; then
    debug_mode=true
    shift # Remove the debug flag from arguments
fi

# Check if file argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [-d] <file>"
    exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found."
    exit 1
fi

# Get the number of lines in the file
num_lines=$(get_num_lines "$1")
echo "Total IPs to block: $num_lines"

# Calculate estimated time
echo -n "Estimated time to complete: "
calculate_estimated_time "$1"

# Initialize progress counter
progress=0

# Read each line of the file and print or add to UFW
while IFS= read -r block; do
    if [ "$debug_mode" = true ]; then
        debug "IP to block: $block"
    else
        echo "IP to block: $block" >> "$LOG_FILE"
        sudo ufw insert 1 deny from "$block" &>> "$LOG_FILE"
    fi
    # Update progress
    ((progress++))
    update_progress "$progress" "$num_lines"
done < "$1"

# Final newline after progress bar
echo

if [ "$debug_mode" = true ]; then
    echo "Debug mode is enabled. UFW not executed." >> "$LOG_FILE"
else
    echo "Blocking IPs from '$1' file using UFW." >> "$LOG_FILE"
fi
