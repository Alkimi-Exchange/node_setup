#! /bin/bash -xv

shopt -s extglob  ## this is to add exclude a folder in a cp command

cd /home/ubuntu/node_setup

# Check if the service exists and is running
SERVICE_STATUS=$(systemctl is-active nms_service.service 2>/dev/null)

# Check if the service is running
if [ "$SERVICE_STATUS" != "active" ]; then
    # Define paths
    EXISTING_SERVICE_FILE="/etc/systemd/system/nms_service.service"
    NEW_SERVICE_FILE="/home/ubuntu/node_setup/nms_service.service"

    # Remove existing service file if it exists
    if [ -f "$EXISTING_SERVICE_FILE" ]; then
        echo "Removing existing service file: $EXISTING_SERVICE_FILE"
        sudo rm "$EXISTING_SERVICE_FILE"
    fi

    # Copy new service file
    echo "Copying new service file: $NEW_SERVICE_FILE to $EXISTING_SERVICE_FILE"
    sudo cp "$NEW_SERVICE_FILE" "$EXISTING_SERVICE_FILE"

    # Set permissions
    echo "Setting permissions for $EXISTING_SERVICE_FILE"
    sudo chmod 644 "$EXISTING_SERVICE_FILE"

    # Reload systemd daemon
    echo "Reloading systemd daemon"
    sudo systemctl daemon-reload

    # Restart the service
    echo "Restarting nms_service.service"
    sudo systemctl start nms_service.service

else
    sudo systemctl restart nms_service.service
    echo "Restarting nms_service.service"
    
fi