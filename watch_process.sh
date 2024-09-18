#!/bin/bash

# Set environment variables
export HOME=/home/ubuntu/node_setup
LOG_FILE="$HOME/watch_process.log"

# Change directory to the script's directory
cd "$HOME" || { echo "Failed to change directory. Exiting..."; exit 1; }

# Define Docker containers and process names
CONTAINERS=("node_setup_nms_1")
PROCESS_NAMES=("nms_web_server" "upgrade_nms_script.py")

# Function to check and restart containers
check_and_restart_containers() {
    echo "Checking containers..."
    for container in "${CONTAINERS[@]}"; do
        # Check if the container is running
        if ! docker ps --format "{{.Names}}" | grep -q "$container"; then
            echo "Restarting container..."
            # Restart the container
            docker-compose down >> "$LOG_FILE" 2>&1
            docker-compose up -d >> "$LOG_FILE" 2>&1
        fi
    done
}

# Function to check and restart processes
check_and_restart_processes() {
    for process_name in "${PROCESS_NAMES[@]}"; do
        echo "Checking $process_name..."
        # Check if the process is running
        if pgrep -f "$process_name" >/dev/null; then
            echo "$process_name is running"
        else
            echo "Restarting $process_name..."
            # Restart the process
            pkill -f "$process_name" >> "$LOG_FILE" 2>&1
            if [ "$process_name" == "upgrade_nms_script.py" ]; then
                nohup python3 "$process_name" >> upgrade_nms_script.log 2>&1 &
            else
                nohup ./"$process_name" >> "${process_name}.log" 2>&1 &
            fi
        fi
    done
}

# Main function to call the monitoring functions
main() {
    echo "Starting monitoring..."
    while true; do
        check_and_restart_containers
        check_and_restart_processes
        sleep 300  # Sleep for 5 minutes
    done
}

# Run the main function
main
